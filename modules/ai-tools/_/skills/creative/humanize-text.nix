{ ... }:
let
  skillDir = ./_humanize-text;
in
{
  name = "humanize-text";
  description = "Rewrite text to remove AI writing tells while preserving meaning, facts and the author's voice. Covers English and Brazilian Portuguese, each with its own bundled catalogue of language-specific tells. Use when asked to humanize, naturalize or de-AI writing (\"make this sound human\", \"remove the AI voice\", \"less AI-sounding\", \"de-slop this\", \"humanizar texto\", \"tirar cara de IA\", \"deixar mais natural\", \"parecer escrito por humano\"), or when reviewing prose for artificial formality, filler connectives, corporate vocabulary, inflated importance, generic conclusions, em-dash overuse and uniform rhythm.";
  metadata = {
    category = "creative";
    languages = "en, pt-BR";
    triggers = "humanize, humanise, de-AI, AI slop, AI-sounding, sounds like AI, make it sound human, more natural, less robotic, remove AI voice, rewrite text, edit prose, copy edit, tone of voice, writing style, em dash, English, humanizar, humanizar texto, cara de IA, texto de IA, parecer humano, deixar natural, revisar texto, reescrever texto, português, PT-BR, pt-br, portugues brasileiro, tom de voz, estilo de escrita";
  };
  prompt = builtins.readFile (skillDir + "/_body.md");
  references = {
    "english" = builtins.readFile (skillDir + "/references/english.md");
    "portugues-br" = builtins.readFile (skillDir + "/references/portugues-br.md");
  };
}
