{ pkgs, ... }:
let
  skillDir = ./_/ultimate-browsing;
  playwrightImport = "${pkgs.playwright}/index.js";
  readPlaywrightTemplate =
    path:
    builtins.replaceStrings [ "require('playwright')" ] [ "require('${playwrightImport}')" ] (
      builtins.readFile path
    );
  readReference =
    path:
    builtins.replaceStrings
      [
        "python3 engine/bias_check.py"
        "python3 -m engine"
        "engine/"
        "python3 -c \"import curl_cffi\" 2>/dev/null || pip install curl_cffi -q"
        "python3 -c \"import feedparser\" 2>/dev/null || pip install feedparser -q"
        "python3 -c \"import curl_cffi, bs4, yaml\" 2>/dev/null || pip install curl_cffi beautifulsoup4 pyyaml -q"
        "which yt-dlp || python3 -m yt_dlp --version"
        "- 미설치 시: `pip install yt-dlp`"
        "npm i -g agent-browser@0.33.2 && agent-browser install"
        "npm i -g agent-browser@0.33.2"
      ]
      [
        "ultimate-browsing-bias-check"
        "ultimate-browsing"
        "scripts/engine/"
        "python3 -c \"import curl_cffi\""
        "python3 -c \"import feedparser\""
        "python3 -c \"import curl_cffi, bs4, yaml\""
        "yt-dlp --version"
        "- yt-dlp is provided by the Nix rebuild."
        "# agent-browser is provided by the Nix rebuild; no npm install is needed."
        "# agent-browser is provided by the Nix rebuild; no npm install is needed."
      ]
      (builtins.readFile path);
in
{
  name = "ultimate-browsing";
  description = "Escalation skill for blocked or hard-to-reach web access — load it when a normal browse/fetch is blocked (WAF, 403, Cloudflare, JS-only render, login-gated, or a platform a generic fetcher cannot read). Tiered router: TIER 1 insane-search (headless extraction + WAF bypass via curl_cffi TLS impersonation, yt-dlp, Jina Reader, public APIs, Playwright real-Chrome fallback); TIER 1.5 agent-reach (platform-native readers for Chinese and social platforms: Xiaohongshu, Douyin, Weibo, Bilibili, V2EX, WeChat, plus Twitter/Reddit/LinkedIn/GitHub); TIER 2 Chrome stealth (CloakBrowser stealth Chromium + agent-browser CDP for clicks, forms, screenshots, video, cookie login). Triggers: blocked site, bypass bot detection, cloudflare/WAF bypass, scrape, stealth browser, import cookies, fill form, screenshot, play youtube, xiaohongshu, douyin, weibo, bilibili, v2ex, wechat article, podcast transcript. NOT for simple searches (use web-search) or plain fetches (use webfetch).";
  prompt = builtins.readFile (skillDir + "/_body.md");
  references = {
    "agent-reach/README" = readReference (skillDir + "/references/agent-reach/README.md");
    "agent-reach/career" = readReference (skillDir + "/references/agent-reach/career.md");
    "agent-reach/dev" = readReference (skillDir + "/references/agent-reach/dev.md");
    "agent-reach/search" = readReference (skillDir + "/references/agent-reach/search.md");
    "agent-reach/social" = readReference (skillDir + "/references/agent-reach/social.md");
    "agent-reach/video" = readReference (skillDir + "/references/agent-reach/video.md");
    "agent-reach/web" = readReference (skillDir + "/references/agent-reach/web.md");
    "chrome-stealth" = readReference (skillDir + "/references/chrome-stealth.md");
    "insane-search/README" = readReference (skillDir + "/references/insane-search/README.md");
    "insane-search/cache-archive" = readReference (
      skillDir + "/references/insane-search/cache-archive.md"
    );
    "insane-search/fallback" = readReference (skillDir + "/references/insane-search/fallback.md");
    "insane-search/jina" = readReference (skillDir + "/references/insane-search/jina.md");
    "insane-search/json-api" = readReference (skillDir + "/references/insane-search/json-api.md");
    "insane-search/media" = readReference (skillDir + "/references/insane-search/media.md");
    "insane-search/metadata" = readReference (skillDir + "/references/insane-search/metadata.md");
    "insane-search/naver" = readReference (skillDir + "/references/insane-search/naver.md");
    "insane-search/playwright" = readReference (skillDir + "/references/insane-search/playwright.md");
    "insane-search/public-api" = readReference (skillDir + "/references/insane-search/public-api.md");
    "insane-search/rss" = readReference (skillDir + "/references/insane-search/rss.md");
    "insane-search/tls-impersonate" = readReference (
      skillDir + "/references/insane-search/tls-impersonate.md"
    );
    "insane-search/twitter" = readReference (skillDir + "/references/insane-search/twitter.md");
  };
  scripts = {
    "ATTRIBUTION.md" = builtins.readFile (skillDir + "/ATTRIBUTION.md");
    "engine/__init__.py" = builtins.readFile (skillDir + "/engine/__init__.py");
    "engine/__main__.py" = builtins.readFile (skillDir + "/engine/__main__.py");
    "engine/bias_check.py" = builtins.readFile (skillDir + "/engine/bias_check.py");
    "engine/curl_probe.py" = builtins.readFile (skillDir + "/engine/curl_probe.py");
    "engine/executor.py" = builtins.readFile (skillDir + "/engine/executor.py");
    "engine/fetch_chain.py" = builtins.readFile (skillDir + "/engine/fetch_chain.py");
    "engine/referers.py" = builtins.readFile (skillDir + "/engine/referers.py");
    "engine/result_schema.py" = builtins.readFile (skillDir + "/engine/result_schema.py");
    "engine/summary.py" = builtins.readFile (skillDir + "/engine/summary.py");
    "engine/surrogate.py" = builtins.readFile (skillDir + "/engine/surrogate.py");
    "engine/surrogates.yaml" = builtins.readFile (skillDir + "/engine/surrogates.yaml");
    "engine/templates/package.json" = builtins.readFile (skillDir + "/engine/templates/package.json");
    "engine/templates/playwright_mobile_chrome.js" = readPlaywrightTemplate (
      skillDir + "/engine/templates/playwright_mobile_chrome.js"
    );
    "engine/templates/playwright_real_chrome.js" = readPlaywrightTemplate (
      skillDir + "/engine/templates/playwright_real_chrome.js"
    );
    "engine/tests/fixtures/amp_redirect_stub.html" = builtins.readFile (
      skillDir + "/engine/tests/fixtures/amp_redirect_stub.html"
    );
    "engine/tests/fixtures/search_interstitial.html" = builtins.readFile (
      skillDir + "/engine/tests/fixtures/search_interstitial.html"
    );
    "engine/tests/fixtures/wayback_available.json" = builtins.readFile (
      skillDir + "/engine/tests/fixtures/wayback_available.json"
    );
    "engine/tests/fixtures/wayback_snapshot.html" = builtins.readFile (
      skillDir + "/engine/tests/fixtures/wayback_snapshot.html"
    );
    "engine/tests/test_fetch_chain.py" = builtins.readFile (
      skillDir + "/engine/tests/test_fetch_chain.py"
    );
    "engine/tests/test_playwright_templates.py" = builtins.readFile (
      skillDir + "/engine/tests/test_playwright_templates.py"
    );
    "engine/tests/test_surrogate.py" = builtins.readFile (skillDir + "/engine/tests/test_surrogate.py");
    "engine/tests/test_surrogate_validators.py" = builtins.readFile (
      skillDir + "/engine/tests/test_surrogate_validators.py"
    );
    "engine/url_transforms.py" = builtins.readFile (skillDir + "/engine/url_transforms.py");
    "engine/validators.py" = builtins.readFile (skillDir + "/engine/validators.py");
    "engine/waf_detector.py" = builtins.readFile (skillDir + "/engine/waf_detector.py");
    "engine/waf_profiles.yaml" = builtins.readFile (skillDir + "/engine/waf_profiles.yaml");
    "cookie_crypto.py" = builtins.readFile (skillDir + "/scripts/cookie_crypto.py");
    "cookie_domains.py" = builtins.readFile (skillDir + "/scripts/cookie_domains.py");
    "cookie_paths.py" = builtins.readFile (skillDir + "/scripts/cookie_paths.py");
    "extract_cookies.py" = builtins.readFile (skillDir + "/scripts/extract_cookies.py");
    "tests/test_cookie_domain_filter.py" = builtins.readFile (
      skillDir + "/scripts/tests/test_cookie_domain_filter.py"
    );
    "tests/test_extract_cookies.py" = builtins.readFile (
      skillDir + "/scripts/tests/test_extract_cookies.py"
    );
  };
}
