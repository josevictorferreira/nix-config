{ ... }:
let
  skillDir = ./_brainstorming;
in
{
  name = "brainstorming";
  description = "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.";
  license = "MIT";
  metadata = {
    category = "planning";
    triggers = "brainstorm, design, spec, idea, feature, new project, requirements, approach, tradeoffs, mockup, wireframe, architecture, scope, decompose";
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
