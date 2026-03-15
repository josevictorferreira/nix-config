{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  name = "vision-tools";
  description = "Visual analysis related skills. Image analysis, video understanding, OCR, UI screenshots to code, error diagnosis, technical diagrams, data visualization, and UI diff checking.";
  licence = "MIT";
  metadata = {
    category = "visual-engineering";
    triggers = "image, screenshot, photo, picture, OCR, text extraction, video, analyze image, understand diagram, UI screenshot, error screenshot, chart, graph, visualization, architecture diagram, flow chart, UML, ER diagram, dashboard, compare UI, visual diff, GLM-4.6V, vision, multimodal, visual understanding";
  };
  prompt = ''
    # Vision Tools

    ## CRITICAL: `skill_mcp` Syntax

    ```
    skill_mcp(mcp_name="<MCP_SERVER>", tool_name="<TOOL>", arguments='<JSON>')
    ```

    - `mcp_name` = MCP server (`zai-mcp-server`) — NOT `"vision-tools"`
    - `tool_name` = Tool name without prefix — NOT `zai-mcp-server_analyze_image`

    ## Tools

    | MCP Server | Tool | Use For |
    |------------|------|---------|
    | `zai-mcp-server` | `ui_to_artifact` | Turn UI screenshots into code, prompts, specs, or descriptions |
    | `zai-mcp-server` | `extract_text_from_screenshot` | OCR screenshots for code, terminals, docs, and general text |
    | `zai-mcp-server` | `diagnose_error_screenshot` | Analyze error snapshots and propose actionable fixes |
    | `zai-mcp-server` | `understand_technical_diagram` | Interpret architecture, flow, UML, ER, and system diagrams |
    | `zai-mcp-server` | `analyze_data_visualization` | Read charts and dashboards to surface insights and trends |
    | `zai-mcp-server` | `ui_diff_check` | Compare two UI shots to flag visual or implementation drift |
    | `zai-mcp-server` | `image_analysis` | General-purpose image understanding when other tools don't fit |
    | `zai-mcp-server` | `video_analysis` | Inspect videos (local/remote ≤8MB; MP4/MOV/M4V) to describe scenes, moments, and entities |

    ## Examples

    **UI to Artifact** (convert screenshot to code):
    ```
    skill_mcp(mcp_name="zai-mcp-server", tool_name="ui_to_artifact", arguments='{"image_path": "screenshot.png", "output_format": "code"}')
    ```

    **Extract Text** (OCR):
    ```
    skill_mcp(mcp_name="zai-mcp-server", tool_name="extract_text_from_screenshot", arguments='{"image_path": "terminal.png"}')
    ```

    **Diagnose Error**:
    ```
    skill_mcp(mcp_name="zai-mcp-server", tool_name="diagnose_error_screenshot", arguments='{"image_path": "error.png", "context": "React app build failure"}')
    ```

    **Understand Technical Diagram**:
    ```
    skill_mcp(mcp_name="zai-mcp-server", tool_name="understand_technical_diagram", arguments='{"image_path": "architecture.png", "diagram_type": "system architecture"}')
    ```

    **Analyze Data Visualization**:
    ```
    skill_mcp(mcp_name="zai-mcp-server", tool_name="analyze_data_visualization", arguments='{"image_path": "dashboard.png", "focus": "trends and insights"}')
    ```

    **UI Diff Check**:
    ```
    skill_mcp(mcp_name="zai-mcp-server", tool_name="ui_diff_check", arguments='{"image_path_before": "v1.png", "image_path_after": "v2.png"}')
    ```

    **General Image Analysis**:
    ```
    skill_mcp(mcp_name="zai-mcp-server", tool_name="image_analysis", arguments='{"image_path": "photo.jpg", "query": "Describe what you see"}')
    ```

    **Video Analysis**:
    ```
    skill_mcp(mcp_name="zai-mcp-server", tool_name="video_analysis", arguments='{"video_path": "demo.mp4", "query": "Summarize the key moments"}')
    ```

    ## Tool Details

    ### zai-mcp-server Tools

    **ui_to_artifact** - Convert UI screenshots to artifacts
    - `image_path` (string, required): Path to UI screenshot
    - `output_format` (string, optional): "code", "prompt", "spec", or "description" (default: "code")
    - `context` (string, optional): Additional context about the UI

    **extract_text_from_screenshot** - OCR text extraction
    - `image_path` (string, required): Path to screenshot
    - `context` (string, optional): Type of content (code, terminal, doc, etc.)

    **diagnose_error_screenshot** - Analyze error screenshots
    - `image_path` (string, required): Path to error screenshot
    - `context` (string, optional): Error context (language, framework, stack trace info)

    **understand_technical_diagram** - Interpret technical diagrams
    - `image_path` (string, required): Path to diagram
    - `diagram_type` (string, optional): "architecture", "flow", "UML", "ER", "system", etc.
    - `context` (string, optional): Domain or system context

    **analyze_data_visualization** - Analyze charts and dashboards
    - `image_path` (string, required): Path to visualization
    - `focus` (string, optional): What to focus on (trends, insights, anomalies, etc.)
    - `context` (string, optional): Data domain or metrics context

    **ui_diff_check** - Compare two UI screenshots
    - `image_path_before` (string, required): Path to before screenshot
    - `image_path_after` (string, required): Path to after screenshot
    - `focus` (string, optional): What to check (visual drift, layout changes, etc.)

    **image_analysis** - General-purpose image understanding
    - `image_path` (string, required): Path to image
    - `query` (string, required): What to analyze or ask about the image
    - `detail` (string, optional): "low", "medium", or "high" detail level (default: "medium")

    **video_analysis** - Analyze video content
    - `video_path` (string, required): Path or URL to video (≤8MB; MP4/MOV/M4V)
    - `query` (string, required): What to analyze or ask about the video
    - `timestamp_focus` (string, optional): Specific timestamp or moment to focus on

    ## Best Practices

    **Image Paths:**
    - Use relative paths from current directory: `screenshot.png`
    - Use absolute paths if needed: `/path/to/image.png`
    - Supported formats: PNG, JPEG, WebP, GIF, BMP

    **Video Paths:**
    - Local files: `demo.mp4`
    - Remote URLs: `https://example.com/video.mp4`
    - Max size: 8MB
    - Supported formats: MP4, MOV, M4V

    **Tool Selection:**
    - Use specific tools when available (ui_to_artifact, diagnose_error_screenshot, etc.)
    - Use `image_analysis` for general visual understanding
    - Use `video_analysis` for video content analysis

    **Context Tips:**
    - Provide relevant context for better results (framework, language, domain)
    - Specify output format for ui_to_artifact (code, prompt, spec, description)
    - Include error context for diagnose_error_screenshot (stack trace, language)

    ## Common Mistakes

    | ❌ Wrong | ✅ Correct |
    |----------|-----------|
    | `mcp_name="vision-tools"` | `mcp_name="zai-mcp-server"` |
    | `tool_name="zai-mcp-server_image_analysis"` | `tool_name="image_analysis"` |
    | `tool_name="zai-mcp-server_ui_to_artifact"` | `tool_name="ui_to_artifact"` |
    | Pasting images directly in chat | Use image paths in skill_mcp calls |
    | Using wrong tool for task | Use most specific tool available |
  '';
}
