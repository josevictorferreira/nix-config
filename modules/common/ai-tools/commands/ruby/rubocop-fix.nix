{ config
, lib
, inputs
, ...
}:
let
  commandName = "rubocop-fix";
  commandFullName = inputs.lib.strings.kebabToHuman commandName;
  cfg = config.jvf.aiTools.commands."${commandName}";
  commandDef = inputs.lib.aiTools.mkCommandModule {
    name = commandName;
    description = "Fix rubocop offenses/warnings found in a the given file";
    prompt = ''
      # ${commandFullName}

      <objective>
      Read, execute and fix all rubocop lint for the following file "$ARGUMENTS" running the command `bundle exec rubocop $ARGUMENTS`(name of the file).
      </objective>

      <context>
      Read the project AGENTS.md to get context.
      </context>

      <process>
      - Run `bundle exec rubocop $ARGUMENTS`, capture the output, and parse the offenses found.
      - Fix the rubocop offenses/warnings found, call the `fixing-rubocop` skill to fetch how to fix that offense, you can also check the `https://docs.rubocop.org/rubocop/cops.html` page to find every Cop error and the best way to fix them.
      - Run `bundle exec rubocop` to check if your fix does not add any other rubocop offenses, if so, then fix all of them. 
      - Finally run `./bin/parallel_tests` and check if your fix didn't cause any tests in the project to fail. If there's a failure, then fix it.
      </process>

      <success_criteria>
      - All rubocop warnings/offenses are solved in the given file.
      - All tests in the whole project are passing(GREEN)(`./bin/parallel_tests`) correctly.
      </success_criteria>
    '';
  };
in
{
  options.jvf.aiTools.commands."${commandName}" = commandDef.options;
  config = lib.mkIf cfg.enable commandDef.config;
}
