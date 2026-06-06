# Starship config generator — pure function of preset
# Returns the starship settings attrset for a given colors set.
# Re-exports mkStarshipSettings from parent module for aggregation use.
{ lib }:
{ preset }:
let
  c = preset.colors;
  green = "#${c.color2}";
  red = "#${c.color1}";
  blue = "#${c.color4}";
  black = "#${c.color0}";
  brightBlack = "#${c.color8}";
in
{
  aws.disabled = true;

  directory = {
    truncation_length = 0;
    truncate_to_repo = false;
  };

  add_newline = true;

  battery.disabled = true;

  format = "$directory$git_branch$git_status$nix_shell$fill$time$line_break$character";

  fill = {
    disabled = false;
    symbol = " ";
    style = "bold ${black}";
  };

  character = {
    success_symbol = "[➜](bold ${green})";
    error_symbol = "[✗](bold ${red})";
  };

  time = {
    disabled = false;
    format = "[$time]($style)";
    style = "bold ${brightBlack}";
  };

  cmd_duration.disabled = false;

  git_branch = {
    symbol = "🌱 ";
  };

  status = {
    disabled = false;
    format = "[$symbol$status]($style) ";
    symbol = "✖  ";
  };

  nix_shell = {
    disabled = false;
    format = "via [☃️ $state( \\($name\\))](bold ${blue}) ";
    symbol = "❄️ ";
    impure_msg = "[impure shell](bold ${red})";
    pure_msg = "[pure shell](bold ${green})";
    style = "bold ${blue}";
  };
}
