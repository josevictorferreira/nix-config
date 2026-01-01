{ config
, lib
, inputs
, ...
}:

let
  skillName = "fixing-rubocop";
  cfg = config.jvf.aiTools.skills."${skillName}";
  skillFullName = inputs.lib.strings.kebabToHuman skillName;
  skillOptions = {
    allowed-tools = [
      "Read"
      "Write"
      "Edit"
      "Bash"
      "Tool"
      "Grep"
      "Glob"
    ];
    name = skillName;
    description = "Expertise in fixing rubocop offenses across the Ruby and Ruby on Rails codebases.";
    model = "openrouter/z-ai/glm-4.7";
    tags = [
      "explorer"
      "documentation"
    ];
    scripts = {
      "check_cops.py" = ''
        #!/usr/bin/env python3
        """
        RuboCop Cop Documentation Fetcher

        Fetches documentation for a specific RuboCop cop from the official docs.
        Usage: python check_cops.py <cop_name>
        Example: python check_cops.py Style/StringLiterals
        """

        import sys
        import urllib.request
        import urllib.error
        import html.parser
        import re


        class CopPageParser(html.parser.HTMLParser):
            """Parser to extract cop documentation content from RuboCop docs."""

            def __init__(self):
                super().__init__()
                self.in_content = False
                self.in_code = False
                self.in_pre = False
                self.in_heading = False
                self.heading_level = 0
                self.current_tag = None
                self.content = []
                self.skip_tags = {"script", "style", "nav", "header", "footer"}
                self.skip_depth = 0

            def handle_starttag(self, tag, attrs):
                attrs_dict = dict(attrs)

                if tag in self.skip_tags:
                    self.skip_depth += 1
                    return

                if self.skip_depth > 0:
                    return

                if tag == "article" or (tag == "div" and "content" in attrs_dict.get("class", "")):
                    self.in_content = True

                if not self.in_content:
                    return

                self.current_tag = tag

                if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
                    self.in_heading = True
                    self.heading_level = int(tag[1])
                    self.content.append("\n" + "#" * self.heading_level + " ")
                elif tag == "pre":
                    self.in_pre = True
                    self.content.append("\n```ruby\n")
                elif tag == "code" and not self.in_pre:
                    self.in_code = True
                    self.content.append("`")
                elif tag == "p":
                    self.content.append("\n\n")
                elif tag == "li":
                    self.content.append("\n- ")
                elif tag == "br":
                    self.content.append("\n")
                elif tag == "strong" or tag == "b":
                    self.content.append("**")
                elif tag == "em" or tag == "i":
                    self.content.append("*")

            def handle_endtag(self, tag):
                if tag in self.skip_tags:
                    self.skip_depth -= 1
                    return

                if self.skip_depth > 0:
                    return

                if not self.in_content:
                    return

                if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
                    self.in_heading = False
                    self.content.append("\n")
                elif tag == "pre":
                    self.in_pre = False
                    self.content.append("\n```\n")
                elif tag == "code" and not self.in_pre:
                    self.in_code = False
                    self.content.append("`")
                elif tag == "strong" or tag == "b":
                    self.content.append("**")
                elif tag == "em" or tag == "i":
                    self.content.append("*")
                elif tag == "article":
                    self.in_content = False

                self.current_tag = None

            def handle_data(self, data):
                if self.skip_depth > 0:
                    return

                if self.in_content:
                    if self.in_pre:
                        self.content.append(data)
                    else:
                        text = data.strip()
                        if text:
                            if self.content and not self.content[-1].endswith(("\n", " ", "`", "*")):
                                self.content.append(" ")
                            self.content.append(text)

            def get_markdown(self):
                result = "".join(self.content)
                result = re.sub(r"\n{3,}", "\n\n", result)
                return result.strip()


        EXTENSION_DEPARTMENTS = {
            "capybara": "rubocop-capybara",
            "performance": "rubocop-performance",
            "rspec": "rubocop-rspec",
            "shopify": "rubocop-shopify",
            "rails": "rubocop-rails",
            "rake": "rubocop-rake",
            "rspecrails": "rubocop-rspec_rails",
            "threadsafety": "rubocop-thread_safety",
            "factorybot": "rubocop-factory_bot",
        }


        def get_base_url(cop_name):
            """Get the base URL based on the cop department."""
            department = cop_name.split("/")[0].lower()
            extension = EXTENSION_DEPARTMENTS.get(department)
            if extension:
                return f"https://docs.rubocop.org/{extension}"
            return "https://docs.rubocop.org/rubocop"


        def cop_to_url(cop_name):
            """Convert cop name to documentation URL."""
            parts = cop_name.split("/")
            if len(parts) != 2:
                raise ValueError(f"Invalid cop name format: {cop_name}. Expected format: Department/CopName")

            department, name = parts
            base_url = get_base_url(cop_name)
            anchor = f"{department.lower()}{name.lower()}"
            return f"{base_url}/cops_{department.lower()}.html#{anchor}"


        def fetch_cops_index(cop_name):
            """Fetch the cops index page to find all available cops."""
            base_url = get_base_url(cop_name)
            url = f"{base_url}/cops.html"
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

            with urllib.request.urlopen(req, timeout=30) as response:
                return response.read().decode("utf-8")


        def find_cop_url(cop_name, index_html):
            """Find the URL for a specific cop from the index page."""
            cop_escaped = re.escape(cop_name)
            pattern = rf'href="([^"]+)"[^>]*>\s*{cop_escaped}\s*</a>'
            match = re.search(pattern, index_html, re.IGNORECASE)

            if match:
                href = match.group(1)
                if href.startswith("http"):
                    return href
                base_url = get_base_url(cop_name)
                return f"{base_url}/{href}"

            return None


        def fetch_cop_page(url):
            """Fetch a cop documentation page."""
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

            with urllib.request.urlopen(req, timeout=30) as response:
                return response.read().decode("utf-8")


        def extract_cop_section(html_content, cop_name):
            """Extract the section for a specific cop from the page."""
            parts = cop_name.split("/")
            if len(parts) != 2:
                return html_content

            department, name = parts
            anchor_id = f"{department.lower()}{name.lower()}"

            anchor_pattern = rf'<h2[^>]*id="{re.escape(anchor_id)}"'
            match = re.search(anchor_pattern, html_content, re.IGNORECASE)

            if match:
                start = match.start()
                next_sect = re.search(r'<div class="sect1">', html_content[start + 10:])
                if next_sect:
                    end = start + 10 + next_sect.start()
                    return html_content[start:end]
                return html_content[start:]

            return None


        def parse_cop_documentation(html_content):
            """Parse HTML content and convert to markdown."""
            parser = CopPageParser()
            parser.feed(html_content)
            return parser.get_markdown()


        def main():
            if len(sys.argv) != 2:
                print("Usage: python check_cops.py <cop_name>")
                print("Example: python check_cops.py Style/StringLiterals")
                sys.exit(1)

            cop_name = sys.argv[1]

            if "/" not in cop_name:
                print(f"Error: Invalid cop name format '{cop_name}'")
                print("Expected format: Department/CopName (e.g., Style/StringLiterals)")
                sys.exit(1)

            try:


                index_html = fetch_cops_index(cop_name)
                cop_url = find_cop_url(cop_name, index_html)

                if not cop_url:
                    cop_url = cop_to_url(cop_name)

                page_html = fetch_cop_page(cop_url)
                section_html = extract_cop_section(page_html, cop_name)

                if section_html is None:
                    print(f"Error: Could not find documentation for cop '{cop_name}'", file=sys.stderr)
                    print(f"URL attempted: {cop_url}", file=sys.stderr)
                    sys.exit(1)

                markdown = parse_cop_documentation(section_html)

                if not markdown or len(markdown) < 50:
                    print(f"Warning: Could not extract meaningful content for {cop_name}", file=sys.stderr)
                    print(f"URL attempted: {cop_url}", file=sys.stderr)
                    sys.exit(1)

                print(f"# {cop_name}\n")
                print(f"Source: {cop_url}\n")
                print(markdown)

            except urllib.error.HTTPError as e:
                print(f"Error: HTTP {e.code} when fetching documentation", file=sys.stderr)
                print(f"The cop '{cop_name}' may not exist or the URL format has changed.", file=sys.stderr)
                sys.exit(1)
            except urllib.error.URLError as e:
                print(f"Error: Could not connect to RuboCop docs: {e.reason}", file=sys.stderr)
                sys.exit(1)
            except Exception as e:
                print(f"Error: {e}", file=sys.stderr)
                sys.exit(1)


        if __name__ == "__main__":
          main()
      '';
    };
    prompt = ''
      # ${skillFullName}

      Your task is to:
        - Analyze the provided RuboCop offense description.
        - Use the script `python scripts/check_cops.py {TypeOfCop/NameOfCop}` to fetch the most up-to-date documentation for the specified cop. Capture the output of the script.
        - Suggest the minimal code change to resolve the offense, adhering to the project's style guidelines.
        - If multiple fixes are possible, prioritize the most idiomatic Ruby solution.
        - Return the suggestion in a concise markdown code block.

      Script call example:
      `python scripts/check_cops.py Capybara/NegationMatcher`
    '';
  };
in
{
  options.jvf.aiTools.skills."${skillName}" = {
    enable = (lib.mkEnableOption "Enable the ${skillFullName} agent") // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.skills."${skillName}" = skillOptions;
    jvf.programs.claudecode.skills."${skillName}" = skillOptions;
  };
}
