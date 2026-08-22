{ ... }:
let
  skillDir = ./_brainstorming;
in
{
  name = "brainstorming";
  description = "Collaborative dialogue that turns a still-undecided idea into an agreed design or spec. Use ONLY when the user is explicitly brainstorming what to build: they say \"brainstorm\", \"ideate\", \"let's think through\", \"explore options\", \"help me decide\", \"what should we build\", or they float a new feature or project whose requirements and shape are genuinely open and ask for help settling them. Do NOT use for implementation work, even when it produces something new: writing, fixing, refactoring or reviewing code; config, module or infrastructure changes; adding a package, tool or dependency; debugging; or answering a question — all of those proceed directly. If the user has already decided what they want, it is not brainstorming.";
  license = "MIT";
  metadata = {
    category = "planning";
    triggers = "brainstorm, ideate, explore options, help me decide, what should we build, new feature idea, requirements still open, undecided scope";
    source = "https://github.com/obra/superpowers/tree/main/skills/brainstorming";
  };
  prompt = builtins.readFile (skillDir + "/_body.md");
  references = {
    "visual-companion" = builtins.readFile (skillDir + "/references/visual-companion.md");
    "spec-document-reviewer-prompt" = builtins.readFile (skillDir + "/references/spec-document-reviewer-prompt.md");
  };
  scripts = {
    "server.cjs" = builtins.readFile (skillDir + "/scripts/server.cjs");
    "start-server.sh" = builtins.readFile (skillDir + "/scripts/start-server.sh");
    "stop-server.sh" = builtins.readFile (skillDir + "/scripts/stop-server.sh");
    "helper.js" = builtins.readFile (skillDir + "/scripts/helper.js");
    "frame-template.html" = builtins.readFile (skillDir + "/scripts/frame-template.html");
  };
}
