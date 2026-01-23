{ config
, lib
, inputs
, ...
}:
let
  skillName = "browser-debug-tools";
  cfg = config.jvf.aiTools.skills."${skillName}";
  skillDef = inputs.lib.aiTools.mkSkillModule {
    name = skillName;
    description = "Browser automation and debugging via Chrome DevTools Protocol and Playwright. Control browser, inspect elements, execute JavaScript, monitor network/console, emulate devices, take screenshots, and automate interactions.";
    licence = "MIT";
    metadata = {
      triggers = "browser, debug, inspect, element, console, devtools, screenshot, navigate, click, fill, form, hover, drag, network, request, response, performance, emulate, device, mobile, geolocation, CPU throttling, JavaScript, execute, snapshot, accessibility, a11y, DOM, CSS, HTML, troubleshoot, webpage, automation, testing, E2E, interaction, keyboard, press key, page, tab, reload, refresh";
    };
    prompt = ''
      # Browser Debug Tools

      ## CRITICAL: `skill_mcp` Syntax

      ```
      skill_mcp(mcp_name="<MCP_SERVER>", tool_name="<TOOL>", arguments='<JSON>')
      ```

      - `mcp_name` = MCP server (`playwriter`, `chrome-devtools`) — NOT `"browser-debug-tools"`
      - `tool_name` = Tool name without prefix — NOT `chrome-devtools_click`

      ## Tools

      | MCP Server | Tool | Use For |
      |------------|------|---------|
      | `chrome-devtools` | `click` | Click on page elements (single or double-click) |
      | `chrome-devtools` | `close_page` | Close browser pages by ID |
      | `chrome-devtools` | `drag` | Drag elements between locations |
      | `chrome-devtools` | `emulate` | Emulate network conditions, CPU throttling, geolocation |
      | `chrome-devtools` | `evaluate_script` | Execute JavaScript in browser context |
      | `chrome-devtools` | `fill` | Fill input fields, text areas, or select options |
      | `chrome-devtools` | `get_console_message` | Get specific console message by ID |
      | `chrome-devtools` | `get_network_request` | Get network request details |
      | `chrome-devtools` | `hover` | Hover over page elements |
      | `chrome-devtools` | `list_console_messages` | List all console messages (with filtering) |
      | `chrome-devtools` | `list_pages` | List all open browser pages |
      | `chrome-devtools` | `navigate_page` | Navigate pages (URL, back, forward, reload) |
      | `chrome-devtools` | `press_key` | Press keyboard keys or combinations |
      | `chrome-devtools` | `select_page` | Select a page as context for future calls |
      | `chrome-devtools` | `take_screenshot` | Take screenshots (page or element) |
      | `chrome-devtools` | `take_snapshot` | Take accessibility tree snapshot |
      | `playwriter` | `execute` | Control browser via Playwright code snippets |
      | `playwriter` | `reset` | Reset CDP connection and browser/page/context |

      ## Examples

      **Click element**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="click", arguments='{"uid": "element-123", "dblClick": false}')
      ```

      **Close page**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="close_page", arguments='{"pageId": 1}')
      ```

      **Drag element**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="drag", arguments='{"from_uid": "source-123", "to_uid": "target-456"}')
      ```

      **Emulate network/CPU/geolocation**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="emulate", arguments='{"networkConditions": "Slow 3G", "cpuThrottlingRate": 4, "geolocation": {"latitude": 37.7749, "longitude": -122.4194}}')
      ```

      **Evaluate JavaScript**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="evaluate_script", arguments='{"function": "async () => { return await fetch(\\'/api/data\\').then(r => r.json()); }"}')
      ```

      **Fill input field**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="fill", arguments='{"uid": "input-123", "value": "Hello World"}')
      ```

      **Get console message**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="get_console_message", arguments='{"msgid": 5}')
      ```

      **Get network request**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="get_network_request", arguments='{"reqid": 123}')
      ```

      **Hover over element**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="hover", arguments='{"uid": "element-123"}')
      ```

      **List console messages**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="list_console_messages", arguments='{"types": ["error", "warn"], "pageSize": 50}')
      ```

      **List pages**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="list_pages", arguments='{}')
      ```

      **Navigate page**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="navigate_page", arguments='{"type": "url", "url": "https://example.com", "timeout": 30000}')
      ```

      **Press key**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="press_key", arguments='{"key": "Control+A"}')
      ```

      **Select page**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="select_page", arguments='{"pageId": 2, "bringToFront": true}')
      ```

      **Take screenshot**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="take_screenshot", arguments='{"format": "png", "fullPage": true}')
      ```

      **Take snapshot**:
      ```
      skill_mcp(mcp_name="chrome-devtools", tool_name="take_snapshot", arguments='{"verbose": false}')
      ```

      **Execute Playwright code**:
      ```
      skill_mcp(mcp_name="playwriter", tool_name="execute", arguments='{"code": "await page.click(\\'button\\'); console.log(\\'Clicked!\\');", "timeout": 10000}')
      ```

      **Reset connection**:
      ```
      skill_mcp(mcp_name="playwriter", tool_name="reset", arguments='{}')
      ```

      ## Tool Details

      ### chrome-devtools Tools

      **click** - Click on page elements
      - `uid` (string, required): Element UID from page snapshot
      - `dblClick` (boolean, optional): Double-click (default: false)

      **close_page** - Close browser page
      - `pageId` (number, required): Page ID to close

      **drag** - Drag element to another element
      - `from_uid` (string, required): Source element UID
      - `to_uid` (string, required): Target element UID

      **emulate** - Emulate device/network conditions
      - `networkConditions` (string, optional): "No emulation", "Offline", "Slow 3G", "Fast 3G", "Slow 4G", "Fast 4G"
      - `cpuThrottlingRate` (number, optional): CPU slowdown factor (1-20, 1 = no throttling)
      - `geolocation` (object/null, optional): {latitude, longitude} or null to clear

      **evaluate_script** - Execute JavaScript in page
      - `function` (string, required): JavaScript function (async supported)
      - `args` (array, optional): Arguments to pass to function

      **fill** - Fill form fields
      - `uid` (string, required): Element UID from page snapshot
      - `value` (string, required): Value to fill

      **get_console_message** - Get console message details
      - `msgid` (number, required): Console message ID

      **get_network_request** - Get network request details
      - `reqid` (number, optional): Network request ID (if omitted, returns currently selected)

      **hover** - Hover over element
      - `uid` (string, required): Element UID from page snapshot

      **list_console_messages** - List console messages with filtering
      - `types` (array, optional): Filter by message types (log, debug, info, error, warn, dir, etc.)
      - `pageSize` (integer, optional): Max messages to return
      - `pageIdx` (integer, optional): Page number (0-based)
      - `includePreservedMessages` (boolean, optional): Include messages from last 3 navigations (default: false)

      **list_pages** - List all open pages
      - No parameters required

      **navigate_page** - Navigate pages
      - `type` (string, required): "url", "back", "forward", or "reload"
      - `url` (string, optional): Target URL (only for type="url")
      - `ignoreCache` (boolean, optional): Ignore cache on reload
      - `timeout` (integer, optional): Max wait time in milliseconds

      **press_key** - Press keyboard keys
      - `key` (string, required): Key or combination (e.g., "Enter", "Control+A", "Shift+R")

      **select_page** - Select page as context
      - `pageId` (number, required): Page ID to select
      - `bringToFront` (boolean, optional): Focus and bring page to top

      **take_screenshot** - Take screenshots
      - `format` (string, optional): "png", "jpeg", or "webp" (default: "png")
      - `quality` (number, optional): Compression quality for JPEG/WebP (0-100)
      - `uid` (string, optional): Element UID (if omitted, screenshots entire page)
      - `fullPage` (boolean, optional): Screenshot full scrollable page
      - `filePath` (string, optional): Save to file path instead of attaching to response

      **take_snapshot** - Take accessibility tree snapshot
      - `verbose` (boolean, optional): Include all a11y tree info (default: false)
      - `filePath` (string, optional): Save to file path instead of attaching to response

      ### playwriter Tools

      **execute** - Run Playwright code snippets
      - `code` (string, required): JavaScript code with {page, state, context} in scope
      - `timeout` (number, optional): Timeout in ms (default: 5000)

      **reset** - Reset CDP connection
      - No parameters required

      ## Common Mistakes

      | ❌ Wrong | ✅ Correct |
      |----------|-----------|
      | `mcp_name="browser-debug-tools"` | `mcp_name="chrome-devtools"` or `mcp_name="playwriter"` |
      | `tool_name="chrome-devtools_click"` | `tool_name="click"` |
      | `tool_name="playwriter_execute"` | `tool_name="execute"` |
    '';
  };
in
{
  options.jvf.aiTools.skills."${skillName}" = skillDef.options;
  config = lib.mkIf cfg.enable skillDef.config;
}
