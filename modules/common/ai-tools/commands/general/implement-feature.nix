{
  implement-feature = ''
    ---
    description: Plan and proceed to implement a new feature based on a prompt enhanced by a specified (or defaulted) model.
    agent: build
    ---
    !`prompt-enhancer feature "$ARGUMENTS"";`
  '';
}
