# Aspect: roles-ai-development
# Bundles AI/LLM development tools and vibe coding assistants.
# Imports AI-related program aspects and installs user-level AI packages.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  # web_search Pi tool backed by the OmniRoute Search API (POST /v1/search).
  # Reads OMNIROUTE_API_KEY (exported from the sops omniroute_api_key secret).
  # Cross-platform (pure fetch + process.env), so used by both nixos and darwin.
  webSearchExtension = ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
    import { Type } from "typebox";
    import { StringEnum } from "@earendil-works/pi-ai";

    const ENDPOINT = "https://omniroute.josevictor.me/v1/search";
    const PROVIDERS = [
      "serper-search",
      "brave-search",
      "perplexity-search",
      "exa-search",
      "tavily-search",
      "google-pse-search",
      "linkup-search",
      "searchapi-search",
      "searxng-search",
    ] as const;

    export default function (pi: ExtensionAPI) {
      pi.registerTool({
        name: "web_search",
        label: "Web Search",
        description:
          "Search the live web (or news) via the OmniRoute Search API and " +
          "return ranked results with titles, URLs and snippets. Use this to " +
          "look up current information not in the model's training data.",
        promptSnippet:
          "web_search: search the live web/news for up-to-date information.",
        promptGuidelines: [
          "Use web_search when you need current or external information that " +
            "may not be in your training data (recent events, docs, prices).",
          "Prefer a focused query; set search_type to \"news\" for recent news.",
        ],
        parameters: Type.Object({
          query: Type.String({
            minLength: 1,
            maxLength: 500,
            description: "The search query (1-500 characters).",
          }),
          max_results: Type.Optional(
            Type.Integer({
              minimum: 1,
              maximum: 20,
              description: "Number of results to return (1-20, default 5).",
            }),
          ),
          search_type: Type.Optional(
            StringEnum(["web", "news"] as const, {
              description: "Search category (default \"web\").",
            }),
          ),
          provider: Type.Optional(
            StringEnum(PROVIDERS, {
              description:
                "Optional search provider; omit to let OmniRoute auto-select.",
            }),
          ),
        }),
        async execute(_toolCallId, params, signal) {
          const apiKey = process.env.OMNIROUTE_API_KEY;
          if (!apiKey) {
            return {
              content: [
                {
                  type: "text",
                  text: "web_search error: OMNIROUTE_API_KEY is not set in the environment.",
                },
              ],
              details: {},
              isError: true,
            };
          }

          const body: Record<string, unknown> = {
            query: params.query,
            max_results: params.max_results ?? 5,
            search_type: params.search_type ?? "web",
          };
          if (params.provider) body.provider = params.provider;

          const timeout = AbortSignal.timeout(60000);
          const abort = signal
            ? AbortSignal.any([signal, timeout])
            : timeout;

          let response: Response;
          try {
            response = await fetch(ENDPOINT, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: "Bearer " + apiKey,
              },
              body: JSON.stringify(body),
              signal: abort,
            });
          } catch (err) {
            return {
              content: [
                { type: "text", text: "web_search request failed: " + String(err) },
              ],
              details: {},
              isError: true,
            };
          }

          if (!response.ok) {
            const errText = await response.text().catch(() => "");
            return {
              content: [
                {
                  type: "text",
                  text:
                    "web_search HTTP " + response.status + ": " + errText,
                },
              ],
              details: { status: response.status },
              isError: true,
            };
          }

          const data = (await response.json()) as {
            provider: string;
            query: string;
            cached: boolean;
            results: Array<{
              title: string;
              url: string;
              display_url?: string;
              snippet: string;
              position: number;
            }>;
            usage: { queries_used: number; search_cost_usd: number };
          };

          const results = data.results ?? [];
          const lines: string[] = [];
          if (results.length === 0) {
            lines.push("No results found for: " + data.query);
          } else {
            for (const r of results) {
              lines.push(r.position + ". " + r.title);
              lines.push("   " + (r.display_url ?? r.url));
              if (r.snippet) lines.push("   " + r.snippet);
              lines.push("");
            }
          }
          lines.push(
            "[provider: " +
              data.provider +
              ", cached: " +
              data.cached +
              ", queries_used: " +
              data.usage.queries_used +
              ", cost_usd: " +
              data.usage.search_cost_usd +
              "]",
          );

          return {
            content: [{ type: "text", text: lines.join("\n") }],
            details: {
              provider: data.provider,
              cached: data.cached,
              usage: data.usage,
              resultCount: results.length,
            },
          };
        },
      });
    }
  '';

  # web_fetch Pi tool backed by the OmniRoute web-fetch API (POST /v1/web/fetch).
  # Reads OMNIROUTE_API_KEY (exported from the sops omniroute_api_key secret).
  # Cross-platform (pure fetch + process.env), so used by both nixos and darwin.
  webFetchExtension = ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
    import { Type } from "typebox";
    import { StringEnum } from "@earendil-works/pi-ai";

    const ENDPOINT = "https://omniroute.josevictor.me/v1/web/fetch";
    const PROVIDERS = [
      "serper-search",
      "brave-search",
      "perplexity-search",
      "exa-search",
      "tavily-search",
      "google-pse-search",
      "linkup-search",
      "searchapi-search",
      "searxng-search",
    ] as const;

    export default function (pi: ExtensionAPI) {
      pi.registerTool({
        name: "web_fetch",
        label: "Web Fetch",
        description:
          "Fetch a single web page via the OmniRoute web-fetch API and return " +
          "its content as markdown (or html). Use this to read the full text of " +
          "a known URL, e.g. documentation, articles or search-result pages.",
        promptSnippet:
          "web_fetch: fetch and read the content of a specific web page URL.",
        promptGuidelines: [
          "Use web_fetch when you have a specific URL and need its full content " +
            "(not a search). Pair it with web_search to read a result's page.",
          "Prefer format \"markdown\" for reading; use \"html\" only when you need raw markup.",
        ],
        parameters: Type.Object({
          url: Type.String({
            minLength: 1,
            description: "The absolute URL of the page to fetch.",
          }),
          format: Type.Optional(
            StringEnum(["markdown", "html"] as const, {
              description: "Output format (default \"markdown\").",
            }),
          ),
          full_page: Type.Optional(
            Type.Boolean({
              description:
                "Fetch the full rendered page instead of the main content (default false).",
            }),
          ),
          provider: Type.Optional(
            StringEnum(PROVIDERS, {
              description:
                "Optional fetch provider; omit to let OmniRoute auto-select.",
            }),
          ),
        }),
        async execute(_toolCallId, params, signal) {
          const apiKey = process.env.OMNIROUTE_API_KEY;
          if (!apiKey) {
            return {
              content: [
                {
                  type: "text",
                  text: "web_fetch error: OMNIROUTE_API_KEY is not set in the environment.",
                },
              ],
              details: {},
              isError: true,
            };
          }

          const body: Record<string, unknown> = {
            url: params.url,
            format: params.format ?? "markdown",
            full_page: params.full_page ?? false,
          };
          if (params.provider) body.provider = params.provider;

          const timeout = AbortSignal.timeout(60000);
          const abort = signal
            ? AbortSignal.any([signal, timeout])
            : timeout;

          let response: Response;
          try {
            response = await fetch(ENDPOINT, {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: "Bearer " + apiKey,
              },
              body: JSON.stringify(body),
              signal: abort,
            });
          } catch (err) {
            return {
              content: [
                { type: "text", text: "web_fetch request failed: " + String(err) },
              ],
              details: {},
              isError: true,
            };
          }

          if (!response.ok) {
            const errText = await response.text().catch(() => "");
            return {
              content: [
                {
                  type: "text",
                  text:
                    "web_fetch HTTP " + response.status + ": " + errText,
                },
              ],
              details: { status: response.status },
              isError: true,
            };
          }

          const data = (await response.json()) as {
            provider: string;
            url: string;
            content: string;
            links: string[];
            metadata: Record<string, unknown> | null;
            screenshot_url: string | null;
          };

          const content = data.content ?? "";
          const links = data.links ?? [];
          const lines: string[] = [];
          if (content.length === 0) {
            lines.push("No content returned for: " + data.url);
          } else {
            lines.push(content);
          }
          lines.push("");
          lines.push(
            "[provider: " +
              data.provider +
              ", url: " +
              data.url +
              ", links: " +
              links.length +
              "]",
          );

          return {
            content: [{ type: "text", text: lines.join("\n") }],
            details: {
              provider: data.provider,
              url: data.url,
              linkCount: links.length,
              hasScreenshot: data.screenshot_url != null,
            },
          };
        },
      });
    }
  '';

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.ai-development = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  nixosModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.ai-development;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        programs-ck-search
        programs-lsp-mcp
        programs-opencode
        programs-claudecode
        programs-rtk
        programs-gemini
        programs-hermes-agent
        programs-forgecode
        programs-pi
        programs-vix
        programs-crush
      ]);

      config = {
        # Sub-feature enables
        jvf.programs.gemini.antigravity.enable = true;

        # AI Tools enables
        jvf.aiTools.mcp.chrome-devtools.enable = true;
        jvf.aiTools.mcp.jira.enable = true;
        jvf.aiTools.mcp.grafana.enable = false;

        jvf.aiTools.mcp.grafanaWork.enable = false;

        # Pi extensions (declarative install via sentinel postInstall)
        jvf.programs.pi.extensions = [
          "npm:pi-mcp-adapter"
        ];

        # MCP servers glued into Pi via pi-mcp-adapter. codegraph is a
        # Linux-only oh-my-openagent binary (absolute path required).
        jvf.programs.pi.mcps = {
          context7 = {
            command = "npx";
            args = [
              "-y"
              "@upstash/context7-mcp"
            ];
          };
          codegraph = {
            command = "/home/${cfg.username}/.omo/codegraph/bin/codegraph";
            args = [
              "serve"
              "--mcp"
            ];
          };
          grep_app = {
            url = "https://mcp.grep.app";
          };
          lsp = {
            command = "npx";
            args = [
              "-y"
              "language-server-mcp"
            ];
          };
        };

        # Local Pi extension: web_search tool (OmniRoute Search API).
        jvf.programs.pi.extensionFiles."web-search.ts" = webSearchExtension;

        # Local Pi extension: web_fetch tool (OmniRoute web-fetch API).
        jvf.programs.pi.extensionFiles."web-fetch.ts" = webFetchExtension;

        # Claude Code settings (YOLO mode — bypass all permission prompts)
        jvf.programs.claudecode.theme = "tokyonight";
        jvf.programs.claudecode.settings = {
          permissions = {
            defaultMode = "bypassPermissions";
          };
          attribution = {
            commit = "";
            pr = "";
          };
        };

        users.users."${cfg.username}".packages = [
          pkgs.pi-coding-agent
        ];
      };
    };

  darwinModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.ai-development;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with darwinAspects; [
        programs-ck-search
        programs-lsp-mcp
        programs-opencode
        programs-claudecode
        programs-rtk
        programs-gemini
        programs-hermes-agent
        programs-forgecode
        programs-pi
        programs-vix
        programs-crush
      ]);

      config = {
        # Sub-feature enables
        jvf.programs.gemini.antigravity.enable = true;

        # AI Tools enables
        jvf.aiTools.mcp.chrome-devtools.enable = true;
        jvf.aiTools.mcp.jira.enable = true;
        jvf.aiTools.mcp.grafana.enable = false;

        jvf.aiTools.mcp.grafanaWork.enable = false;

        # Pi extensions (declarative install via sentinel postInstall)
        jvf.programs.pi.extensions = [
          "npm:pi-mcp-adapter"
        ];

        # MCP servers glued into Pi via pi-mcp-adapter (codegraph is
        # Linux-only, so it is omitted from the darwin block).
        jvf.programs.pi.mcps = {
          context7 = {
            command = "npx";
            args = [
              "-y"
              "@upstash/context7-mcp"
            ];
          };
          grep_app = {
            url = "https://mcp.grep.app";
          };
          lsp = {
            command = "npx";
            args = [
              "-y"
              "language-server-mcp"
            ];
          };
        };

        # Local Pi extension: web_search tool (OmniRoute Search API).
        jvf.programs.pi.extensionFiles."web-search.ts" = webSearchExtension;

        # Local Pi extension: web_fetch tool (OmniRoute web-fetch API).
        jvf.programs.pi.extensionFiles."web-fetch.ts" = webFetchExtension;

        # Claude Code settings (YOLO mode — bypass all permission prompts)
        jvf.programs.claudecode.theme = "tokyonight";
        jvf.programs.claudecode.settings = {
          permissions = {
            defaultMode = "bypassPermissions";
          };
          attribution = {
            commit = "";
            pr = "";
          };
        };

        users.users."${cfg.username}".packages = [
          pkgs.pi-coding-agent
        ];
      };
    };
in
{
  flake.modules.nixos.roles-ai-development = nixosModule;
  flake.modules.darwin.roles-ai-development = darwinModule;
}
