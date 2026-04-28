{ lib
, pkgs
, isDarwin
, npx
, defaultBrowser
, kebabToHuman
, ...
}:
let
  skillDir = ./_skill-creator;

  rawPrompt = builtins.readFile (skillDir + "/_body.md");

  prompt =
    builtins.replaceStrings
      [
        "agents/grader.md"
        "agents/comparator.md"
        "agents/analyzer.md"
        "eval-viewer/generate_review.py"
        "assets/eval_review.html"
      ]
      [
        "scripts/agents/grader.md"
        "scripts/agents/comparator.md"
        "scripts/agents/analyzer.md"
        "scripts/eval-viewer/generate_review.py"
        "scripts/assets/eval_review.html"
      ]
      rawPrompt;
in
{
  name = "skill-creator";
  description = "Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.";
  allowed-tools = [
    "Read"
    "Write"
    "Edit"
    "Bash"
    "Glob"
    "Grep"
    "WebFetch"
  ];
  scripts = {
    "agents/grader.md" = builtins.readFile (skillDir + "/agents/grader.md");
    "agents/comparator.md" = builtins.readFile (skillDir + "/agents/comparator.md");
    "agents/analyzer.md" = builtins.readFile (skillDir + "/agents/analyzer.md");
    "aggregate_benchmark.py" = builtins.readFile (skillDir + "/scripts/aggregate_benchmark.py");
    "generate_report.py" = builtins.readFile (skillDir + "/scripts/generate_report.py");
    "improve_description.py" = builtins.readFile (skillDir + "/scripts/improve_description.py");
    "package_skill.py" = builtins.readFile (skillDir + "/scripts/package_skill.py");
    "quick_validate.py" = builtins.readFile (skillDir + "/scripts/quick_validate.py");
    "run_eval.py" = builtins.readFile (skillDir + "/scripts/run_eval.py");
    "run_loop.py" = builtins.readFile (skillDir + "/scripts/run_loop.py");
    "utils.py" = builtins.readFile (skillDir + "/scripts/utils.py");
    "__init__.py" = builtins.readFile (skillDir + "/scripts/__init__.py");
    "eval-viewer/generate_review.py" = builtins.readFile (skillDir + "/eval-viewer/generate_review.py");
    "eval-viewer/viewer.html" = builtins.readFile (skillDir + "/eval-viewer/viewer.html");
    "assets/eval_review.html" = builtins.readFile (skillDir + "/assets/eval_review.html");
  };
  references = {
    "schemas" = builtins.readFile (skillDir + "/references/schemas.md");
  };
  inherit prompt;
}
