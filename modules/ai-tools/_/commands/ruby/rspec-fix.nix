{ ... }:
{
  name = "rspec-fix";
  description = "Fix rspec tests failures in the given file";
  agent = "";
  prompt = ''
    # Rspec Fix

    <objective>
    Read, execute and fix all rspec tests for the following file "$ARGUMENTS" running the command `bundle exec rspec $ARGUMENTS`(name of the file).
    </objective>

    <context>
    Read the project AGENTS.md to get context, also read the feature implementations in the .docs folder. Check if there's a subagent available to call named `rspec-testing`, if so, then call it using @rspec-testing. Otherwise do the task yourself.
    </context>

    <process>
    - Run `bundle exec rspec $ARGUMENTS`, capture the output, and parse failing examples.
    - Fix the failing examples, always ensure the spec still reflects the expected application behavior, you fix the problem by editing the source code or test files as needed (only when the spec does not make sence with the current application expected behaviour).
    - Run `bundle exec rubocop` to check if your fix does not add any rubocop offenses, if so, then fix all of them. 
    </process>

    <success_criteria>
    - All tests in the following file are passing(GREEN) correctly.
    - All rubocop warnings/offenses are solved in the whole project.
    </success_criteria>
  '';
}
