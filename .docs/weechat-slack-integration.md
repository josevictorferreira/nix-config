# WeeChat Slack Integration

## Overview

WeeChat includes Slack and Matrix support via `wee-slack` and `weechat-matrix` plugins. The Slack token is loaded from sops secrets at startup.

## How It Works

1. **Token Storage**: Slack API token stored in sops at `slack_api_token`
2. **Runtime Loading**: On startup, a trigger reads `/run/secrets/slack_api_token` and sets it in WeeChat's secure data
3. **Plugin Config**: `plugins.var.python.slack.slack_api_token` references `${sec.data.slack_token}`

## Setup

### 1. Add Slack Token to sops

```bash
sops secrets/secrets.yaml
# Add: slack_api_token: xoxc-your-token-here
```

### 2. Enable WeeChat

```nix
{
  jvf.programs.weechat.enable = true;
}
```

### 3. Rebuild and Launch

```bash
make rebuild
weechat
```

## Getting Slack Tokens

### Session Token (Recommended)
1. Login to Slack in browser
2. Open DevTools → Network tab
3. Filter for `api` requests
4. Find `token` parameter (starts with `xoxc-`)
5. Also grab `d` cookie value
6. Token format: `xoxc-TOKEN:d-COOKIE`

### Bot Token
1. Go to [Slack API Apps](https://api.slack.com/apps)
2. Create app, add bot scopes, install to workspace
3. Copy Bot User OAuth Token (`xoxb-...`)

## Commands

- `/slack workspaces` - List workspaces
- `/slack connect` - Connect to Slack
- `/slack disconnect` - Disconnect
- `/join #channel` - Join channel
- `/msg @user text` - DM user

## Troubleshooting

### Token Not Loading
```
/secure list
```
Should show `slack_token`. If missing, check `/run/secrets/slack_api_token` exists.

### Plugin Errors
```
/python list
```
Should show `slack`. Check startup logs for Python errors.

### Connection Failed
- Verify token format
- Check token hasn't expired (session tokens expire)
- Try `/slack disconnect` then `/slack connect`

## Technical Details

The init script:
1. Creates trigger `slack_token_loader` to capture `/exec` output
2. Runs `/exec -hsignal slack_token cat /run/secrets/slack_api_token`
3. Trigger sets `/secure set slack_token ${out}`
4. wee-slack reads `${sec.data.slack_token}`

## Matrix Support

`weechat-matrix` is currently disabled (Python 3.13 compatibility issue with `future` package in nixpkgs).
