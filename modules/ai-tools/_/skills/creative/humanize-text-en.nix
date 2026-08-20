{ ... }:
let
  skillDir = ./_humanize-text-en;
in
{
  name = "humanize-text-en";
  description = "Rewrite English text to remove AI writing tells while preserving meaning, facts and the author's voice. Use when asked to humanize, naturalize or de-AI English writing (\"make this sound human\", \"remove the AI voice\", \"less AI-sounding\", \"de-slop this\"), or when reviewing English prose for artificial formality, filler connectives, corporate vocabulary, inflated importance, generic conclusions, em-dash overuse and uniform rhythm.";
  metadata = {
    category = "creative";
    language = "en";
    triggers = "humanize, humanise, de-AI, AI slop, AI-sounding, sounds like AI, make it sound human, more natural, less robotic, remove AI voice, rewrite text, edit prose, copy edit, tone of voice, writing style, em dash, English";
  };
  prompt = builtins.readFile (skillDir + "/_body.md");
}
