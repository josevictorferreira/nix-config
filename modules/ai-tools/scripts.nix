# Aspect: ai-tools-scripts
# AI tool scripts: prompt-enhancer and rules-enforcer.
# Installs shell script packages for enhancing prompts and enforcing
# project rules via OpenRouter API.
{ ... }:
let
  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.aiTools.scripts = {
        "prompt-enhancer" = {
          enable = (lib.mkEnableOption "prompt enhancer") // {
            default = true;
          };

          username = lib.mkOption {
            type = lib.types.str;
            default = config.jvf.core.username;
            description = "Username for installing the script package.";
          };

          package = lib.mkOption {
            type = lib.types.package;
            description = "The prompt-enhancer script package (set internally).";
          };
        };

        "rules-enforcer" = {
          enable = (lib.mkEnableOption "rules enforcer") // {
            default = true;
          };

          username = lib.mkOption {
            type = lib.types.str;
            default = config.jvf.core.username;
            description = "Username for installing the script package.";
          };

          package = lib.mkOption {
            type = lib.types.package;
            description = "The rules-enforcer script package (set internally).";
          };
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      peCfg = config.jvf.aiTools.scripts."prompt-enhancer";
      reCfg = config.jvf.aiTools.scripts."rules-enforcer";

      opencodeExec = lib.getExe pkgs.opencode;

      rfc2119 = ''
        # RFC2119

        Network Working Group                                         S. Bradner
        Request for Comments: 2119                            Harvard University
        BCP: 14                                                       March 1997
        Category: Best Current Practice

        Key words for use in RFCs to Indicate Requirement Levels

        ## Abstract

        In many standards track documents several words are used to signify the requirements in the specification.  These words are often capitalized.  This document defines these words as they should be interpreted in IETF documents.  Authors who follow these guidelines should incorporate this phrase near the beginning of their document:

        The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", 
        "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

        ### 1. MUST

        This word, or the terms "REQUIRED" or "SHALL", mean that the definition is an absolute requirement of the specification.

        ### 2. MUST NOT

        This phrase, or the phrase "SHALL NOT", mean that the definition is an absolute prohibition of the specification.

        ### 3. SHOULD

        This word, or the adjective "RECOMMENDED", mean that there may exist valid reasons in particular circumstances to ignore a particular item, but the full implications must be understood and carefully weighed before choosing a different course.

        ### 4. SHOULD NOT

        This phrase, or the phrase "NOT RECOMMENDED" mean that there may exist valid reasons in particular circumstances when the particular behavior is acceptable or even useful, but the full implications should be understood and the case carefully weighed before implementing any behavior described with this label.

        ### 5. MAY

        This word, or the adjective "OPTIONAL", mean that an item is truly optional.  One vendor may choose to include the item because a particular marketplace requires it or because the vendor feels that it enhances the product while another vendor may omit the same item. An implementation which does not include a particular option MUST be prepared to interoperate with another implementation which does include the option, though perhaps with reduced functionality. In the same vein an implementation which does include a particular option MUST be prepared to interoperate with another implementation which does not include the option (except, of course, for the feature the option provides.)

        ### 6. Guidance in the use of these Imperatives

        Imperatives of the type defined in this memo must be used with care and sparingly.  In particular, they MUST only be used where it is actually required for interoperation or to limit behavior which has potential for causing harm (e.g., limiting retransmisssions)  For example, they must not be used to try to impose a particular method on implementors where the method is not required for interoperability.
      '';

      preludePrompt = ''
        ## Your role

        You are an expert at using AI-powered agentic tools, a skilled writer, and a masterful prompt engineer.

        ## Your mission

        Your job is to write an enhanced version of the prompt that follows below after the heading entitled 'Original Prompt', elaborating upon the ideas expressed in the supplied user prompt in ways that make sense in the context of this codebase to transform a simple input prompt into a thorough, detailed description..

        ### Guidelines that you always follow

        - To better inform you when writing enhanced prompts, before you begin writing an enhanced prompt you SHOULD first take advantage of your ability to use your tools to analyze the codebase and learn any information that is relevant to the task described by the original prompt the user provides to you.
        - You SHOULD begin the enhanced prompt with a straightforwards summary before continuing to elaborate and add detail and descriptiveness to the prompt supplied by the user.
        - You SHOULD make sure to mention relevant files in the codebase in the enhanced prompts you write.
        - To ensure clarity, you SHOULD use RFC2119 style language (MUST, SHOULD, MUST NOT, RECCOMEND, etc.) in the enhanced prompt when appropriate. You SHOULD use this language in the enhanced prompt, but you MUST NOT include a dedicated 'RFC2119 Compliance' section in the enhanced prompt that you write, and you SHOULD NOT include recommendations to use RFC2119 language in the enhanced prompts that you write.
        - You MUST reply with ONLY the enhanced prompt: You MUST not include a leading section heading like 'Enhanced prompt:', and SHOULD NOT include conversation, excessive explanations or lead-in, bullet points, placeholders, or surrounding quotes.
        - You MUST stay focused on enhancing the prompts that the user gives you, but you MUST NOT produce step-by-step plans: you SHOULD focus on  better describing WHAT the user's promp says they want to do, not on precisely HOW to do it.
        - You MUST format the enhanced prompts you write in a structured Markdown format, but you MUST not include surrounding code fences.
        - You MUST not include any internal monogue in the output.

        ## Original Prompt

      '';

      promptEnhancerPkg = pkgs.writeScriptBin "prompt-enhancer" ''
        #!/bin/bash
        PROMPT_ENHANCER_PRELUDE="${preludePrompt}"
        RFC2119="${rfc2119}"
        INCLUDE_RFC2119=2; # 1 for compliance phrase only, 2 for full (well, partially trimmed) RFC test.
        DEFAULT_ENHANCER_MODEL="openrouter/x-ai/grok-4.1-fast"; 
        DEBUG__LOG_ARGUMENTS="0";
        DEBUG__OUTPUT_FENCES="0";
        DEBUG__SKIP_ENHANCING="0";
        PUNCTUATION=""
        ENHANCER_ACTION=""
        OBJECT=""
        DEFINITE_OBJECT_FRAGMENT=""
        DEMONSTRATIVE_OBJECT_FRAGMENT=""
        ENHANCED_PROMPT_TITLE_HEADING=""
        EPILOGUE_INDEPENDANT_CLAUSE=""
        ENHANCER_SUPPLEMENTAL_PHRASE=""
        ARGS="$*";
        gsed() { sed "$@"; }
        if [[ "$ARGS" == *" "* ]]; then
          PROMPT_OBJECT_ARG="''${ARGS%% *}";
          REST="''${ARGS#* }";
        else
          PROMPT_OBJECT_ARG="$ARGS";
          REST="";
        fi;
        case $PROMPT_OBJECT_ARG in
          feature) 
            ENHANCED_PROMPT_TITLE_HEADING="New Feature Request";
            OBJECT="feature";
            ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT="this new $OBJECT";
            ;;
          change)
            ENHANCED_PROMPT_TITLE_HEADING="New Change Request";
            OBJECT="change";
            ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT="this new $OBJECT to the code's behaviour";
            ;;
          refactoring)
            ENHANCED_PROMPT_TITLE_HEADING="New Refactoring Request Specification";
            OBJECT="refactoring";
            ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT="this $OBJECT of the code";
            ;;
          tests)
            ENHANCED_PROMPT_TITLE_HEADING="New Test Request";
            OBJECT="test(s)";
            ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT="$OBJECT for these parts of the codebase";
            ENHANCER_SUPPLEMENTAL_PHRASE="Avoid writing pointless tests that simply test whether simple constant(s) have expected value(s): focus on testing the BEHAVIOUR of the code."
            DEMONSTRATIVE_OBJECT_FRAGMENT="these $OBJECT";
            ;;
          bugfix)
            ENHANCED_PROMPT_TITLE_HEADING="Critical Bug Fix Request";
            OBJECT="problem";
            ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT="a fix for this bug in the code";
            EPILOGUE_INDEPENDANT_CLAUSE="analyzing the problem thoroughly and diagnosing its root cause";
            ;;
          question) 
            ENHANCED_PROMPT_TITLE_HEADING="Do not edit the code! Just answer this question";
            OBJECT="question";
            ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT="this $OBJECT";
            ENHANCER_ACTION="Do not edit the code, just answer";
            PUNCTUATION="?";
            ;;
          bare)
            ENHANCED_PROMPT_TITLE_HEADING="ENHANCED_PROMPT_TITLE_HEADING";
            OBJECT="BARE"; # value disables some of the normal content.
            ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT="ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT";
            EPILOGUE_INDEPENDANT_CLAUSE="EPILOGUE_INDEPENDANT_CLAUSE";
            ;;
        esac;
        [[ -z $PUNCTUATION ]] &&\
          PUNCTUATION=".";
        [[ -z $ENHANCER_ACTION ]] &&\
          ENHANCER_ACTION="Implement";
        [[ -z $DEFINITE_OBJECT_FRAGMENT ]] &&\
          DEFINITE_OBJECT_FRAGMENT="the $OBJECT";
        [[ -z $DEMONSTRATIVE_OBJECT_FRAGMENT ]] &&\
          DEMONSTRATIVE_OBJECT_FRAGMENT="this $OBJECT";
        [[ -z $EPILOGUE_INDEPENDANT_CLAUSE ]] &&\
          EPILOGUE_INDEPENDANT_CLAUSE="thinking the implementation of $DEMONSTRATIVE_OBJECT_FRAGMENT through thoroughly";
        if [[ "$REST" == *" "* ]]; then
          MODEL="''${REST%% *}"           # second word
          USER_PROMPT="''${REST#* }"      # everything after second word
        else
          MODEL="$REST"               # if no space, second = rest
          USER_PROMPT=""              # nothing left
        fi
        if ! ${opencodeExec} models | grep -q "$MODEL"; then
          USER_PROMPT="$MODEL $USER_PROMPT";
          MODEL=$DEFAULT_ENHANCER_MODEL;
        fi;
        if [[ "$DEBUG__LOG_ARGUMENTS" == "1" ]]; then 
          echo -e "# Debug Information:\n";
          echo "ARGS='$ARGS'";
          echo "PROMPT_OBJECT_ARG='$PROMPT_OBJECT_ARG'"
          echo "MODEL='$MODEL'"
          echo "USER_PROMPT='$USER_PROMPT'"
          echo "REST='$REST'";
          echo "ENHANCED_PROMPT_TITLE_HEADING='$ENHANCED_PROMPT_TITLE_HEADING'";
          echo "EPILOGUE_INDEPENDANT_CLAUSE='$EPILOGUE_INDEPENDANT_CLAUSE'";
          echo "DEFINITE_OBJECT_FRAGMENT='$DEFINITE_OBJECT_FRAGMENT'";
          echo "DEMONSTRATIVE_OBJECT_FRAGMENT='$DEMONSTRATIVE_OBJECT_FRAGMENT'";
          i=0;
          for arg in "$@"; do
            echo "$i: $arg";
            i=$((i+1))
          done;
          echo;
        fi;
        if [[ -z "$ENHANCED_PROMPT_TITLE_HEADING" ]] || [[ -z "$USER_PROMPT" ]]; then
          echo "FATAL ERROR: The user has provided bad arguments to the command they tried to use, and as a result this prompt's content has been corrupted. Please remind the user that this command's first argument should be a model listed by the \`opencode models\` command and the remainder must constitute a non-empty string.";
          exit 0;
        fi;
        ENHANCED=$({
          echo "$PROMPT_ENHANCER_PRELUDE"
          
          if [[ "$OBJECT" != "BARE" ]]; then
              echo -en "$ENHANCER_ACTION $ENHANCER_INDEPENDANT_CLAUSE_FRAGMENT: "
          fi
          
          echo -e "''${USER_PROMPT}''${PUNCTUATION}"
          
          if [[ -n "$ENHANCER_SUPPLEMENTAL_PHRASE" ]]; then
              echo -e "\n$ENHANCER_SUPPLEMENTAL_PHRASE\n"
          fi
        });
        if [[ "$DEBUG__SKIP_ENHANCING" == "0" ]]; then
          if ! RAW_OUTPUT=$(echo "$ENHANCED" | ${opencodeExec} --model "$MODEL" --agent plan run); then
              echo "ERROR: 'opencode' execution failed. Please check your API keys and network connection."
              exit 1
          fi
          ENHANCED="$RAW_OUTPUT"
        else
          ENHANCED+=$'\n\n'"DEBUG__SKIP_ENHANCING is set, this is dummy data!";
        fi;
        ENHANCED=$(echo "$ENHANCED" | gsed 's/^#\+ *Enhanced.*//i');
        ENHANCED=$(echo "$ENHANCED" | gsed 's/^#/##/');
        ENHANCED=$(echo -e "$ENHANCED" | gsed -Ez 's/\n{3,}/\n\n/g');
        ENHANCED=$(echo -e "$ENHANCED" | awk 'NF{p=1} p');
        [[ $INCLUDE_RFC2119 -ge 1 && $OBJECT != "BARE" && $OBJECT != "question" ]] &&\
          ENHANCED="The key words \"MUST\", \"MUST NOT\", \"REQUIRED\", \"SHALL\", \"SHALL NOT\", \"SHOULD\", \"SHOULD NOT\", \"RECOMMENDED\",  \"MAY\", and \"OPTIONAL\" in this document are to be interpreted as described in RFC 2119.\n\n''${ENHANCED}\n";
        [[ $OBJECT != "BARE" ]] &&\
          ENHANCED="# ''${ENHANCED_PROMPT_TITLE_HEADING}:\n\n''${ENHANCED}";
        if [[ $OBJECT != "BARE" && $OBJECT != "question" ]]; then
          ENHANCED=$({              
                      [[ $INCLUDE_RFC2119 -ge 2 ]] && echo "$RFC2119";
                      echo -e "$ENHANCED\n";
                      echo -e "## IMPORTANT: Employ our standard pracices to maximize the odds of successful implementation!\n";
                      echo -e "So long as you proceed systematically, work hard, and adhere to our standard practices, your successful completion of the task is as good as guaranteed! Remember:\n"
                      echo -e "- Start by $EPILOGUE_INDEPENDANT_CLAUSE. Then, you MUST break the implementation of $DEMONSTRATIVE_OBJECT_FRAGMENT down into small steps to produce a detailed, step-by-step plan that you will use to implement $DEMONSTRATIVE_OBJECT_FRAGMENT. Group the plan's steps into \"phases\": the code MUST continue to build correctly and all tests MUST pass after each phase is completed.";
                      echo -e "- Next, write the plan into an appropriately named new Markdown file in the project's ./.docs/plans/ directory which includes checkboxes in which to mark the completion of each step.";
                      echo -e "- Proceed to systematically implement the plan that you just wrote in the Markdown file. You MUST check off each step you've completed in the Markdown file immediately as you complete it, you MAY NOT proceed to the next step until you have checked off the current step.";
                      echo -e "- Follow through and finish the job: you MUST continue complete the task! Keep working until every step in the Markdown file has been checked off and the entire plan has been completed. The code MUST build correctly and all tests MUST pass afterwards.";
                    });
        fi;
        [[ "$DEBUG__OUTPUT_FENCES" == "1" ]] && echo "BEGIN";
        echo -e "''${ENHANCED}";
        [[ "$DEBUG__OUTPUT_FENCES" == "1" ]] && echo "END";
        exit 0;
      '';

      rulesEnforcerModel = "openai/gpt-oss-120b";

      rulesEnforcerPkg = pkgs.writeShellApplication {
        name = "rules-enforcer";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          #!/bin/bash
          set -euo pipefail

          # DEBUG mode - set to "true" to enable verbose logging
          DEBUG="''${DEBUG:-false}"

          # Model to use for OpenRouter API requests (can be changed by user)
          MODEL="${rulesEnforcerModel}"

          # Read the JSON input from stdin
          INPUT_JSON=$(cat)

          if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG] INPUT_JSON received: $INPUT_JSON" >&2
          fi

          # Extract the prompt from the JSON input
          USER_PROMPT=$(echo "$INPUT_JSON" | jq -r '.prompt // empty')

          if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG] USER_PROMPT extracted: ''${USER_PROMPT:0:100}..." >&2
          fi

          if [[ -z "$USER_PROMPT" ]]; then
            if [[ "$DEBUG" == "true" ]]; then
              echo "[DEBUG] No prompt found in JSON, returning input." >&2
            fi
            echo "$INPUT_JSON"
            exit 0
          fi

          # Get the current working directory
          CURRENT_PATH="$(pwd)"

          if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG] CURRENT_PATH: $CURRENT_PATH" >&2
          fi

          # Find and read all markdown files in .docs/rules/
          PROJECT_RULES=""

          # Check for .docs/rules.md
          if [[ -f "$CURRENT_PATH/.docs/rules.md" ]]; then
            if [[ "$DEBUG" == "true" ]]; then
              echo "[DEBUG] Found .docs/rules.md, reading content..." >&2
            fi
            PROJECT_RULES="''${PROJECT_RULES}$(cat "$CURRENT_PATH/.docs/rules.md")"
            PROJECT_RULES="''${PROJECT_RULES}"$'\n\n'
          else
            if [[ "$DEBUG" == "true" ]]; then
              echo "[DEBUG] .docs/rules.md not found" >&2
            fi
          fi

          # Check for .docs/rules/ directory and read all .md files
          if [[ -d "$CURRENT_PATH/.docs/rules" ]]; then
            if [[ "$DEBUG" == "true" ]]; then
              echo "[DEBUG] Found .docs/rules/ directory, scanning for .md files..." >&2
            fi
            while IFS= read -r -d '''''' file; do
              if [[ "$file" == *.md ]]; then
                if [[ "$DEBUG" == "true" ]]; then
                  echo "[DEBUG] Reading file: $file" >&2
                fi
                PROJECT_RULES="''${PROJECT_RULES}"$'\n\n---\n\n'
                PROJECT_RULES="''${PROJECT_RULES}$(cat "$file")"
              fi
            done < <(find "$CURRENT_PATH/.docs/rules" -type f -name "*.md" -print0)
          else
            if [[ "$DEBUG" == "true" ]]; then
              echo "[DEBUG] .docs/rules/ directory not found" >&2
            fi
          fi

          if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG] PROJECT_RULES length: ''${#PROJECT_RULES} characters" >&2
            echo "[DEBUG] PROJECT_RULES preview:" >&2
            echo "---BEGIN---" >&2
            echo "''${PROJECT_RULES:0:500}" >&2
            echo "---END---" >&2
          fi

          # Exit quietly if no rules found
          if [[ -z "''${PROJECT_RULES//[[:space:]]/}" ]]; then
            if [[ "$DEBUG" == "true" ]]; then
              echo "[DEBUG] No rules found, returning input." >&2
            fi
            echo "$INPUT_JSON"
            exit 0
          fi

          # Build the user message content with proper escaping
          USER_CONTENT="Rules:\n''${PROJECT_RULES}\n\nUser Prompt:\n''${USER_PROMPT}"

          if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG] USER_CONTENT length: ''${#USER_CONTENT} characters" >&2
          fi

          # Make the OpenRouter API request using jq for proper JSON escaping
          JSON_BODY=$(echo '{}' | jq -n --arg model "$MODEL" --arg system_content "Given the following rules and the user prompt, return the text of all rules that may be useful for executing what the user asked. Be concise and only include relevant rules." --arg user_content "$USER_CONTENT" '{model:$model,messages:[{role:"system",content:$system_content},{role:"user",content:$user_content}]}')

          # Check for API key
          if [[ -z "''${OPENROUTER_API_KEY_CODE_AGENT:-}" ]]; then
            if [[ "$DEBUG" == "true" ]]; then
              echo "[DEBUG] OPENROUTER_API_KEY_CODE_AGENT not set, returning input." >&2
            fi
            echo "$INPUT_JSON"
            exit 0
          fi

          API_RESPONSE=$(echo "$JSON_BODY" | curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" -H "Content-Type: application/json" -H "Authorization: Bearer $OPENROUTER_API_KEY_CODE_AGENT" -H "HTTP-Referer: $CURRENT_PATH" --data-binary @-)

          if [[ "$DEBUG" == "true" ]]; then
            echo "[DEBUG] API_RESPONSE received: ''${API_RESPONSE:0:200}..." >&2
          fi

          # Extract rules output
          RULES_OUTPUT=$(echo "$API_RESPONSE" | jq -r '.choices[0].message.content // empty')

          if [[ -n "$RULES_OUTPUT" ]]; then
            # Append rules to prompt and return full JSON
            NEW_PROMPT="''${USER_PROMPT}"$'\n\n'"Rules to follow:"$'\n'"''${RULES_OUTPUT}"
            echo "$INPUT_JSON" | jq --arg new_prompt "$NEW_PROMPT" '.prompt = $new_prompt'
          else
            # Return original input if no output from API
            echo "$INPUT_JSON"
          fi
        '';
      };
    in
    {
      imports = [ mkOptions ];

      config = lib.mkMerge [
        {
          # Set the internally-built packages as option defaults
          jvf.aiTools.scripts."prompt-enhancer".package = lib.mkDefault promptEnhancerPkg;
          jvf.aiTools.scripts."rules-enforcer".package = lib.mkDefault rulesEnforcerPkg;
        }
        (lib.mkIf peCfg.enable {
          users.users."${peCfg.username}".packages = [ peCfg.package ];
        })
        (lib.mkIf reCfg.enable {
          users.users."${reCfg.username}".packages = [ reCfg.package ];
        })
      ];
    };
in
{
  flake.modules.nixos.ai-tools-scripts = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-scripts = mkConfig { isDarwin = true; };
}
