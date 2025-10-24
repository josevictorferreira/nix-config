export OPENROUTER_API_KEY_TERMINAL=$(cat /run/secrets/openrouter_terminal)
export OPENROUTER_API_KEY_COMMIT=$(cat /run/secrets/openrouter_commit)
export OPENROUTER_API_KEY_AUTOCOMPLETE=$(cat /run/secrets/openrouter_autocomplete)
export OPENROUTER_API_KEY_CODE_AGENT=$(cat /run/secrets/openrouter_code_agent)

export CONTEXT7_API_KEY=$(cat /run/secrets/context7_api_key)

export GITHUB_TOKEN=$(cat /run/secrets/github_token)
