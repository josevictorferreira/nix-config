# Run: python -m unittest test_bufcat
"""Unit tests for bufcat.py - pure Python, no WeeChat runtime required."""

import json
import os
import tempfile
import unittest
from typing import Any, Dict, List, Tuple

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
        self._infolist_items: List[str] = []  # buffer ptrs for iteration
        self._infolist_cursor: int = -1

    def info_get(self, info_name: str, arguments: str = "") -> str:
        return ""

    def config_get(self, option: str) -> str:
        return self.config_values.get(option, "")

    def config_set(self, option: str, value: str) -> bool:
        self.config_values[option] = value
        return True

    def buffer_get_string(self, buffer: str, prop: str) -> str:
        return self.buffers.get(buffer, {}).get(prop, "")

    def buffer_set(self, buffer: str, prop: str, value: str) -> bool:
        self.buffers.setdefault(buffer, {})[prop] = value
        return True

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
        """Empty buffer_name falls back to buffer_full_name."""
        config = _make_config()
        result = bufcat.choose_category("", config, buffer_full_name="irc.libera.#nix")
        self.assertEqual(result["name"], "irc")

    def test_empty_name_and_full_name(self):
        """Both names empty → default category."""
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
        result = bufcat.load_config(path, self._error_sink)
        # No last-good → None
        self.assertIsNone(result)
        self.assertTrue(any("not found" in e for e in self._errors))

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
            self.adapter.config_values["buflist.look.sort"],
            "local_variables.bufcat_order,number",
        )
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
        self.assertEqual(localvars["localvar_set_bufcat_order"], "020")
        self.assertEqual(localvars["localvar_set_bufcat_prefix"], "  ")


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
            self.adapter.buffers["buf_core"]["localvar_set_bufcat_order"], "010"
        )
        self.assertEqual(
            self.adapter.buffers["buf_irc"]["localvar_set_bufcat_order"], "020"
        )
        self.assertEqual(
            self.adapter.buffers["buf_other"]["localvar_set_bufcat_order"], "099"
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
