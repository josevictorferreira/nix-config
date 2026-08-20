{ ... }:
let
  skillDir = ./_humanize-text-ptbr;
in
{
  name = "humanize-text-ptbr";
  description = "Rewrite Brazilian Portuguese text to remove AI writing tells while preserving meaning, facts and the author's voice. Use when asked to humanize, naturalize or de-AI PT-BR writing (\"humanizar texto\", \"tirar cara de IA\", \"deixar mais natural\", \"parecer escrito por humano\"), or when reviewing PT-BR prose for artificial formality, filler connectives, corporate vocabulary, inflated importance, generic conclusions and uniform rhythm.";
  metadata = {
    category = "creative";
    language = "pt-BR";
    triggers = "humanizar, humanizar texto, cara de IA, texto de IA, parecer humano, deixar natural, revisar texto, reescrever texto, português, PT-BR, pt-br, portugues brasileiro, tom de voz, estilo de escrita, humanize, de-AI, AI slop";
  };
  prompt = builtins.readFile (skillDir + "/_body.md");
}
