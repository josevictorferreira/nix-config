{ lib
, pkgs
, isDarwin
, npx
, defaultBrowser
, kebabToHuman
, ...
}:
let
  playwrightImport = "${pkgs.playwright}/index.mjs";
  readScript =
    path:
    builtins.replaceStrings [ "from 'playwright-core';" ] [ "from '${playwrightImport}';" ] (
      builtins.readFile path
    );
  generatedPrompt =
    builtins.replaceStrings [ "from 'playwright-core';" ] [ "from '${playwrightImport}';" ]
      (builtins.readFile ./_/browser-dev-cycle/_body.md);
in
{
  name = "browser-dev-cycle";
  description = "Full development cycle browser automation - viewing, debugging, testing, and visual inspection of web apps. Three-tier strategy using @playwright/mcp (MCP tools), Chrome DevTools MCP (performance), and Playwright-core (scripting). Triggers on \"browse\", \"browser\", \"screenshot\", \"viewport\", \"performance trace\", \"network debug\", \"visual QA\", \"responsive test\".";
  licence = "MIT";
  metadata = {
    triggers = "browser, debug, inspect, element, console, devtools, screenshot, navigate, click, fill, form, hover, drag, network, request, response, performance, emulate, device, mobile, geolocation, CPU throttling, JavaScript, execute, snapshot, accessibility, a11y, DOM, CSS, HTML, troubleshoot, webpage, automation, testing, E2E, interaction, keyboard, press key, page, tab, reload, refresh";
  };
  mcp = {
    playwright = {
      command = pkgs.writeShellScript "mcp-playwright-wrapper" ''
        export PATH="${lib.getBin pkgs.nodejs}/bin:$PATH"
        exec ${npx} -y @playwright/mcp@latest \
          --browser=chrome \
          --executable-path=${defaultBrowser} \
          "$@"
      '';
      args = [ ];
    };
    chrome-devtools = {
      command = pkgs.writeShellScript "mcp-chrome-devtools-wrapper" ''
        export PATH="${lib.getBin pkgs.nodejs}/bin:$PATH"
        exec ${npx} -y chrome-devtools-mcp@latest \
          --headless=true \
          --isolated=true \
          --executablePath=${defaultBrowser} \
          "$@"
      '';
      args = [ ];
    };
  };
  programs = [
    "opencode"
    "claudecode"
    "gemini"
    "command-code"
    "pi"
  ];
  scripts = {
    "network-mock.mjs" = readScript ./_/browser-dev-cycle/scripts/network-mock.mjs;
    "playwright-helper.mjs" = readScript ./_/browser-dev-cycle/scripts/playwright-helper.mjs;
    "viewport-test.mjs" = readScript ./_/browser-dev-cycle/scripts/viewport-test.mjs;
  };
  references = {
    "tool-comparison" = builtins.readFile ./_/browser-dev-cycle/references/tool-comparison.md;
    "workbook-patterns" = builtins.readFile ./_/browser-dev-cycle/references/workbook-patterns.md;
  };

  prompt = generatedPrompt;

}
