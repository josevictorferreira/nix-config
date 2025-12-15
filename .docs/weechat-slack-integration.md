# WeeChat Slack Integration Documentation

## Overview

The WeeChat module now includes full Slack integration support via the `wee-slack` Python plugin. This fixes the issue where the plugin was packaged but not properly configured for loading and use.

## Configuration

### Basic Setup

To enable Slack integration, add the following to your configuration:

```nix
{
  jvf.programs.weechat.slack = {
    enable = true;
    token = "xoxb-your-slack-bot-token-here";
    autoConnect = true;  # Optional, defaults to true
  };
}
```

### Multiple Workspaces

For multiple Slack workspaces:

```nix
{
  jvf.programs.weechat.slack = {
    enable = true;
    workspaces = {
      "company-main" = {
        token = "xoxb-primary-workspace-token";
        autoConnect = true;
      };
      "company-side" = {
        token = "xoxb-secondary-workspace-token";
        autoConnect = false;  # Connect manually
      };
    };
  };
}
```

### Getting Slack Tokens

1. Go to [Slack API Apps](https://api.slack.com/apps)
2. Create a new app or use an existing one
3. Add the "bot" scope
4. Install the app to your workspace
5. Copy the Bot User OAuth Token (starts with `xoxb-`)

## Usage

### Connecting to Slack

After rebuilding your system and starting WeeChat:

1. Verify the plugin is loaded: `/plugin list` (should show `slack`)
2. Available workspaces: `/slack workspaces`
3. Connect to a workspace: `/slack connect workspace-name`
4. View channels: `/buffer list`

### Basic Commands

- `/slack workspaces` - List configured workspaces
- `/slack connect [workspace]` - Connect to workspace
- `/slack disconnect [workspace]` - Disconnect from workspace
- `/slack away [status]` - Set away status
- `/slack back` - Remove away status

### Channel Operations

- `/join #channel-name` - Join a channel
- `/part #channel-name` - Leave a channel
- `/msg #channel-name text` - Send message to channel

## Files Modified

- `modules/programs/weechat.nix` - Added Slack configuration options and plugin loading
- `modules/roles/communication.nix` - Enabled Slack integration by default

## Technical Details

### What Was Fixed

1. **Plugin Loading**: Added explicit Python plugin loading configuration in `plugins.conf`
2. **Script Autoloading**: Ensures `wee-slack.py` is properly linked to autoload directory
3. **Configuration Options**: Added dedicated Slack configuration section
4. **Dependencies**: Included Python 3 runtime environment
5. **User Integration**: Proper script propagation through user wrappers

### Module Structure

The module now includes:
- JavaScript with TypeScript support
- Comprehensive plugin management
- Secure token handling
- Multi-workspace support
- Auto-connection capabilities

### Configuration Files

The setup creates these WeeChat configuration files:
- `weechat.conf` - Main WeeChat configuration
- `plugins.conf` - Plugin loading configuration (with Python enabled when Slack is enabled)
- `slack.conf` - Slack-specific settings (only included when Slack is enabled)
- Other existing config files (irc.conf, buflist.conf, etc.)

## Troubleshooting

### Plugin Not Loading

1. Check WeeChat startup logs for errors
2. Verify Python 3 is installed: `python3 --version`
3. Manually check plugin: `/python load wee_slack.py`

### Connection Issues

1. Verify token format: Should start with `xoxb-`
2. Check token permissions: Need appropriate workspace scopes
3. Test with `/slack connect workspace-name`

### Script Not Found

1. Rebuild system: `make rebuild`
2. Check file permissions in `~/.weechat/python/autoload/`
3. Verify wee-slack package is installed correctly

## Migration

If you were previously using the manual wee-slack setup:

1. Your existing configuration will migrate automatically
2. Token should be moved to the new module structure
3. The plugin will now auto-load on WeeChat startup

## Future Enhancements

- Automatic workspace discovery
- Enhanced notification controls
- Better error handling for invalid tokens
- Integration with system keyring for secure token storage