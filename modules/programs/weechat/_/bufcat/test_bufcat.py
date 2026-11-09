# Run: python -m unittest test_bufcat
"""Unit tests for bufcat.py - pure Python, no WeeChat runtime required."""

import json
import os
import tempfile
import unittest
from typing import Any, Dict, List, Tuple
from unittest import mock

import bufcat


# ---------------------------------------------------------------------------
# Fake adapter
# ---------------------------------------------------------------------------


class FakeWeeChatAdapter(bufcat.WeeChatAdapter):
    """In-memory WeeChat adapter for testing."""

    def __init__(self):
        self.config_values: Dict[str, str] = {}
        self.buffers: Dict[str, Dict[str, str]] = {}  # ptr -> localvars
        self.signal_hooks: List[Tuple[str, str, str]] = []
        self.command_hooks: List[Dict[str, str]] = []
        self.printed: List[Tuple[str, str]] = []
        self.signals_sent: List[Tuple[str, str, Any]] = []
        self.print_hooks: List[Tuple[str, str]] = []
        self.lines: Dict[str, List[Tuple[int, List[str]]]] = {}  # ptr -> [(date, tags)] oldest first
        self.commands: List[Tuple[str, str]] = []
        self._infolist_items: List[str] = []  # buffer ptrs for iteration
        self._infolist_cursor: int = -1

    def info_get(self, info_name: str, arguments: str = "") -> str:
        return ""

    def config_get(self, option: str) -> str:
        return self.config_values.get(option, "")

    def config_set(self, option: str, value: str) -> bool:
        self.config_values[option] = value
        return True

    def config_get_plugin(self, option: str) -> str:
        return self.config_values.get(f"plugin.{option}", "")

    def buffer_get_string(self, buffer: str, prop: str) -> str:
        return self.buffers.get(buffer, {}).get(prop, "")

    def buffer_set(self, buffer: str, prop: str, value: str) -> bool:
        props = self.buffers.setdefault(buffer, {})
        props[prop] = value
        # Mirror WeeChat: localvar_set_x / localvar_del_x are readable as localvar_x
        if prop.startswith("localvar_set_"):
            props["localvar_" + prop[len("localvar_set_"):]] = value
        elif prop.startswith("localvar_del_"):
            props.pop("localvar_" + prop[len("localvar_del_"):], None)
        return True

    def buffer_search(self, plugin: str, name: str) -> str:
        for ptr, localvars in self.buffers.items():
            if localvars.get("name") == name:
                return ptr
        return ""

    def buffer_new(self, name: str) -> str:
        ptr = f"ptr_{name}"
        self.buffers[ptr] = {"name": name}
        return ptr

    def infolist_get(self, name: str, pointer: str, arguments: str) -> Any:
        self._infolist_items = list(self.buffers.keys())
        self._infolist_cursor = -1
        return "fake_infolist"

    def infolist_next(self, infolist: Any) -> bool:
        self._infolist_cursor += 1
        return self._infolist_cursor < len(self._infolist_items)

    def infolist_string(self, infolist: Any, variable: str) -> str:
        ptr = self._infolist_items[self._infolist_cursor]
        return self.buffers.get(ptr, {}).get(variable, "")

    def infolist_pointer(self, infolist: Any, variable: str) -> Any:
        return self._infolist_items[self._infolist_cursor]

    def infolist_free(self, infolist: Any) -> None:
        self._infolist_items = []
        self._infolist_cursor = -1

    def hook_signal(self, signal: str, callback: str, callback_data: str = "") -> Any:
        self.signal_hooks.append((signal, callback, callback_data))
        return f"hook_{signal}"

    def hook_print(self, callback: str, callback_data: str = "") -> Any:
        self.print_hooks.append((callback, callback_data))
        return "hook_print"

    def buffer_lines(self, buffer: str, max_lines: int) -> List[Tuple[int, List[str]]]:
        return list(reversed(self.lines.get(buffer, [])))[:max_lines]

    def hook_command(
        self,
        command: str,
        description: str,
        args: str,
        args_description: str,
        completion: str,
        callback: str,
        callback_data: str = "",
    ) -> Any:
        self.command_hooks.append({"command": command, "callback": callback})
        return f"hook_cmd_{command}"

    def command(self, buffer: str, command: str) -> bool:
        self.commands.append((buffer, command))
        if command == "/buffer close":
            self.buffers.pop(buffer, None)
        return True

    def print_buffer(self, buffer: str, message: str) -> None:
        self.printed.append((buffer, message))

    def signal_send(self, signal: str, type_str: str, signal_data: Any) -> bool:
        self.signals_sent.append((signal, type_str, signal_data))
        return True


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_config(
    categories=None, default_category=None, case_insensitive=False
) -> Dict[str, Any]:
    """Build a minimal valid config dict."""
    return {
        "version": 1,
        "case_insensitive": case_insensitive,
        "categories": categories
        or [
            {"name": "core", "order": 10, "prefix": "", "patterns": ["core."]},
            {"name": "irc", "order": 20, "prefix": "  ", "patterns": ["irc."]},
        ],
        "default_category": default_category
        or {"name": "other", "order": 99, "prefix": ""},
    }


def _write_json_file(path: str, data: Any) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f)


# ---------------------------------------------------------------------------
# Tests: pure functions
# ---------------------------------------------------------------------------


class TestChooseCategory(unittest.TestCase):
    """Tests for choose_category()."""

    def test_first_match_wins(self):
        """Overlapping patterns — first category in list wins."""
        config = _make_config(
            categories=[
                {"name": "first", "order": 1, "patterns": ["irc."]},
                {"name": "second", "order": 2, "patterns": ["irc.freenode"]},
            ]
        )
        result = bufcat.choose_category("irc.freenode.#nix", config)
        self.assertEqual(result["name"], "first")

    def test_default_fallback(self):
        """No pattern match → default_category."""
        config = _make_config()
        result = bufcat.choose_category("matrix.room.general", config)
        self.assertEqual(result["name"], "other")
        self.assertEqual(result["order"], 99)

    def test_case_insensitive_matching(self):
        """case_insensitive=True matches regardless of case."""
        config = _make_config(
            categories=[
                {"name": "irc", "order": 20, "prefix": "", "patterns": ["IRC."]},
            ],
            case_insensitive=True,
        )
        # Lowercase buffer name should match uppercase pattern
        result = bufcat.choose_category("irc.libera.#nix", config)
        self.assertEqual(result["name"], "irc")

    def test_case_sensitive_by_default(self):
        """Default: case-sensitive — uppercase pattern won't match lowercase name."""
        config = _make_config(
            categories=[
                {"name": "irc", "order": 20, "prefix": "", "patterns": ["IRC."]},
            ],
            case_insensitive=False,
        )
        result = bufcat.choose_category("irc.libera.#nix", config)
        self.assertEqual(result["name"], "other")

    def test_fallback_to_full_name(self):
        """Empty buffer_name still matches via buffer_full_name."""
        config = _make_config()
        result = bufcat.choose_category("", config, buffer_full_name="irc.libera.#nix")
        self.assertEqual(result["name"], "irc")

    def test_short_name_discord_tag(self):
        """Tags like (DC) often appear only on short_name (buflist display)."""
        config = _make_config(
            categories=[
                {
                    "name": "discord",
                    "order": 50,
                    "prefix": "  ",
                    "patterns": ["(DC)"],
                },
            ],
        )
        result = bufcat.choose_category(
            "#introductions",
            config,
            buffer_full_name="discord.server.#introductions",
            buffer_short_name="#introductions (DC)",
        )
        self.assertEqual(result["name"], "discord")

    def test_exact_category_matches_whole_field_only(self):
        config = _make_config(
            categories=[
                {"name": "mel", "order": 30, "patterns": ["Mel"], "exact": True},
                {"name": "wa", "order": 40, "patterns": ["matrix."]},
            ]
        )
        full = "matrix.homelab-matrix.!x:josevictor.me"
        self.assertEqual(bufcat.choose_category(full, config, full, "Mel")["name"], "mel")
        self.assertEqual(bufcat.choose_category(full, config, full, "#Mel (WA)")["name"], "wa")
        self.assertEqual(bufcat.choose_category(full, config, full, "#Mel Dynamics Corp.")["name"], "wa")

    def test_exact_must_be_bool(self):
        config = _make_config(categories=[{"name": "x", "order": 1, "patterns": ["a"], "exact": "yes"}])
        valid, err = bufcat._validate_config(config)
        self.assertFalse(valid)
        self.assertIn("exact", err)

    def test_empty_name_and_full_name(self):
        """All name fields empty → default category."""
        config = _make_config()
        result = bufcat.choose_category("", config, buffer_full_name="")
        self.assertEqual(result["name"], "other")


class TestZeroPadOrder(unittest.TestCase):
    """Tests for zero_pad_order()."""

    def test_single_digit(self):
        self.assertEqual(bufcat.zero_pad_order(5), "005")

    def test_double_digit(self):
        self.assertEqual(bufcat.zero_pad_order(10), "010")

    def test_triple_digit(self):
        self.assertEqual(bufcat.zero_pad_order(100), "100")

    def test_zero(self):
        self.assertEqual(bufcat.zero_pad_order(0), "000")

    def test_max(self):
        self.assertEqual(bufcat.zero_pad_order(999), "999")


class TestValidateConfig(unittest.TestCase):
    """Tests for _validate_config()."""

    def test_valid_config(self):
        config = _make_config()
        valid, err = bufcat._validate_config(config)
        self.assertTrue(valid)
        self.assertEqual(err, "")

    def test_missing_version(self):
        config = _make_config()
        del config["version"]
        valid, err = bufcat._validate_config(config)
        self.assertFalse(valid)
        self.assertIn("version", err)

    def test_wrong_version(self):
        config = _make_config()
        config["version"] = 99
        valid, err = bufcat._validate_config(config)
        self.assertFalse(valid)

    def test_missing_categories(self):
        config = _make_config()
        del config["categories"]
        valid, err = bufcat._validate_config(config)
        self.assertFalse(valid)
        self.assertIn("categories", err)

    def test_missing_default_category(self):
        config = _make_config()
        del config["default_category"]
        valid, err = bufcat._validate_config(config)
        self.assertFalse(valid)
        self.assertIn("default_category", err)

    def test_invalid_case_insensitive_type(self):
        config = _make_config()
        config["case_insensitive"] = "yes"
        valid, err = bufcat._validate_config(config)
        self.assertFalse(valid)
        self.assertIn("case_insensitive", err)

    def test_category_missing_patterns(self):
        config = _make_config(
            categories=[{"name": "bad", "order": 10}],
        )
        valid, err = bufcat._validate_config(config)
        self.assertFalse(valid)
        self.assertIn("patterns", err)

    def test_category_order_out_of_range(self):
        config = _make_config(
            categories=[{"name": "bad", "order": 1000, "patterns": ["x"]}],
        )
        valid, err = bufcat._validate_config(config)
        self.assertFalse(valid)
        self.assertIn("order", err)


# ---------------------------------------------------------------------------
# Tests: load_config (file I/O)
# ---------------------------------------------------------------------------


class TestLoadConfig(unittest.TestCase):
    """Tests for load_config()."""

    def setUp(self):
        # Reset global state before each test
        bufcat._last_good_config = None
        self._tmpdir = tempfile.mkdtemp()
        self._errors: List[str] = []

    def tearDown(self):
        bufcat._last_good_config = None

    def _error_sink(self, msg: str) -> None:
        self._errors.append(msg)

    def test_load_valid_config(self):
        path = os.path.join(self._tmpdir, "bufcat.json")
        _write_json_file(path, _make_config())
        result = bufcat.load_config(path, self._error_sink)
        self.assertIsNotNone(result)
        self.assertEqual(result["version"], 1)
        self.assertEqual(len(self._errors), 0)

    def test_malformed_json_keeps_last_good(self):
        """Invalid JSON → returns last-good config."""
        path = os.path.join(self._tmpdir, "bufcat.json")

        # First: load a valid config to establish last-good
        _write_json_file(path, _make_config())
        good = bufcat.load_config(path, self._error_sink)
        self.assertIsNotNone(good)

        # Now corrupt the file
        with open(path, "w") as f:
            f.write("{bad json!!!")

        result = bufcat.load_config(path, self._error_sink)
        # Should return the last-good config, not None
        self.assertIsNotNone(result)
        self.assertEqual(result["version"], 1)
        self.assertTrue(any("JSON parse error" in e for e in self._errors))

    def test_file_not_found_returns_last_good(self):
        path = os.path.join(self._tmpdir, "nonexistent.json")
        with mock.patch.object(
            bufcat,
            "_bundled_config_path",
            return_value=os.path.join(self._tmpdir, "no-bundle-here.json"),
        ):
            result = bufcat.load_config(path, self._error_sink)
        # No last-good → None
        self.assertIsNone(result)
        self.assertTrue(any("not found" in e for e in self._errors))

    def test_seeds_from_bundled_when_target_missing(self):
        """Missing path + real bundle beside bufcat.py → copy then load."""
        path = os.path.join(self._tmpdir, "bufcat.json")
        self.assertFalse(os.path.isfile(path))
        result = bufcat.load_config(path, self._error_sink)
        self.assertIsNotNone(result)
        self.assertEqual(result["version"], 1)
        self.assertTrue(os.path.isfile(path))
        self.assertEqual(len(self._errors), 0)

    def test_validation_error_keeps_last_good(self):
        """Schema-invalid config → returns last-good."""
        path = os.path.join(self._tmpdir, "bufcat.json")

        # Establish last-good
        _write_json_file(path, _make_config())
        bufcat.load_config(path, self._error_sink)

        # Write invalid config (wrong version)
        _write_json_file(
            path, {"version": 99, "categories": [], "default_category": {}}
        )
        result = bufcat.load_config(path, self._error_sink)
        self.assertIsNotNone(result)
        self.assertEqual(result["version"], 1)  # last-good


# ---------------------------------------------------------------------------
# Tests: adapter-dependent functions
# ---------------------------------------------------------------------------


class TestBuflistPatchAndRestore(unittest.TestCase):
    """Tests for apply_buflist_config() and restore_buflist_config()."""

    def setUp(self):
        self.adapter = FakeWeeChatAdapter()
        bufcat._adapter = self.adapter
        bufcat._saved_buflist = {}
        # Pre-populate buflist config values
        self.adapter.config_values = {
            "buflist.look.sort": "number",
            "buflist.format.buffer": "${format_buffer}",
            "buflist.format.buffer_current": "${format_buffer}",
            "buflist.look.signals_refresh": "",
        }

    def tearDown(self):
        bufcat._adapter = None
        bufcat._saved_buflist = {}

    def test_apply_patches_sort_and_format(self):
        bufcat.apply_buflist_config()

        # Sort should be overridden
        self.assertEqual(
            self.adapter.config_values["buflist.look.sort"], bufcat.BUFLIST_SORT
        )
        self.assertIn("-local_variables.bufcat_last", bufcat.BUFLIST_SORT)
        # Format should be prefixed
        fmt = self.adapter.config_values["buflist.format.buffer"]
        self.assertIn("bufcat_prefix", fmt)
        self.assertTrue(fmt.endswith("${format_buffer}"))

    def test_apply_adds_signal_refresh(self):
        bufcat.apply_buflist_config()
        signals = self.adapter.config_values["buflist.look.signals_refresh"]
        self.assertIn("bufcat_categorized", signals)

    def test_restore_reverts_all(self):
        bufcat.apply_buflist_config()
        bufcat.restore_buflist_config()

        self.assertEqual(self.adapter.config_values["buflist.look.sort"], "number")
        self.assertEqual(
            self.adapter.config_values["buflist.format.buffer"], "${format_buffer}"
        )
        self.assertEqual(
            self.adapter.config_values["buflist.format.buffer_current"],
            "${format_buffer}",
        )

    def test_restore_clears_saved_state(self):
        bufcat.apply_buflist_config()
        self.assertTrue(len(bufcat._saved_buflist) > 0)
        bufcat.restore_buflist_config()
        self.assertEqual(bufcat._saved_buflist, {})

    def test_current_format_not_double_prefixed(self):
        """buffer_current embeds ${format_buffer}, which already carries the prefix."""
        self.adapter.config_values["buflist.format.buffer_current"] = "${color:,17}${format_buffer}"
        bufcat.apply_buflist_config()
        self.assertEqual(
            self.adapter.config_values["buflist.format.buffer_current"],
            "${color:,17}${format_buffer}",
        )

    def test_current_format_prefixed_when_standalone(self):
        self.adapter.config_values["buflist.format.buffer_current"] = "${color:,17}${name}"
        bufcat.apply_buflist_config()
        fmt = self.adapter.config_values["buflist.format.buffer_current"]
        self.assertTrue(fmt.startswith("${if:${buffer.local_variables.bufcat_prefix}"))
        self.assertTrue(fmt.endswith("${color:,17}${name}"))

    def test_apply_is_idempotent_on_saved_patched_config(self):
        """A buflist.conf saved with the old double-prefix patch is healed, not stacked."""
        bufcat.apply_buflist_config()
        patched = self.adapter.config_values["buflist.format.buffer"]
        self.adapter.config_values["buflist.format.buffer_current"] = (
            "${if:${buffer.local_variables.bufcat_prefix}?${buffer.local_variables.bufcat_prefix}:}"
            "${color:,17}${format_buffer}"
        )
        bufcat._saved_buflist = {}
        bufcat.apply_buflist_config()
        self.assertEqual(self.adapter.config_values["buflist.format.buffer"], patched)
        self.assertEqual(
            self.adapter.config_values["buflist.format.buffer_current"],
            "${color:,17}${format_buffer}",
        )


class TestCategorizeBuffer(unittest.TestCase):
    """Tests for categorize_buffer()."""

    def setUp(self):
        self.adapter = FakeWeeChatAdapter()
        bufcat._adapter = self.adapter
        # Set up a buffer
        self.adapter.buffers["buf_1"] = {
            "name": "irc.libera.#nix",
            "full_name": "irc.server.libera.#nix",
        }

    def tearDown(self):
        bufcat._adapter = None

    def test_sets_localvars(self):
        config = _make_config()
        bufcat.categorize_buffer("buf_1", config)
        localvars = self.adapter.buffers["buf_1"]
        self.assertEqual(localvars["localvar_set_bufcat_order"], "020_1")
        self.assertEqual(localvars["localvar_set_bufcat_prefix"], "  ")
        self.assertEqual(localvars["localvar_set_bufcat_last"], bufcat.NO_MESSAGE_YET)

    def test_keeps_existing_last_message_time(self):
        self.adapter.buffers["buf_1"]["localvar_bufcat_last"] = "1700000000"
        bufcat.categorize_buffer("buf_1", _make_config())
        self.assertNotIn("localvar_set_bufcat_last", self.adapter.buffers["buf_1"])

    def test_backfills_from_existing_lines(self):
        """Reload / logger backlog: newest message-like line seeds bufcat_last."""
        self.adapter.lines["buf_1"] = [
            (1700000100, ["notify_message"]),
            (1700000200, ["logger_backlog", "notify_none"]),
            (1700000300, []),  # membership event, newest but ignored
        ]
        bufcat.categorize_buffer("buf_1", _make_config())
        self.assertEqual(self.adapter.buffers["buf_1"]["localvar_set_bufcat_last"], "1700000200")

    def test_backfill_without_messages_is_zero(self):
        self.adapter.lines["buf_1"] = [(1700000300, ["irc_join"])]
        bufcat.categorize_buffer("buf_1", _make_config())
        self.assertEqual(self.adapter.buffers["buf_1"]["localvar_set_bufcat_last"], bufcat.NO_MESSAGE_YET)


class TestRecency(unittest.TestCase):
    """Tests for on_print() — most-recent-message tracking."""

    def setUp(self):
        self.adapter = FakeWeeChatAdapter()
        bufcat._adapter = self.adapter
        self.adapter.buffers["buf_1"] = {"name": "#Cibelle (WA)"}

    def tearDown(self):
        bufcat._adapter = None

    def _print(self, date, tags):
        return bufcat.on_print("", "buf_1", str(date), tags, 1, 0, "nick", "hi")

    def test_message_sets_zero_padded_time(self):
        self._print(1700000000, "matrix_text,notify_message,nick_mel")
        self.assertEqual(self.adapter.buffers["buf_1"]["localvar_set_bufcat_last"], "1700000000")

    def test_own_message_counts(self):
        self._print(5, "notify_none,no_highlight,self_msg")
        self.assertEqual(self.adapter.buffers["buf_1"]["localvar_set_bufcat_last"], "0000000005")

    def test_logger_backlog_counts(self):
        self._print(1700000000, "logger_backlog,notify_none,no_highlight")
        self.assertEqual(self.adapter.buffers["buf_1"]["localvar_set_bufcat_last"], "1700000000")

    def test_untagged_membership_line_ignored(self):
        self._print(1700000000, "")
        self._print(1700000001, "irc_join,log4")
        self.assertNotIn("localvar_set_bufcat_last", self.adapter.buffers["buf_1"])

    def test_older_backlog_does_not_regress(self):
        self._print(1700000100, "notify_message")
        self._print(1700000050, "notify_message")
        self.assertEqual(self.adapter.buffers["buf_1"]["localvar_set_bufcat_last"], "1700000100")

    def test_init_registers_print_hook(self):
        bufcat._saved_buflist = {}
        bufcat._last_good_config = None
        with mock.patch.object(bufcat, "load_config", return_value=None):
            bufcat.bufcat_init()
        self.assertEqual(self.adapter.print_hooks, [("on_print", "")])


class TestManageHeaders(unittest.TestCase):
    """Tests for manage_headers()."""

    def setUp(self):
        self.adapter = FakeWeeChatAdapter()
        bufcat._adapter = self.adapter

    def tearDown(self):
        bufcat._adapter = None

    def _config(self, header):
        return _make_config(
            categories=[
                {"name": "matrix", "order": 30, "prefix": "  ", "patterns": ["matrix."], "header": header},
            ]
        )

    def test_creates_header_above_its_rooms(self):
        bufcat.manage_headers(self._config("The Mel Dynamics Corp."))
        hdr = self.adapter.buffers["ptr_The Mel Dynamics Corp."]
        self.assertEqual(hdr["localvar_set_bufcat_header"], "1")
        self.assertEqual(hdr["localvar_set_bufcat_order"], "030_0")

    def test_renamed_header_closes_stale_one(self):
        bufcat.manage_headers(self._config("Matrix"))
        self.assertIn("ptr_Matrix", self.adapter.buffers)
        bufcat.manage_headers(self._config("The Mel Dynamics Corp."))
        self.assertNotIn("ptr_Matrix", self.adapter.buffers)
        self.assertIn(("ptr_Matrix", "/buffer close"), self.adapter.commands)
        self.assertIn("ptr_The Mel Dynamics Corp.", self.adapter.buffers)

    def test_rerun_keeps_current_header(self):
        cfg = self._config("WhatsApp")
        bufcat.manage_headers(cfg)
        bufcat.manage_headers(cfg)
        self.assertEqual(self.adapter.commands, [])


class TestShippedConfig(unittest.TestCase):
    """The bufcat.json next to the script matches the wanted buflist layout."""

    def setUp(self):
        self.config = bufcat.load_config(bufcat._bundled_config_path(), lambda m: self.fail(m))

    def test_four_sections_in_order(self):
        headers = [
            (c["order"], c["header"]) for c in self.config["categories"] if "header" in c
        ]
        self.assertEqual(
            [h for _, h in sorted(headers)],
            ["The Mel Dynamics Corp.", "WhatsApp", "Slack", "Discord"],
        )

    def test_rooms_route_to_sections(self):
        def section(short):
            return bufcat.choose_category(
                short, self.config, buffer_full_name=f"matrix.homelab-matrix.!x:josevictor.me",
                buffer_short_name=short,
            )["header"]

        self.assertEqual(section("#Cibelle (WA)"), "WhatsApp")
        self.assertEqual(section("#general (SL)"), "Slack")
        self.assertEqual(section("#agents (DC)"), "Discord")
        for name in ("Mel", "Luna", "Kira", "Ted", "Spike", "#CCTV", "#Homelab Alerts", "#Valoris · Agentes"):
            self.assertEqual(section(name), "The Mel Dynamics Corp.")
        # Untagged matrix rooms are WhatsApp groups; "Mel" must not catch look-alikes.
        for name in ("#Patrulha Canina", "#Open Tênis 🎾", "#Mel (WA)", "#Mel Dynamics Corp.", "WhatsApp Bridge Bot"):
            self.assertEqual(section(name), "WhatsApp")

    def test_sections_are_indented(self):
        for c in self.config["categories"]:
            if "header" in c:
                self.assertEqual(c["prefix"], "  ")


class TestCategorizeAllBuffers(unittest.TestCase):
    """Tests for categorize_all_buffers()."""

    def setUp(self):
        self.adapter = FakeWeeChatAdapter()
        bufcat._adapter = self.adapter
        self.adapter.buffers = {
            "buf_core": {"name": "core.weechat", "full_name": "core.weechat"},
            "buf_irc": {"name": "irc.libera.#nix", "full_name": "irc.libera.#nix"},
            "buf_other": {"name": "matrix.room", "full_name": "matrix.room"},
        }

    def tearDown(self):
        bufcat._adapter = None

    def test_categorizes_all(self):
        config = _make_config()
        bufcat.categorize_all_buffers(config)

        self.assertEqual(
            self.adapter.buffers["buf_core"]["localvar_set_bufcat_order"], "010_1"
        )
        self.assertEqual(
            self.adapter.buffers["buf_irc"]["localvar_set_bufcat_order"], "020_1"
        )
        self.assertEqual(
            self.adapter.buffers["buf_other"]["localvar_set_bufcat_order"], "099_1"
        )

    def test_sends_signal_after_categorize(self):
        config = _make_config()
        bufcat.categorize_all_buffers(config)
        self.assertTrue(
            any(s[0] == "bufcat_categorized" for s in self.adapter.signals_sent)
        )


class TestGetAllCategories(unittest.TestCase):
    """Tests for get_all_categories()."""

    def test_includes_default_sorted(self):
        config = _make_config()
        cats = bufcat.get_all_categories(config)
        names = [c["name"] for c in cats]
        self.assertIn("other", names)
        # Verify sorted by order
        orders = [c["order"] for c in cats]
        self.assertEqual(orders, sorted(orders))


if __name__ == "__main__":
    unittest.main()
