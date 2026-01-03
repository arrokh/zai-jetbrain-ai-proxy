# Z.AI Proxy for IntelliJ IDEA

A local proxy server that rewrites OpenAI-compatible API paths from `/v1/` to `/v4/` to enable Z.AI GLM models to work with IntelliJ IDEA's AI Assistant.

## Problem Solved

IntelliJ IDEA hardcodes `/v1/` in OpenAI-compatible API paths, but Z.AI uses `/v4/`. This proxy transparently rewrites requests:

- **IntelliJ sends**: `GET /v1/models`
- **Proxy rewrites to**: `GET /v4/models`
- **Z.AI receives**: `GET /v4/models` ✅

## Path Placeholder

**Note**: This documentation uses `<PROJECT_ROOT>` as a placeholder. Replace it with your actual project root path where the proxy scripts are located.

Example:
- If your scripts are in `/Users/username/projects/zai-proxy`
- Then `<PROJECT_ROOT>` = `/Users/username/projects/zai-proxy`

## Installation

### Prerequisites

```bash
# Install required Python packages
pip3 install flask requests
```

### Setup

1. Copy the proxy script to this directory
2. Ensure Python 3 is installed: `python3 --version`
3. Install dependencies (see Prerequisites above)

### Port Configuration

**IMPORTANT**: The proxy uses port 21435 by default. TCP ports must be in the range 0-65535.

To change the port, edit `zai-proxy.py` and modify line 84:

```python
app.run(host='localhost', port=21435, debug=False)  # Change 21435 to your desired port (1024-65535)
```

Also update the port in `manage.sh` (lines 29, 74, 106, 119) if using the management script.

**Common port choices**:
- `21435` - HTTP alternative (default)
- `8765` - Less commonly used
- `9000` - Development servers
- `11434` - Ollama's default
- Any port between `1024-65535`

## Usage

### Starting the Proxy

#### Option 1: Using Management Script (Recommended)

```bash
cd <PROJECT_ROOT>
./manage.sh start
```

#### Option 2: Foreground (Recommended for Testing)

```bash
cd <PROJECT_ROOT>
python3 zai-proxy.py
```

You'll see:
```
============================================================
Z.AI Proxy for IntelliJ IDEA
============================================================
Proxy listening on: http://localhost:21435
Target endpoint: https://api.z.ai/api/coding/paas
Path rewriting: /v1/ -> /v4/
============================================================

Ready to accept requests...
Press Ctrl+C to stop
```

**Keep this terminal window open** while using IntelliJ.

#### Option 3: Background (Recommended for Production)

```bash
cd <PROJECT_ROOT>
python3 zai-proxy.py > /tmp/zai-proxy.log 2>&1 &
```

The proxy will run in the background. Logs are written to `/tmp/zai-proxy.log`.

### Stopping the Proxy

```bash
# If using management script
cd <PROJECT_ROOT>
./manage.sh stop

# Or manually
pkill -f zai-proxy.py
```

Or if you know the PID:
```bash
kill <PID>
```

## Configuration

### IntelliJ IDEA Setup

1. **Open Settings**:
   - Go to `Settings → AI Assistant → Third-party Providers`

2. **Configure OpenAI-compatible Provider**:
   - Select **OpenAI-compatible**
   - **Base URL**: `http://localhost:21435` (or your custom port)
   - **API Key**: Your Z.AI API key
   - **Model**: `glm-4.7` (or `glm-4.6`, `glm-4.5`, `glm-4.5-air`)

3. **Test Connection**:
   - Click **Test Connection** button
   - Should show success with available models

4. **Save and Use**:
   - Click **OK** to save settings
   - Start using AI Assistant features in IntelliJ

## Management

### Check if Proxy is Running

```bash
# Method 1: Using management script
cd <PROJECT_ROOT>
./manage.sh status

# Method 2: Check process
ps aux | grep zai-proxy.py

# Method 3: Test endpoint
curl http://localhost:21435/v1/models
```

### View Logs

```bash
# Follow logs in real-time
tail -f /tmp/zai-proxy.log

# View last 50 lines
tail -n 50 /tmp/zai-proxy.log

# Search for errors
grep ERROR /tmp/zai-proxy.log
```

### Restart the Proxy

```bash
# Using management script
cd <PROJECT_ROOT>
./manage.sh restart

# Or manually
pkill -f zai-proxy.py
cd <PROJECT_ROOT>
python3 zai-proxy.py > /tmp/zai-proxy.log 2>&1 &
```

### Auto-start on Login (macOS)

#### Using LaunchAgent

Create `~/Library/LaunchAgents/com.zai.proxy.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zai.proxy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string><PROJECT_ROOT>/zai-proxy.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/zai-proxy.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/zai-proxy.log</string>
</dict>
</plist>
```

Replace `<PROJECT_ROOT>` with your actual path.

Load the agent:
```bash
launchctl load ~/Library/LaunchAgents/com.zai.proxy.plist
```

Unload to stop:
```bash
launchctl unload ~/Library/LaunchAgents/com.zai.proxy.plist
```

## Troubleshooting

### Port Already in Use

**Error**: `Address already in use`

**Solution**:
```bash
# Find what's using port 21435 (or your custom port)
lsof -i :21435

# Kill the process
kill -9 <PID>
```

### Invalid Port Number

**Error**: `OverflowError: bind(): port must be 0-65535`

**Solution**: The port number must be between 0-65535. Edit `zai-proxy.py` line 84 and choose a valid port.

### Connection Refused

**Error**: `curl: (7) Failed to connect to localhost port 21435`

**Solution**:
1. Check if proxy is running: `ps aux | grep zai-proxy.py`
2. Check logs: `tail -f /tmp/zai-proxy.log`
3. Restart the proxy (see Restart section above)

### IntelliJ Test Connection Fails

**Symptoms**: "Test Connection" button returns error

**Solutions**:
1. Verify proxy is running (see Check if Proxy is Running)
2. Verify base URL is `http://localhost:21435` (or your custom port, no trailing slash)
3. Check proxy logs for errors: `tail -f /tmp/zai-proxy.log`
4. Test manually: `curl http://localhost:21435/v1/models`
5. Restart IntelliJ IDEA after configuration changes

### Proxy Returns 404

**Symptoms**: Requests return 404 Not Found

**Solutions**:
1. Check proxy logs for path rewriting
2. Verify Z.AI API key is valid
3. Test Z.AI API directly:
   ```bash
   curl https://api.z.ai/api/coding/paas/v4/models \
     -H "Authorization: Bearer YOUR_API_KEY"
   ```
4. Check internet connection

### Permission Denied

**Error**: `Permission denied` when starting script

**Solution**:
```bash
chmod +x <PROJECT_ROOT>/zai-proxy.py
chmod +x <PROJECT_ROOT>/manage.sh
```

## Testing

### Manual Testing

```bash
# Test models endpoint
curl http://localhost:21435/v1/models \
  -H "Authorization: Bearer YOUR_API_KEY"

# Test chat completions
curl http://localhost:21435/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "glm-4.7",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 50
  }'
```

Expected response: JSON with model list or chat completion

### Using Management Script

```bash
cd <PROJECT_ROOT>
./manage.sh test
```

### Proxy Log Analysis

When working correctly, logs should show:
```
[PROXY] Rewriting path: /v1/models -> /v4/models
[PROXY] Forwarding to: https://api.z.ai/api/coding/paas/v4/models
[PROXY] Response: 200
```

## Available Models

- `glm-4.7` - Latest model (recommended)
- `glm-4.6` - Previous generation
- `glm-4.5` - Older generation
- `glm-4.5-air` - Lightweight version

## Architecture

```
IntelliJ IDEA          Local Proxy           Z.AI API
     │                      │                    │
     │  GET /v1/models      │                    │
     ├─────────────────────>│                    │
     │                      │  GET /v4/models    │
     │                      ├──────────────────>│
     │                      │  200 OK (models)   │
     │                      │<──────────────────┤
     │  200 OK (models)     │                    │
     │<─────────────────────┤                    │
```

## Security Notes

- The proxy only listens on `localhost` (127.0.0.1) - not accessible from external networks
- API keys are passed through headers - ensure your API key is kept secret
- Logs may contain request information - secure log files appropriately
- Only run this proxy when needed - consider using the LaunchAgent for controlled startup

## Performance

- Minimal overhead: Simple path rewriting and forwarding
- Latency: ~10-50ms additional to Z.AI API response time
- Concurrent requests: Supported via Flask's threaded server
- Resource usage: <50MB RAM typically

## File Structure

```
<PROJECT_ROOT>/
├── zai-proxy.py       # Main proxy server script
├── manage.sh          # Management script (start/stop/status/logs/test)
├── README.md          # This file
└── QUICKSTART.md      # Quick start guide
```

## Updates

### Updating the Proxy Script

1. Stop the proxy: `pkill -f zai-proxy.py` or `./manage.sh stop`
2. Replace/update `zai-proxy.py`
3. Restart the proxy
4. Test with `curl http://localhost:21435/v1/models` or `./manage.sh test`

### Changing the Port

1. Stop the proxy
2. Edit `zai-proxy.py`, find line 84: `app.run(host='localhost', port=21435, debug=False)`
3. Change `21435` to your desired port (must be 1024-65535)
4. If using `manage.sh`, also update the port in lines 29, 74, 106, 119
5. Restart the proxy
6. Update IntelliJ configuration with new port

### Updating Dependencies

```bash
pip3 install --upgrade flask requests
```

## Support

### Getting Help

If you encounter issues:

1. Check the Troubleshooting section above
2. Review logs: `tail -f /tmp/zai-proxy.log`
3. Test Z.AI API directly to isolate the issue
4. Check IntelliJ IDEA AI Assistant settings
5. Verify network connectivity

### Useful Commands Reference

```bash
# Quick status check
curl -s http://localhost:21435/v1/models | jq '.data[].id'

# Kill and restart
pkill -f zai-proxy.py && cd <PROJECT_ROOT> && python3 zai-proxy.py > /tmp/zai-proxy.log 2>&1 &

# Monitor with filtering
tail -f /tmp/zai-proxy.log | grep -E "(ERROR|Rewriting|Response)"

# Test full round-trip
curl -v http://localhost:21435/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"glm-4.7","messages":[{"role":"user","content":"test"}]}'

# Using management script
cd <PROJECT_ROOT>
./manage.sh status
./manage.sh logs
./manage.sh test
```

## License

This proxy is provided as-is for enabling Z.AI integration with JetBrains IDEs.

## Version History

- **v1.2** - Updated documentation with project root placeholder and port configuration notes
- **v1.1** - Fixed URL construction bugs, added CORS support, improved logging
- **v1.0** - Initial release with basic `/v1/` to `/v4/` path rewriting

---

**Last Updated**: 2026-01-03
**Compatible with**: IntelliJ IDEA 2025.3+
**Tested with**: Z.AI GLM-4.7
**Default Port**: 21435 (configurable, must be 0-65535)
