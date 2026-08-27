_:
let
  skillDir = ./_/ultimate-browsing;
in
{
  name = "ultimate-browsing";
  description = "Escalation skill for blocked or hard-to-reach web access — load it when a normal browse/fetch is blocked (WAF, 403, Cloudflare, JS-only render, login-gated, or a platform a generic fetcher cannot read). Tiered router: TIER 1 insane-search (headless extraction + WAF bypass via curl_cffi TLS impersonation, yt-dlp, Jina Reader, public APIs, Playwright real-Chrome fallback); TIER 1.5 agent-reach (platform-native readers for Chinese and social platforms: Xiaohongshu, Douyin, Weibo, Bilibili, V2EX, WeChat, plus Twitter/Reddit/LinkedIn/GitHub); TIER 2 Chrome stealth (CloakBrowser stealth Chromium + agent-browser CDP for clicks, forms, screenshots, video, cookie login). Triggers: blocked site, bypass bot detection, cloudflare/WAF bypass, scrape, stealth browser, import cookies, fill form, screenshot, play youtube, xiaohongshu, douyin, weibo, bilibili, v2ex, wechat article, podcast transcript. NOT for simple searches (use web-search) or plain fetches (use webfetch).";
  prompt = builtins.readFile (skillDir + "/_body.md");
  references = {
    "agent-reach/README" = builtins.readFile (skillDir + "/references/agent-reach/README.md");
    "agent-reach/career" = builtins.readFile (skillDir + "/references/agent-reach/career.md");
    "agent-reach/dev" = builtins.readFile (skillDir + "/references/agent-reach/dev.md");
    "agent-reach/search" = builtins.readFile (skillDir + "/references/agent-reach/search.md");
    "agent-reach/social" = builtins.readFile (skillDir + "/references/agent-reach/social.md");
    "agent-reach/video" = builtins.readFile (skillDir + "/references/agent-reach/video.md");
    "agent-reach/web" = builtins.readFile (skillDir + "/references/agent-reach/web.md");
    "chrome-stealth" = builtins.readFile (skillDir + "/references/chrome-stealth.md");
    "insane-search/README" = builtins.readFile (skillDir + "/references/insane-search/README.md");
    "insane-search/cache-archive" = builtins.readFile (
      skillDir + "/references/insane-search/cache-archive.md"
    );
    "insane-search/fallback" = builtins.readFile (skillDir + "/references/insane-search/fallback.md");
    "insane-search/jina" = builtins.readFile (skillDir + "/references/insane-search/jina.md");
    "insane-search/json-api" = builtins.readFile (skillDir + "/references/insane-search/json-api.md");
    "insane-search/media" = builtins.readFile (skillDir + "/references/insane-search/media.md");
    "insane-search/metadata" = builtins.readFile (skillDir + "/references/insane-search/metadata.md");
    "insane-search/naver" = builtins.readFile (skillDir + "/references/insane-search/naver.md");
    "insane-search/playwright" = builtins.readFile (
      skillDir + "/references/insane-search/playwright.md"
    );
    "insane-search/public-api" = builtins.readFile (
      skillDir + "/references/insane-search/public-api.md"
    );
    "insane-search/rss" = builtins.readFile (skillDir + "/references/insane-search/rss.md");
    "insane-search/tls-impersonate" = builtins.readFile (
      skillDir + "/references/insane-search/tls-impersonate.md"
    );
    "insane-search/twitter" = builtins.readFile (skillDir + "/references/insane-search/twitter.md");
  };
  scripts = {
    "ATTRIBUTION.md" = builtins.readFile (skillDir + "/ATTRIBUTION.md");
    "engine/AGENTS.md" = builtins.readFile (skillDir + "/engine/AGENTS.md");
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
    "engine/templates/playwright_mobile_chrome.js" = builtins.readFile (
      skillDir + "/engine/templates/playwright_mobile_chrome.js"
    );
    "engine/templates/playwright_real_chrome.js" = builtins.readFile (
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
