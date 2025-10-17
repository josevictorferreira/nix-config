{
  implement-fix = ''
    ---
    description: Plan and proceed to implement a bug fix based on a prompt enhanced by a specified (or defaulted) model.
    agent: build
    ---
    !`prompt-enhancer bugfix "$ARGUMENTS"";`
  '';
}
