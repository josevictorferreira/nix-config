{ ... }:
{
  name = "rails-frontend-fix";
  description = "Fix bugs in frontend code of a Ruby on Rails application";
  agent = "";
  prompt = ''
    # Rails Frontend Fix

    <objective>
    Read, execute and fix the following bug/problem described:  $ARGUMENTS.
    </objective>

    <context>
    Read the project AGENTS.md to get context, also read the feature implementations in the .docs folder. Check if there's a subagent available to call named `rails-hotwire`, if so, then call it using @rails-hotwire. Otherwise do the task yourself.
    Remember also to use the tool `chrome-devtools` to debug the problem in the browser.
    </context>

    <process>
    - Read the AGENTS.md and .docs/features folder to get context about the project.
    - Explore the codebase and search for possible files that have the code responsible for the bug.
    - Use the `rails-hotwire` task and tell what and where it needs to be fixed.
    - After the subagent call is done and fixed the problem, verify if a new `spec` could be added to cover the behavior that was failing, if not dont add any new test. Use the task `@rspec-testing` to write and fix tests.
    - Check if the whole test suite in the project are passing running `./bin/parallel_rspec` or `bundle exec rspec`. If tests are failing, then fix them(using the @rspec-testing subagent) before going to the next step.
    - Run `bundle exec rubocop` to check if your fix does not add any rubocop offenses, if so, then fix all of them. 
    </process>

    <success_criteria>
    - The bug in question is fixed and tested in the browser using `chrome-devtools`.
    - All tests in the whole test suite are passing(GREEN) correctly.
    - All rubocop warnings/offenses are solved in the whole project. Zero offenses/warnings are allowed.
    </success_criteria>
  '';
}
