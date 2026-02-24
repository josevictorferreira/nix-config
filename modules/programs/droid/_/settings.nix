# Default Droid settings and custom models
# Pure data export - no module boilerplate
{ mcps }:
{
  settings = {
    mcpServers = mcps;
    customModels = [
      {
        model = "minimax/minimax-m2.1";
        displayName = "Minimax M2.1 [OpenRouter]";
        baseUrl = "https://openrouter.ai/api/v1";
        apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
      }
      {
        model = "z-ai/glm-4.7";
        displayName = "GLM 4.7 [OpenRouter]";
        baseUrl = "https://openrouter.ai/api/v1";
        apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
      }
      {
        model = "moonshotai/kimi-k2-thinking";
        displayName = "Kimi K2 Thinking [OpenRouter]";
        baseUrl = "https://openrouter.ai/api/v1";
        apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
      }
      {
        model = "moonshotai/kimi-k2-0905:exacto";
        displayName = "Minimax K2 0905 [OpenRouter]";
        baseUrl = "https://openrouter.ai/api/v1";
        apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
      }
      {
        model = "z-ai/glm-4.6:exacto";
        displayName = "GLM 4.6 [OpenRouter]";
        baseUrl = "https://openrouter.ai/api/v1";
        apiKey = "OPENROUTER_API_KEY_CODE_AGENT";
      }
    ];
  };
}
