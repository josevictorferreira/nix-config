"""
bufcat.py - WeeChat buflist categorization script.

Config schema (version 1, JSON):
--------------------------------
Root object:
  version: int (required) - Must be 1
  case_insensitive: bool (optional, default false) - Global case-insensitive matching
  categories: array (required) - List of category objects
  default_category: object (required) - Fallback category for unmatched buffers

Category object (in `categories` array):
  name: string (required) - Category display name (informational)
  order: int (required, 0-999) - Sort order; lower = higher in buflist
  prefix: string (optional, default "") - Prefix prepended in buflist display
  patterns: array of strings (required) - Substring patterns to match buffer `name`

Default category object:
  name: string (required) - Category display name
  order: int (required, 0-999) - Sort order for unmatched buffers
  prefix: string (optional, default "") - Prefix for unmatched buffers

Matching rules:
- Target: substring search on `name`, then `short_name`, then `full_name` (each distinct
  non-empty value is tried; plugin tags like ``(DC)`` often live only in ``short_name``)
- Type: literal substring search (no regex/glob)
- Precedence: first match wins (iterate categories top-to-bottom)
- Case: case-sensitive by default unless case_insensitive=true

Sort behavior:
- Primary: category.order (zero-padded to 3 digits as localvar `bufcat_order`)
- Secondary: buffer.number

Example config:
{
  "version": 1,
  "case_insensitive": false,
  "categories": [
    {"name": "core", "order": 10, "prefix": "", "patterns": ["core."]},
    {"name": "irc", "order": 20, "prefix": "", "patterns": ["irc."]},
    {"name": "whatsapp", "order": 30, "prefix": "  ", "patterns": ["(WA)"]}
  ],
  "default_category": {"name": "other", "order": 99, "prefix": ""}
}

Usage:
  /bufcat reload - Reload config from disk
  /bufcat status - Show current config status
  /bufcat list   - List all buffers with their categories

Config file location:
  plugins.var.python.bufcat.config_path, else BUFCAT_CONFIG_PATH (Nix wrapper sets the store
  bufcat.json by default), else ${weechat_data_dir}/bufcat.json. If that data-dir file is
  missing, bufcat copies the default from the script directory. Load via
  /python load …/share/bufcat.py.

Requires: WeeChat >= 4.1.0
"""

from __future__ import annotations

import json
import os
import shutil
from typing import Any, Callable, Dict, List, Optional, Tuple

# Global state
_last_good_config: Optional[Dict[str, Any]] = None

# Schema constants
SCHEMA_VERSION = 1
DEFAULT_CASE_INSENSITIVE = False


def zero_pad_order(order: int) -> str:
    """Convert order integer to 3-digit zero-padded string.

    Args:
        order: Integer 0-999

    Returns:
        Zero-padded 3-digit string (e.g., 10 -> "010")
    """
    return f"{order:03d}"


def _validate_category(cat: Any, is_default: bool = False) -> Tuple[bool, str]:
    """Validate a category object.

    Args:
        cat: Category dict to validate
        is_default: True if this is default_category (no patterns required)

    Returns:
        (valid, error_message) tuple
    """
    if not isinstance(cat, dict):
        return False, "category must be an object"

    # Required: name
    if "name" not in cat or not isinstance(cat["name"], str):
        return False, "category.name (string) is required"

    # Required: order (int 0-999)
    if "order" not in cat:
        return False, "category.order is required"
    if not isinstance(cat["order"], int) or cat["order"] < 0 or cat["order"] > 999:
        return False, "category.order must be int 0-999"

    # Optional: prefix (string, default "")
    if "prefix" in cat and not isinstance(cat["prefix"], str):
        return False, "category.prefix must be string"

    # Required for non-default: patterns (array of strings)
    if not is_default:
        if "patterns" not in cat:
            return False, "category.patterns is required"
        if not isinstance(cat["patterns"], list):
            return False, "category.patterns must be array"
        for p in cat["patterns"]:
            if not isinstance(p, str):
                return False, "category.patterns must contain strings"

    return True, ""


def _validate_config(config: Any) -> Tuple[bool, str]:
    """Validate full config structure.

    Args:
        config: Parsed JSON config

    Returns:
        (valid, error_message) tuple
    """
    if not isinstance(config, dict):
        return False, "config must be an object"

    # Required: version
    if "version" not in config:
        return False, "version is required"
    if config["version"] != SCHEMA_VERSION:
        return False, f"version must be {SCHEMA_VERSION}"

    # Optional: case_insensitive (bool)
    if "case_insensitive" in config and not isinstance(
        config["case_insensitive"], bool
    ):
        return False, "case_insensitive must be boolean"

    # Required: categories (array)
    if "categories" not in config:
        return False, "categories is required"
    if not isinstance(config["categories"], list):
        return False, "categories must be array"
    for i, cat in enumerate(config["categories"]):
        valid, err = _validate_category(cat, is_default=False)
        if not valid:
            return False, f"categories[{i}]: {err}"

    # Required: default_category (object)
    if "default_category" not in config:
        return False, "default_category is required"
    valid, err = _validate_category(config["default_category"], is_default=True)
    if not valid:
        return False, f"default_category: {err}"

    return True, ""


def _bundled_config_path() -> str:
    """Path to bufcat.json installed next to this script (e.g. nix store …/share/)."""
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "bufcat.json")


def _resolve_config_file(path: str, print_error: Callable[[str], None]) -> str:
    """If ``path`` is missing, copy bundled default or fall back to reading the bundle."""
    if os.path.isfile(path):
        return path
    bundled = _bundled_config_path()
    if not os.path.isfile(bundled):
        return path
    parent = os.path.dirname(path)
    try:
        if parent:
            os.makedirs(parent, exist_ok=True)
        shutil.copy2(bundled, path)
        return path
    except OSError as e:
        print_error(f"bufcat: cannot write {path} ({e}); using bundled defaults")
        return bundled


def load_config(path: str, print_error: Callable[[str], None] = print) -> Optional[Dict[str, Any]]:
    """Load and validate config from JSON file.

    On parse/validation error, keeps last-good config in memory and returns None.

    If ``path`` does not exist but a ``bufcat.json`` exists next to this script (Nix
    installs both under ``share/``), copies the bundle to ``path`` when writable.

    Args:
        path: Path to bufcat.json
        print_error: Function to call with error messages (default: print)

    Returns:
        Validated config dict, or None on error
    """
    global _last_good_config

    path = _resolve_config_file(path, print_error)

    try:
        with open(path, "r", encoding="utf-8") as f:
            config = json.load(f)
    except FileNotFoundError:
        print_error(f"bufcat: config not found: {path}")
        return _last_good_config
    except json.JSONDecodeError as e:
        print_error(f"bufcat: JSON parse error in {path}: {e}")
        return _last_good_config
    except OSError as e:
        print_error(f"bufcat: error reading {path}: {e}")
        return _last_good_config

    valid, err = _validate_config(config)
    if not valid:
        print_error(f"bufcat: config validation error: {err}")
        return _last_good_config

    _last_good_config = config
    return config


def get_config_path(adapter: WeeChatAdapter, weechat_data_dir: str) -> str:
    """Determine config file path.

    Precedence: plugins.var.python.bufcat.config_path, BUFCAT_CONFIG_PATH,
    ${weechat_data_dir}/bufcat.json.
    """
    plugin_path = adapter.config_get_plugin("config_path").strip()
    if plugin_path:
        return plugin_path

    env_path = os.environ.get("BUFCAT_CONFIG_PATH", "").strip()
    if env_path:
        return env_path

    return os.path.join(weechat_data_dir, "bufcat.json")


def _buffer_match_fields(
    buffer_name: str,
    buffer_short_name: Optional[str],
    buffer_full_name: Optional[str],
) -> List[str]:
    """Distinct non-empty strings to match against, in WeeChat field order."""
    seen: set[str] = set()
    out: List[str] = []
    for s in (buffer_name or "", buffer_short_name or "", buffer_full_name or ""):
        if not s or s in seen:
            continue
        seen.add(s)
        out.append(s)
    return out


def choose_category(
    buffer_name: str,
    config: Dict[str, Any],
    buffer_full_name: Optional[str] = None,
    buffer_short_name: Optional[str] = None,
) -> Dict[str, Any]:
    """Choose category for a buffer using first-match-wins substring search.

    Each pattern is tested against ``name``, then ``short_name``, then ``full_name``
    (when distinct). This catches plugin-specific tags such as ``(DC)`` on short names.

    Args:
        buffer_name: Buffer ``name`` field
        config: Validated config dict
        buffer_full_name: Buffer ``full_name`` field
        buffer_short_name: Buffer ``short_name`` (often what the buflist displays)

    Returns:
        Matching category dict (or default_category if no match)
    """
    fields = _buffer_match_fields(buffer_name, buffer_short_name, buffer_full_name)
    if not fields:
        return config.get("default_category", {"name": "other", "order": 99, "prefix": ""})

    case_insensitive = config.get("case_insensitive", DEFAULT_CASE_INSENSITIVE)

    for cat in config.get("categories", []):
        patterns = cat.get("patterns", [])
        for pattern in patterns:
            search_pattern = pattern.lower() if case_insensitive else pattern
            for field in fields:
                target = field.lower() if case_insensitive else field
                if search_pattern in target:
                    return cat

    return config.get("default_category", {"name": "other", "order": 99, "prefix": ""})


def get_all_categories(config: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Get all categories including default, sorted by order.

    Args:
        config: Validated config dict

    Returns:
        List of category dicts sorted by order
    """
    cats = list(config.get("categories", []))
    default = config.get(
        "default_category", {"name": "other", "order": 99, "prefix": ""}
    )
    cats.append(default)
    return sorted(cats, key=lambda c: c.get("order", 99))


# --- WeeChat integration (adapter boundary) ---


class WeeChatAdapter:
    """Abstract WeeChat API adapter. Subclass or mock for testing."""

    def info_get(self, info_name: str, arguments: str = "") -> str:
        """Get WeeChat info string."""
        raise NotImplementedError

    def config_get(self, option: str) -> str:
        """Get config option value."""
        raise NotImplementedError

    def config_set(self, option: str, value: str) -> bool:
        """Set config option value."""
        raise NotImplementedError

    def config_get_plugin(self, option: str) -> str:
        """Script plugin option (e.g. plugins.var.python.bufcat.<option>)."""
        return ""

    def buffer_get_string(self, buffer: str, property: str) -> str:
        """Get buffer string property."""
        raise NotImplementedError

    def buffer_set(self, buffer: str, property: str, value: str) -> bool:
        """Set buffer property (e.g., localvar_set_*)."""
        raise NotImplementedError

    def buffer_search(self, plugin: str, name: str) -> str:
        """Search for a buffer."""
        raise NotImplementedError

    def buffer_new(self, name: str) -> str:
        """Create a new buffer."""
        raise NotImplementedError

    def infolist_get(self, name: str, pointer: str, arguments: str) -> Any:
        """Get infolist."""
        raise NotImplementedError

    def infolist_next(self, infolist: Any) -> bool:
        """Move to next item in infolist."""
        raise NotImplementedError

    def infolist_string(self, infolist: Any, variable: str) -> str:
        """Get string from infolist item."""
        raise NotImplementedError

    def infolist_pointer(self, infolist: Any, variable: str) -> Any:
        """Get pointer from infolist item."""
        raise NotImplementedError

    def infolist_free(self, infolist: Any) -> None:
        """Free infolist."""
        raise NotImplementedError

    def hook_signal(self, signal: str, callback: str, callback_data: str = "") -> Any:
        """Hook a signal."""
        raise NotImplementedError

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
        """Hook a command."""
        raise NotImplementedError

    def command(self, buffer: str, command: str) -> bool:
        """Execute a command."""
        raise NotImplementedError

    def print_buffer(self, buffer: str, message: str) -> None:
        """Print message to buffer."""
        raise NotImplementedError

    def signal_send(self, signal: str, type_str: str, signal_data: Any) -> bool:
        """Send a signal."""
        raise NotImplementedError


# Real WeeChat adapter (imported when running in WeeChat)
try:
    import weechat

    _WEECHAT_AVAILABLE = True
except ImportError:
    weechat = None
    _WEECHAT_AVAILABLE = False


class RealWeeChatAdapter(WeeChatAdapter):
    """Real WeeChat API adapter."""

    def info_get(self, info_name: str, arguments: str = "") -> str:
        return weechat.info_get(info_name, arguments) or ""

    def config_get(self, option: str) -> str:
        ptr = weechat.config_get(option)
        return weechat.config_string(ptr) if ptr else ""

    def config_set(self, option: str, value: str) -> bool:
        ptr = weechat.config_get(option)
        if ptr:
            return weechat.config_option_set(ptr, value, 1) == 1
        return False

    def config_get_plugin(self, option: str) -> str:
        ptr = weechat.config_get_plugin(option)
        return weechat.config_string(ptr) if ptr else ""

    def buffer_get_string(self, buffer: str, property: str) -> str:
        return weechat.buffer_get_string(buffer, property) or ""

    def buffer_set(self, buffer: str, property: str, value: str) -> bool:
        weechat.buffer_set(buffer, property, value)
        return True

    def buffer_search(self, plugin: str, name: str) -> str:
        return weechat.buffer_search(plugin, name) or ""

    def buffer_new(self, name: str) -> str:
        return weechat.buffer_new(name, "", "", "", "") or ""

    def infolist_get(self, name: str, pointer: str, arguments: str) -> Any:
        return weechat.infolist_get(name, pointer, arguments)

    def infolist_next(self, infolist: Any) -> bool:
        return weechat.infolist_next(infolist) == 1

    def infolist_string(self, infolist: Any, variable: str) -> str:
        return weechat.infolist_string(infolist, variable) or ""

    def infolist_pointer(self, infolist: Any, variable: str) -> Any:
        return weechat.infolist_pointer(infolist, variable)

    def infolist_free(self, infolist: Any) -> None:
        weechat.infolist_free(infolist)

    def hook_signal(self, signal: str, callback: str, callback_data: str = "") -> Any:
        return weechat.hook_signal(signal, callback, callback_data)

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
        return weechat.hook_command(
            command,
            description,
            args,
            args_description,
            completion,
            callback,
            callback_data,
        )

    def command(self, buffer: str, command: str) -> bool:
        return weechat.command(buffer, command) == 1

    def print_buffer(self, buffer: str, message: str) -> None:
        weechat.prnt(buffer, message)

    def signal_send(self, signal: str, type_str: str, signal_data: Any) -> bool:
        return weechat.hook_signal_send(signal, type_str, signal_data) == 1


# Module-level adapter instance
_adapter: Optional[WeeChatAdapter] = None

# Saved buflist config for restore
_saved_buflist: Dict[str, str] = {}


def get_adapter() -> WeeChatAdapter:
    """Get or create WeeChat adapter."""
    global _adapter
    if _adapter is None:
        if _WEECHAT_AVAILABLE:
            _adapter = RealWeeChatAdapter()
        else:
            raise RuntimeError("WeeChat not available")
    return _adapter


def _print_to_core(message: str) -> None:
    """Print message to core buffer."""
    try:
        adapter = get_adapter()
        adapter.print_buffer("", f"bufcat: {message}")
    except RuntimeError:
        print(f"bufcat: {message}")


def categorize_buffer(buffer_ptr: str, config: Dict[str, Any]) -> None:
    """Categorize a single buffer and set localvars.

    Args:
        buffer_ptr: WeeChat buffer pointer
        config: Validated config dict
    """
    adapter = get_adapter()

    if adapter.buffer_get_string(buffer_ptr, "local_variables.bufcat_header") == "1":
        return

    # Get buffer name (fallback to full_name)
    buffer_name = adapter.buffer_get_string(buffer_ptr, "name")
    buffer_short_name = adapter.buffer_get_string(buffer_ptr, "short_name")
    buffer_full_name = adapter.buffer_get_string(buffer_ptr, "full_name")

    # Choose category
    cat = choose_category(buffer_name, config, buffer_full_name, buffer_short_name)

    # Set localvars
    order_str = f"{zero_pad_order(cat.get('order', 99))}_1"
    prefix = cat.get("prefix", "")

    adapter.buffer_set(buffer_ptr, "localvar_set_bufcat_order", order_str)
    adapter.buffer_set(buffer_ptr, "localvar_set_bufcat_prefix", prefix)


def manage_headers(config: Dict[str, Any]) -> None:
    """Ensure dummy buffers exist for categories that define a 'header'."""
    adapter = get_adapter()
    for cat in config.get("categories", []):
        header = cat.get("header")
        if not header or not isinstance(header, str):
            continue

        # Search for existing dummy buffer
        ptr = adapter.buffer_search("core", header) or adapter.buffer_search("python", header) or adapter.buffer_search("", header)
        if not ptr:
            ptr = adapter.buffer_new(header)
            if ptr:
                adapter.buffer_set(ptr, "title", f"{header} category")
                adapter.buffer_set(ptr, "notify", "0")
                adapter.buffer_set(ptr, "type", "formatted")

        if ptr:
            adapter.buffer_set(ptr, "localvar_set_bufcat_header", "1")
            adapter.buffer_set(ptr, "localvar_set_bufcat_order", f"{zero_pad_order(cat.get('order', 99))}_0")
            adapter.buffer_set(ptr, "localvar_set_bufcat_prefix", "")


def categorize_all_buffers(config: Dict[str, Any]) -> None:
    """Categorize all open buffers.

    Args:
        config: Validated config dict
    """
    manage_headers(config)

    adapter = get_adapter()

    infolist = adapter.infolist_get("buffer", "", "")
    if not infolist:
        return

    try:
        while adapter.infolist_next(infolist):
            buffer_ptr = adapter.infolist_pointer(infolist, "pointer")
            categorize_buffer(buffer_ptr, config)
    finally:
        adapter.infolist_free(infolist)

    # Trigger buflist refresh
    adapter.signal_send("bufcat_categorized", "string", "")


def save_buflist_config() -> None:
    """Save current buflist config for later restore."""
    global _saved_buflist
    adapter = get_adapter()

    # Don't overwrite if already saved (e.g. from previous call in same execution)
    if _saved_buflist:
        return

    _saved_buflist = {
        "buflist.look.sort": adapter.config_get("buflist.look.sort"),
        "buflist.format.buffer": adapter.config_get("buflist.format.buffer"),
        "buflist.format.buffer_current": adapter.config_get(
            "buflist.format.buffer_current"
        ),
        "buflist.look.signals_refresh": adapter.config_get(
            "buflist.look.signals_refresh"
        ),
    }


def apply_buflist_config() -> None:
    """Apply buflist config changes for bufcat."""
    adapter = get_adapter()

    # Save originals first
    save_buflist_config()

    # Set sort order (category -> number -> name)
    adapter.config_set("buflist.look.sort", "local_variables.bufcat_order,number,name")

    # Patch format to include prefix (idempotent)
    original_format = _saved_buflist.get("buflist.format.buffer", "${format_buffer}")
    original_format_current = _saved_buflist.get(
        "buflist.format.buffer_current", "${format_buffer}"
    )

    prefix_expr = "${if:${buffer.local_variables.bufcat_prefix}?${buffer.local_variables.bufcat_prefix}:}"
    
    # Only patch if not already patched
    current_format = adapter.config_get("buflist.format.buffer")
    if prefix_expr not in current_format:
        adapter.config_set("buflist.format.buffer", prefix_expr + original_format)
    
    current_format_current = adapter.config_get("buflist.format.buffer_current")
    if prefix_expr not in current_format_current:
        adapter.config_set(
            "buflist.format.buffer_current", prefix_expr + original_format_current
        )

    # Add bufcat signal to refresh triggers
    signals = adapter.config_get("buflist.look.signals_refresh")
    if "bufcat_categorized" not in signals:
        if signals:
            signals = f"{signals},bufcat_categorized"
        else:
            signals = "bufcat_categorized"
        adapter.config_set("buflist.look.signals_refresh", signals)


def restore_buflist_config() -> None:
    """Restore original buflist config."""
    global _saved_buflist
    adapter = get_adapter()

    for option, value in _saved_buflist.items():
        adapter.config_set(option, value)

    _saved_buflist = {}


def clear_buffer_localvars() -> None:
    """Clear bufcat localvars from all buffers."""
    adapter = get_adapter()

    infolist = adapter.infolist_get("buffer", "", "")
    if not infolist:
        return

    try:
        while adapter.infolist_next(infolist):
            buffer_ptr = adapter.infolist_pointer(infolist, "pointer")
            adapter.buffer_set(buffer_ptr, "localvar_del_bufcat_order", "")
            adapter.buffer_set(buffer_ptr, "localvar_del_bufcat_prefix", "")
            adapter.buffer_set(buffer_ptr, "localvar_del_bufcat_header", "")
    finally:
        adapter.infolist_free(infolist)


# --- Command handlers ---


def cmd_reload(data: str, buffer: str, args: str) -> int:
    """Handle /bufcat reload."""
    adapter = get_adapter()
    weechat_data_dir = adapter.info_get("weechat_data_dir", "")
    config_path = get_config_path(adapter, weechat_data_dir)

    config = load_config(config_path, _print_to_core)
    if config:
        if not _saved_buflist:
            apply_buflist_config()
        categorize_all_buffers(config)
        _print_to_core("config reloaded")

    return 0


def cmd_status(data: str, buffer: str, args: str) -> int:
    """Handle /bufcat status."""
    global _last_good_config, _saved_buflist

    if _last_good_config:
        _print_to_core(f"config loaded: version={_last_good_config.get('version')}")
        _print_to_core(f"categories: {len(_last_good_config.get('categories', []))}")
        _print_to_core(
            f"case_insensitive: {_last_good_config.get('case_insensitive', False)}"
        )
    else:
        _print_to_core("no config loaded")

    if _saved_buflist:
        _print_to_core("buflist config: managed by bufcat")
    else:
        _print_to_core("buflist config: not modified")

    return 0


def cmd_list(data: str, buffer: str, args: str) -> int:
    """Handle /bufcat list."""
    if not _last_good_config:
        _print_to_core("no config loaded")
        return 0

    adapter = get_adapter()

    infolist = adapter.infolist_get("buffer", "", "")
    if not infolist:
        return 0

    try:
        while adapter.infolist_next(infolist):
            buffer_ptr = adapter.infolist_pointer(infolist, "pointer")
            buffer_name = adapter.buffer_get_string(buffer_ptr, "name")
            buffer_short_name = adapter.buffer_get_string(buffer_ptr, "short_name")
            buffer_full_name = adapter.buffer_get_string(buffer_ptr, "full_name")

            cat = choose_category(
                buffer_name,
                _last_good_config,
                buffer_full_name,
                buffer_short_name,
            )
            prefix = cat.get("prefix", "")
            order = cat.get("order", 99)
            cat_name = cat.get("name", "unknown")

            display = f"{prefix}{buffer_name}" if prefix else buffer_name
            _print_to_core(f"[{cat_name}] (order={order}) {display}")
    finally:
        adapter.infolist_free(infolist)

    return 0


def cmd_bufcat(data: str, buffer: str, args: str) -> int:
    """Handle /bufcat command."""
    args = args.strip()

    if args == "reload":
        return cmd_reload(data, buffer, args)
    elif args == "status":
        return cmd_status(data, buffer, args)
    elif args == "list":
        return cmd_list(data, buffer, args)
    else:
        _print_to_core("usage: /bufcat reload|status|list")
        return 0


# --- Signal handlers ---


def on_buffer_opened(data: str, signal: str, signal_data: str) -> int:
    """Handle buffer_opened signal."""
    if _last_good_config:
        categorize_buffer(signal_data, _last_good_config)
        get_adapter().signal_send("bufcat_categorized", "string", "")
    return 0


def on_buffer_renamed(data: str, signal: str, signal_data: str) -> int:
    """Handle buffer_renamed signal."""
    if _last_good_config:
        categorize_buffer(signal_data, _last_good_config)
        get_adapter().signal_send("bufcat_categorized", "string", "")
    return 0


# --- WeeChat registration ---


def weechat_register() -> bool:
    """Register with WeeChat."""
    if not _WEECHAT_AVAILABLE:
        return False

    rc = weechat.register(
        "bufcat",
        "jvf",
        "1.0.0",
        "MIT",
        "Categorize buflist buffers by substring matches",
        "bufcat_unload",
        "",
    )

    if rc != 1:
        return False

    # version_number is hex like 0x04080100 for 4.8.1 (see /help weechat version_number).
    # Do NOT use 0x04100000 — that is 4.16.x, not 4.1.0; it rejects every real 4.8.x build.
    raw = (weechat.info_get("version_number", "") or "").strip()
    try:
        num = int(raw, 0) if raw else 0
    except ValueError:
        num = 0
    if num > 0 and num < 0x04010000:  # 4.1.0
        weechat.prnt("", "bufcat: requires WeeChat >= 4.1.0")
        return False

    return True


def bufcat_unload() -> int:
    """Unload callback - restore original config."""
    restore_buflist_config()
    clear_buffer_localvars()
    return 0


def bufcat_init() -> bool:
    """Initialize bufcat after registration."""
    adapter = get_adapter()

    weechat_data_dir = adapter.info_get("weechat_data_dir", "")
    config_path = get_config_path(adapter, weechat_data_dir)
    config = load_config(config_path, _print_to_core)

    adapter.hook_command(
        "bufcat",
        "Manage buflist categorization",
        "reload|status|list",
        "reload: reload config from disk\n"
        "status: show config status\n"
        "list: list all buffers with categories",
        "reload|status|list",
        "cmd_bufcat",
        "",
    )

    adapter.hook_signal("buffer_opened", "on_buffer_opened", "")
    adapter.hook_signal("buffer_renamed", "on_buffer_renamed", "")

    if config:
        apply_buflist_config()
        categorize_all_buffers(config)
        _print_to_core("initialized")
    else:
        _print_to_core(
            "no valid config — add bufcat.json or /set plugins.var.python.bufcat.config_path, then /bufcat reload"
        )

    return True


# Entry point for WeeChat
if _WEECHAT_AVAILABLE:
    if weechat_register():
        bufcat_init()
