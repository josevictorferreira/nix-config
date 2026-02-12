{ config
, lib
, inputs
, ...
}:
let
  skillName = "patching-files";
  skillFullName = inputs.lib.strings.kebabToHuman skillName;
  cfg = config.jvf.aiTools.skills."${skillName}";
  skillOptions = {
    allowed-tools = [
      "Read"
      "Bash"
    ];
    name = skillName;
    model = "openrouter/openai/gpt-oss-120b:exacto";
    description = "High-speed code patching tool. Use this skill when you need to apply edits to files without rewriting the entire file context, or when specifically asked to use Relace/Instant Apply. It uses a specialized model to merge sparse edits into source code at high speed.";
    tags = [
    ];
    scripts = {
      "patch.py" = ''
        import argparse
        import json
        import fileinput
        import sys
        import os
        import requests

        # Configuration
        OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
        MODEL_ID = "relace/relace-apply-3"

        def apply_patch(file_path, instruction, edit_snippet, api_key):
            # 1. Read the initial code from the target file
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    initial_code = f.read()
            except FileNotFoundError:
                print(f"Error: File not found at {file_path}", file=sys.stderr)
                sys.exit(1)

            # 2. Construct the prompt specifically for Relace Apply 3
            # Format: <instruction>{instr}</instruction><code>{code}</code><update>{snippet}</update>
            prompt_content = (
                f"<instruction>{instruction}</instruction>\n"
                f"<code>{initial_code}</code>\n"
                f"<update>{edit_snippet}</update>"
            )

            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/skill-creator", # Required by OpenRouter
                "X-Title": "Claude Skill Relace Patcher"
            }

            data = {
                "model": MODEL_ID,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt_content
                    }
                ],
                "temperature": 0 # Deterministic patching is usually preferred
            }

            print(f"Sending request to {MODEL_ID} for {file_path}...", file=sys.stderr)
            
            # 3. Call the API
            try:
                response = requests.post(OPENROUTER_URL, headers=headers, json=data)
                response.raise_for_status()
                result = response.json()
            except Exception as e:
                print(f"API Error: {e}", file=sys.stderr)
                if 'response' in locals():
                    print(response.text, file=sys.stderr)
                sys.exit(1)

            # 4. Extract and Output
            try:
                patched_code = result['choices'][0]['message']['content']
                
                # Overwrite the file directly
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(patched_code)
                    
                print(f"Successfully patched {file_path}")
                
            except (KeyError, IndexError) as e:
                print("Error parsing response from LLM provider.", file=sys.stderr)
                print(json.dumps(result, indent=2), file=sys.stderr)
                sys.exit(1)

        if __name__ == "__main__":
            parser = argparse.ArgumentParser(description="Apply AI code patches via Relace")
            parser.add_argument("--file-path", required=True, help="Path to the file to patch")
            parser.add_argument("--api-key", help="OpenRouter API Key (optional if env var set)")
            
            args = parser.parse_args()
            
            # Resolve API Key
            api_key = args.api_key or os.environ.get("OPENROUTER_API_KEY_CODE_AGENT")
            if not api_key:
                print("Error: OpenRouter API key is required via --api-key or OPENROUTER_API_KEY_CODE_AGENT env var", file=sys.stderr)
                sys.exit(1)

            # Read JSON input from stdin
            try:
                input_data = json.load(sys.stdin)
                instruction = input_data.get("instruction")
                edit_snippet = input_data.get("edit_snippet")
                
                if not instruction or not edit_snippet:
                    raise ValueError("JSON input must contain 'instruction' and 'edit_snippet'")
                    
            except (json.JSONDecodeError, ValueError) as e:
                print(f"Input Error: {e}", file=sys.stderr)
                print("Expects JSON on stdin: {\"instruction\": \"...\", \"edit_snippet\": \"...\"}", file=sys.stderr)
                sys.exit(1)

            apply_patch(args.file_path, instruction, edit_snippet, api_key)
      '';
    };
    prompt = ''
      # ${skillFullName}
               
      This skill allows you to patch code files using `relace-apply-3` via OpenRouter. This is significantly more token-efficient than rewriting full files because you only generate the changes.

      ## Workflow

      1.  **Analyze**: Identify the file content (`initial_code`) and the specific changes needed (`instruction`).
      2.  **Generate Snippet**: Create a sparse `edit_snippet` representing the changes (see Guidelines below).
      3.  **Execute**: Run the `scripts/patch.py` script to perform the merge.

      ## Formatting Guidelines (CRITICAL)

      When generating the `edit_snippet`, you **must not** output the full file. You must abbreviate unchanged sections using specific comment patterns.

      - Abbreviate sections of the code in your response that will remain the same by replacing those sections with a comment like  "// ... rest of code ...", "// ... keep existing code ...", "// ... code remains the same".
      - Be precise with the location of these comments within your edit snippet. A less intelligent model will use the context clues you provide to accurately merge your edit snippet.
      - If applicable, it can help to include some concise information about the specific code segments you wish to retain "// ... keep calculateTotalFunction ... ".
      - If you plan on deleting a section, you must provide the context to delete it. Some options:
          1. If the initial code is ```code \n Block 1 \n Block 2 \n Block 3 \n code```, and you want to remove Block 2, you would output ```// ... keep existing code ... \n Block 1 \n  Block 3 \n // ... rest of code ...```.
          2. If the initial code is ```code \n Block \n code```, and you want to remove Block, you can also specify ```// ... keep existing code ... \n // remove Block \n // ... rest of code ...```.
      - You must use the comment format applicable to the specific code provided to express these truncations.
      - Preserve the indentation and code structure of exactly how you believe the final code will look (do not output lines that will not be in the final code after they are merged).
      - Be as length efficient as possible without omitting key context.

      **Valid Abbreviation Patterns:**
      - `// ... rest of code ...`
      - `// ... keep existing code ...`
      - `// ... code remains the same ...` (in language-appropriate syntax, e.g., `# ...` for Python)

      **Deletion Rules:**
      To delete a block, you must provide the surrounding context:
      ```javascript
      // ... keep existing code ...
      // remove BlockName
      // ... rest of code ... 
      ```

      ## Execution Instructions

      The python script expects the patch parameters via **Standard Input (stdin)** as a JSON object, and the target file path as an argument.

      **Parameters:**
      1. `--file-path` (Argument): The relative path to the file you are modifying.
      2. `stdin` (Input): A JSON object containing:
         - `instruction`: Natural language description of changes.
         - `edit_snippet`: The sparse code block (must be properly escaped string).

      **Command Protocol:**
      To avoid shell escaping issues with code snippets, you **must** use a HEREDOC pattern to write the JSON to a temporary file first, then pipe it to the script.

      ```bash
      # 1. Construct the Payload (Ensure strict JSON formatting)
      cat <<EOF > /tmp/patch_payload.json
      {
        "instruction": "Your instruction here",
        "edit_snippet": "Your sparse code here with \\n for newlines"
      }
      EOF

      # 2. Run the Script
      python3 scripts/patch.py --file-path "src/target_file.py" < /tmp/patch_payload.json
      ```
    '';
  };
  skillDef = inputs.lib.aiTools.mkSkillModule { inherit skillOptions; };
in
{
  options.jvf.aiTools.skills."${skillName}" = skillDef.options;
  config = lib.mkIf cfg.enable skillDef.config;
}
