{
  ask = ''
    ---
    description: Answer a question based on a promprt enhanced by a specified (or defaulted) model.
    agent: build
    ---
    !`prompt-enhancer question "$ARGUMENTS";`
  '';
}
