# Browser Dev Cycle: Three-Tier Automation Strategy

Comprehensive browser automation covering interaction, performance analysis, and scripted testing. Three tiers serve different needs -- use the lightest tier that gets the job done.

## 1. Decision Tree

### Which Tier for Which Task

| Task | Tier | Tool |
|------|------|------|
| Navigate, click, fill forms, screenshot | Tier 1 | @playwright/mcp |
| Accessibility snapshot | Tier 1 | `browser_snapshot` |
| Performance trace / profiling | Tier 2 | Chrome DevTools MCP |
| Core Web Vitals | Tier 2 | Chrome DevTools MCP |
| Network HAR detail | Tier 2 | Chrome DevTools MCP |
| Console errors with stack traces | Tier 2 | Chrome DevTools MCP |
| CSS computed styles debugging | Tier 2 | Chrome DevTools MCP |
| Network mocking / interception | Tier 3 | Playwright-core scripts |
| Viewport matrix testing | Tier 3 | Playwright-core scripts |
| Video / trace recording | Tier 3 | Playwright-core scripts |
| State save / restore | Tier 3 | Playwright-core scripts |
| Multi-page orchestration | Tier 3 | Playwright-core scripts |
| Visual regression | Tier 1 + Tier 3 | Screenshot compare |

### Quick Selection Rules

- **Start with Tier 1** for any interactive task. It covers 80% of browser automation needs.
- **Escalate to Tier 2** when you need data that Tier 1 cannot provide (performance metrics, network bodies, computed CSS).
- **Escalate to Tier 3** when you need programmatic control (loops, conditionals, mocking, recording).
- **Tier 1 + Tier 2** can run against the same browser instance simultaneously. Both connect via CDP.
- **Tier 3** scripts run as standalone Node.js processes and manage their own connections.

---

## 2. TIER 1: @playwright/mcp Reference

The primary tool for browser interaction. Uses MCP protocol -- tools are called directly without writing scripts.

### Modes

| Mode | Flag | How It Works | Best For |
|------|------|--------------|----------|
| **Snapshot** (default) | none | Accessibility tree with element refs | Most interactions -- no vision needed |
| **Vision** | `--caps vision` | Screenshots + XY coordinates | Visual elements without accessibility labels |
| **PDF** | `--caps pdf` | PDF generation | Saving pages as PDF |
| **Testing** | `--caps testing` | Expect assertions | Automated validation |
| **Tracing** | `--caps tracing` | Code generation | Recording interactions as Playwright scripts |

### Core Workflow

```
1. browser_navigate  ->  Load the page
2. browser_snapshot  ->  Get accessibility tree with element refs
3. browser_click / browser_type / browser_select_option  ->  Interact using refs
4. browser_snapshot  ->  Re-read after DOM changes (refs are invalidated)
```

**Critical rule:** After any navigation or significant DOM change, you MUST call `browser_snapshot` again. Element refs from a previous snapshot are stale and will fail.

### Tool Reference

| Tool | Parameters | Description |
|------|-----------|-------------|
| `browser_navigate` | `url` | Navigate to URL. Waits for page load. |
| `browser_snapshot` | -- | Returns accessibility tree with interactive element refs. |
| `browser_click` | `element: "Submit [ref=\"e3\"]"`, `ref: "e3"` | Click an element by its ref. |
| `browser_type` | `element: "Search [ref=\"e5\"]"`, `ref: "e5"`, `text: "query"` | Type text into an input field. |
| `browser_select_option` | `element: "Country [ref=\"e7\"]"`, `ref: "e7"`, `values: ["US"]` | Select option(s) from a dropdown. |
| `browser_press_key` | `key: "Enter"` | Press a keyboard key. Supports modifiers. |
| `browser_hover` | `element: "Menu [ref=\"e2\"]"`, `ref: "e2"` | Hover over an element. |
| `browser_handle_dialog` | `accept: true`, `promptText: "input"` | Handle alert, confirm, or prompt dialogs. |
| `browser_wait_for` | `time: 2000` or `text: "Loading complete"` | Wait for time (ms) or text to appear. |
| `browser_evaluate` | `expression: "document.title"` | Execute JavaScript in the page context. |
| `browser_take_screenshot` | -- | Capture a screenshot (requires `--caps vision`). |
| `browser_tab_new` | `url` | Open a new tab with the given URL. |
| `browser_tab_select` | `index` | Switch to tab by index (0-based). |
| `browser_tab_close` | `index` | Close a tab by index. |
| `browser_tab_list` | -- | List all open tabs with titles and URLs. |

---

## 3. TIER 2: Chrome DevTools MCP Reference

For performance profiling, network analysis, and detailed inspection that Tier 1 cannot provide.

### Setup

Use `skill_mcp` to interact with Chrome DevTools:

```
skill_mcp(mcp_name="chrome-devtools", tool_name="<TOOL>", arguments='<JSON>')
```

### Key Tools

| Tool | Use Case |
|------|----------|
| `performance_start_trace` | Start CPU profiling |
| `performance_stop_trace` | Stop profiling and get results |
| `performance_get_metrics` | Core Web Vitals (LCP, FID, CLS) |
| `network_get_har` | Full HAR with request/response bodies |
| `console_get_messages` | Console logs with stack traces |
| `css_get_computed_style` | Computed CSS for elements |
| `accessibility_snapshot` | Detailed accessibility tree |

---

## 4. TIER 3: Playwright-core Scripts

For programmatic control: loops, conditionals, mocking, recording, viewport matrix testing.

### Setup

Write `.mjs` scripts that use Playwright-core to connect via CDP:

```javascript
import { chromium } from 'playwright-core';

const browser = await chromium.connectOverCDP('http://localhost:9222');
const context = browser.contexts()[0];
const page = context.pages()[0];

// Your automation here
await page.goto('https://example.com');
await page.screenshot({ path: 'screenshot.png' });

await browser.close();
```

### Common Patterns

#### Viewport Matrix Testing

```javascript
const viewports = [
  { width: 1920, height: 1080, name: 'desktop' },
  { width: 768, height: 1024, name: 'tablet' },
  { width: 375, height: 812, name: 'mobile' }
];

for (const vp of viewports) {
  await page.setViewportSize({ width: vp.width, height: vp.height });
  await page.goto(url);
  await page.screenshot({ path: `${vp.name}.png` });
}
```

#### Network Mocking

```javascript
await page.route('**/api/data', async route => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ mocked: true })
  });
});
```

#### Visual Regression

```javascript
import { expect } from '@playwright/test';

await page.goto(url);
await expect(page).toHaveScreenshot('baseline.png', {
  maxDiffPixelRatio: 0.01
});
```

---

## 5. Common Workflows

### Login Flow

```
1. browser_navigate -> login page
2. browser_snapshot -> get refs
3. browser_type -> fill username
4. browser_type -> fill password
5. browser_click -> submit button
6. browser_snapshot -> verify logged in
```

### Form Testing

```
1. browser_navigate -> form page
2. browser_snapshot -> get refs
3. browser_type -> fill each field
4. browser_click -> submit
5. browser_snapshot -> check for errors
6. browser_evaluate -> verify submission
```

### Visual Inspection

```
1. browser_navigate -> page
2. browser_take_screenshot (Tier 1 Vision)
3. browser_evaluate -> get computed styles (Tier 1)
4. Check for layout issues, overflow, alignment
```

### Performance Profiling

```
1. browser_navigate -> page
2. skill_mcp("chrome-devtools", "performance_start_trace")
3. Interact with page (forms, navigation)
4. skill_mcp("chrome-devtools", "performance_stop_trace")
5. skill_mcp("chrome-devtools", "performance_get_metrics")
```

---

## 6. Error Recovery

| Error | Recovery |
|-------|----------|
| "Element not found" | Re-run `browser_snapshot` to refresh refs |
| "Navigation timeout" | Increase timeout; check if server is running |
| "MCP not connected" | Restart session; verify MCP server is running |
| "Element is not visible" | Scroll to element first; check CSS display/visibility |
| "Element is not editable" | Check if element is disabled or read-only |
| "Dialog already handled" | Use `browser_handle_dialog` before interacting |

---

## 7. Deprecation Notes

The following tools are deprecated. Use @playwright/mcp (Tier 1) instead:

| Deprecated Tool | Issue | Replacement |
|----------------|-------|-------------|
| **agent-browser CLI (`ab`)** | Windows daemon startup broken. Node.js wrapper unreliable. | Tier 1: @playwright/mcp |
| **Claude-in-Chrome MCP** | 6+ Windows 11 bugs. Extension-based approach is fragile. | Tier 1: @playwright/mcp |
| **Puppeteer MCP** | Deprecated upstream. ESM import errors. | Tier 1: @playwright/mcp |
