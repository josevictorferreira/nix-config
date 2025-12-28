{ config
, lib
, inputs
, ...
}:

let
  agentName = "ruby-stealth-scraping";
  cfg = config.jvf.aiTools.agents."${agentName}";
  agentFullName = inputs.lib.strings.kebabToHuman agentName;
  agentOptions = rec {
    name = agentName;
    description = "Specialist in stealthy web scraping with Ruby using Ferrum headless browser. Use when building scrapers that need to evade bot detection, bypass anti-scraping measures, or when working with Cloudflare-protected sites. Triggers include requests for web scraping, data extraction, headless browsing, bot evasion, proxy rotation, user-agent rotation, or Ferrum configuration in Ruby/Rails projects.";
    tools = [
      "Read"
      "Write"
      "Bash"
      "WebFetch"
    ];
    tags = [
      "explorer"
      "documentation"
      "browser"
    ];
    mode = "subagent";
    model = "openrouter/z-ai/glm-4.7";
    references = {
      "bandwidth-optimization" = ''
        # Bandwidth Optimization

        ## Why Block Resources

        - Proxy bandwidth costs money (typically $X/GB)
        - Images, videos, fonts are unnecessary for data extraction
        - Blocking can achieve 2-5x bandwidth savings

        ## Resource Blocking

        ```ruby
        blocked_images = %w[.jpg .jpeg .png .gif .bmp .svg .webp .avif]
        blocked_videos = %w[.mp4 .avi .mov .mkv .webm]
        blocked_sounds = %w[.mp3 .ogg .wav .aac .flac]
        blocked_fonts  = %w[.woff .woff2 .ttf .otf .eot]
        blocked_extensions = blocked_images + blocked_videos + blocked_sounds + blocked_fonts

        browser.network.intercept
        browser.on(:request) do |request|
          if blocked_extensions.any? { |ext| request.url.end_with?(ext) }
            request.abort
          else
            request.continue
          end
        end
        ```

        ## What NOT to Block

        - **CSS files** - Blocking CSS can trigger anti-bot measures and Cloudflare challenges
        - **JavaScript** - Required for dynamic content and may trigger detection
        - **API endpoints** - Often contain the data you need

        ## Expected Savings

        | Site Type | Without Blocking | With Blocking | Savings |
        |-----------|-----------------|---------------|---------|
        | E-commerce | 5-10 MB | 1-2 MB | 5x |
        | News sites | 3-5 MB | 0.5-1 MB | 4x |
        | Simple pages | 1-2 MB | 0.3-0.5 MB | 3x |
      '';
      "full-implementation" = ''
        # Complete Stealth Scraper Implementation

        ## HttpOpts Class

        Place in `app/models/http_opts.rb` or similar autoloaded location:

        ```ruby
        class HttpOpts
          USER_AGENTS = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
          ].freeze

          BASE_HEADERS = {
            "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "Accept-Encoding" => "gzip, deflate, br, zstd",
            "Accept-Language" => "en-GB,en-US;q=0.9,en;q=0.8",
            "Cache-Control" => "no-cache",
            "Pragma" => "no-cache",
            "Priority" => "u=0, i",
            "Upgrade-Insecure-Requests" => "1"
          }.freeze

          def self.ferrum_options
            options = {
              headless: "new",
              timeout: 35,
              window_size: [1366, 768],
              extensions: [Rails.root.join("lib/scraping/stealth.min.js")],
              browser_options: { "disable-blink-features" => "AutomationControlled" }
            }

            options[:browser_path] = ENV["BROWSER_PATH"] if ENV["BROWSER_PATH"].present?
            
            options[:proxy] = {
              host: ENV["PROXY_HOST"],
              port: ENV["PROXY_PORT"].to_i,
              user: ENV["PROXY_USER"],
              password: ENV["PROXY_PASSWORD"]
            } if Rails.env.production? && ENV["PROXY_HOST"].present?

            options
          end

          def self.headers
            user_agent = USER_AGENTS.sample
            
            BASE_HEADERS
              .merge("User-Agent" => user_agent)
              .merge(user_agent_hints(user_agent))
          end

          private

          def self.user_agent_hints(user_agent_string)
            chrome_version = user_agent_string.match(/Chrome\/(\d+)\./)[1]
            
            platform = case user_agent_string
                       when /Macintosh/ then "macOS"
                       when /Windows/ then "Windows"
                       when /Linux/ then "Linux"
                       else "macOS"
                       end

            {
              "Sec-Ch-Ua" => "\"Google Chrome\";v=\"#{chrome_version}\", \"Chromium\";v=\"#{chrome_version}\", \"Not_A Brand\";v=\"24\"",
              "Sec-Ch-Ua-Mobile" => "?0",
              "Sec-Ch-Ua-Platform" => "\"#{platform}\"",
              "Sec-Fetch-Dest" => "document",
              "Sec-Fetch-Mode" => "navigate",
              "Sec-Fetch-Site" => "cross-site",
              "Sec-Fetch-User" => "?1"
            }
          end
        end
        ```

        ## Browser Initialization

        ```ruby
        def init_ferrum_browser
          browser = Ferrum::Browser.new(HttpOpts.ferrum_options)
          browser.headers.set(HttpOpts.headers)

          # Block unnecessary resources
          blocked_images = %w[.jpg .jpeg .png .gif .bmp .svg .webp .avif]
          blocked_videos = %w[.mp4 .avi .mov .mkv .webm]
          blocked_sounds = %w[.mp3 .ogg .wav .aac .flac]
          blocked_fonts  = %w[.woff .woff2 .ttf .otf .eot]
          blocked_extensions = blocked_images + blocked_videos + blocked_sounds + blocked_fonts

          browser.network.intercept
          browser.on(:request) do |request|
            if blocked_extensions.any? { |ext| request.url.end_with?(ext) }
              request.abort
            else
              request.continue
            end
          end

          browser
        end
        ```

        ## Usage Example

        ```ruby
        browser = init_ferrum_browser
        browser.goto("https://example.com")

        # Extract data
        title = browser.at_css("h1")&.text
        links = browser.css("a").map { |a| a["href"] }

        # Take screenshot for debugging
        browser.screenshot(path: "debug.png", full: true)

        # Always close when done
        browser.quit
        ```

        ## Setup Checklist

        1. Install gems: `bundle add ferrum brotli zstd-ruby`
        2. Download stealth plugin: `npx extract-stealth-evasions`
        3. Move `stealth.min.js` to `lib/scraping/`
        4. Set environment variables for proxy (production)
        5. Test at https://bot.sannysoft.com
      '';
      "proxy-config" = ''
        # Proxy Configuration

        ## Types of Proxies

        | Type | Cost | Detection Risk | Use Case |
        |------|------|----------------|----------|
        | Datacenter | Low | High | Initial testing, low-security sites |
        | Residential | Medium | Low | Production scraping, protected sites |
        | Mobile | High | Very Low | High-security targets |

        ## Ferrum Proxy Setup

        ```ruby
        opts = {
          headless: "new",
          timeout: 35,
          window_size: [1366, 768],
          browser_options: { "disable-blink-features" => "AutomationControlled" }
        }

        # Only proxy in production to save bandwidth costs
        opts[:proxy] = {
          host: "proxy.example.com",
          port: 1000,
          user: ENV["PROXY_USER"],
          password: ENV["PROXY_PASSWORD"]
        } if Rails.env.production?

        browser = Ferrum::Browser.new(opts)
        ```

        ## Dynamic vs Static IPs

        - **Dynamic (Rotating)**: New IP per request or session - best for scraping
        - **Static**: Same IP - useful for maintaining sessions

        ## Cost Optimization

        - Proxy bandwidth is typically charged per GB
        - Block unnecessary resources to reduce bandwidth (see bandwidth-optimization.md)
        - Use datacenter proxies for development/testing
        - Reserve residential proxies for production only
      '';
      "user-agent-rotation" = ''
        # User-Agent Rotation

        ## Why Rotate User Agents

        Even with proxy rotation, duplicate IPs can occur. Different user agents make it harder to link requests back to the same scraper.

        ## User Agent Pool

        ```ruby
        USER_AGENTS = [
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
        ]
        ```

        ## User-Agent Client Hints

        Modern browsers send client hints that must match the user agent:

        ```ruby
        def user_agent_hints(user_agent_string)
          chrome_version = user_agent_string.match(/Chrome\/(\d+)\./)[1]
          
          # Detect platform from user agent
          platform = case user_agent_string
                     when /Macintosh/ then "macOS"
                     when /Windows/ then "Windows"
                     when /Linux/ then "Linux"
                     else "macOS"
                     end

          {
            "Sec-Ch-Ua" => "\"Google Chrome\";v=\"#{chrome_version}\", \"Chromium\";v=\"#{chrome_version}\", \"Not_A Brand\";v=\"24\"",
            "Sec-Ch-Ua-Mobile" => "?0",
            "Sec-Ch-Ua-Platform" => "\"#{platform}\"",
            "Sec-Fetch-Dest" => "document",
            "Sec-Fetch-Mode" => "navigate",
            "Sec-Fetch-Site" => "cross-site",
            "Sec-Fetch-User" => "?1"
          }
        end
        ```

        ## Integration

        ```ruby
        user_agent = USER_AGENTS.sample
        headers = base_headers
          .merge("User-Agent" => user_agent)
          .merge(user_agent_hints(user_agent))

        browser.headers.set(headers)
        ```

        ## Important

        - Match user-agent hints to the user agent string
        - Keep Chrome versions current (update every few months)
        - Platform in hints must match platform in user agent
      '';
    };
    scripts = { };
    prompt = ''
      # ${agentFullName}

      Expert guidance for building undetectable web scrapers using Ruby and Ferrum.

      ## Core Setup

      Initialize Ferrum with stealth configuration:

      ```ruby
      headers = {
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Accept-Encoding" => "gzip, deflate, br, zstd",
        "Accept-Language" => "en-GB,en-US;q=0.9,en;q=0.8",
        "Cache-Control" => "no-cache",
        "Pragma" => "no-cache",
        "Sec-Fetch-Dest" => "document",
        "Sec-Fetch-Mode" => "navigate",
        "Sec-Fetch-Site" => "cross-site",
        "Sec-Fetch-User" => "?1",
        "Upgrade-Insecure-Requests" => "1"
      }

      opts = {
        headless: "new",
        timeout: 35,
        window_size: [1366, 768],
        extensions: [Rails.root.join("lib/scraping/stealth.min.js")],
        browser_options: { "disable-blink-features" => "AutomationControlled" }
      }

      browser = Ferrum::Browser.new(opts)
      browser.headers.set(headers)
      ```

      ## Critical Evasions

      1. **Disable AutomationControlled** - Most important flag to hide
      2. **Use Chrome's new headless mode** - `headless: "new"` runs real Chrome without display
      3. **Non-standard window size** - Avoid default 1024x768, use 1366x768 or similar
      4. **Install stealth plugin** - Run `npx extract-stealth-evasions` and include stealth.min.js

      ## Quick Reference

      - **Proxy setup**: See [references/proxy-config.md](references/proxy-config.md)
      - **User-agent rotation**: See [references/user-agent-rotation.md](references/user-agent-rotation.md)
      - **Bandwidth optimization**: See [references/bandwidth-optimization.md](references/bandwidth-optimization.md)
      - **Complete implementation**: See [references/full-implementation.md](references/full-implementation.md)

      ## Required Gems

      ```ruby
      gem "ferrum"
      gem "brotli"      # For br encoding
      gem "zstd-ruby"   # For zstd encoding
      ```

      ## Bot Detection Testing

      Validate your setup at:
      - https://bot.sannysoft.com
      - https://httpbun.com/headers

      ## When to Escalate

      Move from datacenter to residential proxies when:
      - Block rate exceeds 10%
      - Cloudflare challenges persist
      - IP bans occur within hours

      ---

      ## References

      ${lib.concatStringsSep "\n\n" (lib.attrValues references)}
    '';
  };
in
{
  options.jvf.aiTools.agents."${agentName}" = {
    enable = (lib.mkEnableOption "Enable the ${agentFullName} agent") // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.agents."${agentName}" = agentOptions;
    jvf.programs.claudecode.agents."${agentName}" = agentOptions;
  };
}
