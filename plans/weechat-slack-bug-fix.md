# WeeChat Slack Integration Bug Fix Plan

## Root Cause Analysis

After examining the current configuration, I identified several issues:

1. **Missing Plugin Loading Configuration**: `wee-slack` is included in `defaultPlugins` but there's no explicit configuration to load the Python plugin in WeeChat's `plugins.conf`.

2. **No Slack Token Configuration**: The module lacks options for configuring Slack API tokens, which are required for Slack integration.

3. **Missing Script Auto-loading**: While the script is packaged, WeeChat doesn't automatically load Python scripts without explicit configuration.

## Implementation Phases

### Phase 1: Add Slack Configuration Options
- [ ] Add `jvf.programs.weechat.slack.enable` option
- [ ] Add `jvf.programs.weechat.slack.token` option for API token
- [ ] Add `jvf.programs.weechat.slack.autoConnect` option
- [ ] Add `jvf.programs.weechat.slack.workspaces` option for multiple workspaces

### Phase 2: Fix Plugin Loading Configuration
- [ ] Update `plugins.conf` to explicitly load Python scripts
- [ ] Add script auto-loading configuration for `wee-slack.py`
- [ ] Ensure Python dependencies are available

### Phase 3: Add Slack-Specific Configuration
- [ ] Add `slack.conf` configuration section
- [ ] Configure notification settings
- [ ] Set up workspace connection parameters
- [ ] Add display customization options

### Phase 4: Integrate with User Wrappers
- [ ] Ensure configuration files are properly propagated
- [ ] Verify user-specific installation works correctly
- [ ] Test with current `jvf.wrappers` system

### Phase 5: Testing and Validation
- [ ] Build configuration with `make check`
- [ ] Test WeeChat startup and plugin loading
- [ ] Verify Slack connection functionality
- [ ] Test message sending/receiving
- [ ] Run full rebuild test

## Expected Configuration Changes

### New Module Options
```nix
jvf.programs.weechat.slack = {
  enable = true;
  token = "xoxb-your-token-here";
  autoConnect = true;
  workspaces = {
    "workspace-name" = {
      token = "xoxb-workspace-token";
    };
  };
};
```

### Plugin Loading Fix
```nix
scripts = {
  description = "weechat-scripts package";
  autoload = "on";
  python = {
    autoload = "on";
    scripts = [ "wee-slack.py" ];
  };
};
```

### Slack Configuration
```nix
slackConfig = {
  look = {
   Nick truncation = "..."; # Add display options
  };
  workspace = {
    default = "workspace-name";
  };
};
```

## Technical Requirements

1. **Maintain Module Conventions**: Use `lib.mkIf cfg.enable`, proper types, kebab-case naming
2. **Ensure Cross-Platform Compatibility**: Code should work on both NixOS and Darwin
3. **Security**: Handle tokens securely without exposing in logs
4. **Error Handling**: Provide meaningful error messages for missing tokens/connection issues

## Success Criteria

- WeeChat starts without errors
- `/plugin list` shows `slack` plugin loaded
- `/slack workspaces` shows configured workspaces
- `/slack connect` successfully connects
- Messages appear in correct channels
- Notifications work as expected

## Files to Modify

1. `modules/programs/weechat.nix` - Main module updates
2. `.docs/weechat-slack-integration.md` - Documentation (if needed)

## Dependencies

1. Current `jvf.wrappers` system working correctly
2. Python environment available in WeeChat wrapper
3. Valid Slack API tokens for testing