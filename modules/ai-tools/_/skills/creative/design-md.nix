{ lib
, pkgs
, isDarwin
, npx
, defaultBrowser
, kebabToHuman
, ...
}:
let
  skillDir = ./_design-md;
  prompt = builtins.readFile (skillDir + "/_body.md");
in
{
  name = "design-md";
  description = "Author/validate/export Google's DESIGN.md token spec files.";
  licence = "MIT";
  metadata = {
    category = "creative";
    triggers = "DESIGN.md, design tokens, design system, visual identity, token spec, WCAG, contrast, Tailwind, DTCG, Google design spec";
  };
  prompt = prompt;
  templates = {
    "starter.md" = builtins.readFile (skillDir + "/templates/starter.md");
  };
}
