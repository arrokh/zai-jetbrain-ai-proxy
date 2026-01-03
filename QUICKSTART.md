# Z.AI Proxy - Quick Start Guide

## Path Placeholder

**Note**: Replace `<PROJECT_ROOT>` with your actual project root path where you've saved the proxy scripts.

Example:
- If scripts are in: `/Users/username/projects/zai-proxy`
- Use: `cd /Users/username/projects/zai-proxy`

## Quick Start (2 steps)

### 1. Start the Proxy

```bash
cd <PROJECT_ROOT>
./manage.sh start
```

You should see:
```
✓ Z.AI Proxy started successfully
  PID: 12345
  URL: http://localhost:21435
  Logs: /tmp/zai-proxy.log
```

### 2. Configure IntelliJ

1. Open IntelliJ IDEA
2. Go to `Settings → AI Assistant → Third-party Providers`
3. Select **OpenAI-compatible**
4. Enter:
   - **Base URL**: `http://localhost:21435`
   - **API Key**: Your Z.AI API key
   - **Model**: `glm-4.7`
5. Click **Test Connection** ✅
6. Click **OK**

That's it! You can now use Z.AI GLM models in IntelliJ IDEA.

## Management Commands

```bash
cd <PROJECT_ROOT>

./manage.sh start    # Start the proxy
./manage.sh stop     # Stop the proxy
./manage.sh restart  # Restart the proxy
./manage.sh status   # Check if running
./manage.sh logs     # View logs (real-time)
./manage.sh test     # Test endpoints
```

## First Time Setup

### Install Dependencies (One-time)

```bash
pip3 install flask requests
```

### Make Script Executable (One-time)

```bash
chmod +x <PROJECT_ROOT>/manage.sh
```

## Changing the Port

**IMPORTANT**: TCP ports must be in the range 0-65535. The default is 21435.

To change the port:

1. Edit `zai-proxy.py`, line 84:
   ```python
   app.run(host='localhost', port=YOUR_PORT, debug=False)
   ```
   Replace `YOUR_PORT` with a number between 1024-65535.

2. Edit `manage.sh` and update the port in lines 29, 74, 106, 119

3. Restart the proxy:
   ```bash
   ./manage.sh restart
   ```

4. Update IntelliJ configuration with new port (e.g., `http://localhost:9000`)

**Common Port Choices**:
- `21435` - Default (HTTP alternative)
- `8765` - Less common
- `9000` - Development servers
- `11434` - Ollama's default

## Troubleshooting

### Port Already in Use

```bash
# Find what's using port 21435
lsof -i :21435

# Kill it
kill -9 <PID>

# Then start the proxy
./manage.sh start
```

### Invalid Port Error

**Error**: `OverflowError: bind(): port must be 0-65535`

**Solution**: Choose a port between 1024-65535. See "Changing the Port" section above.

### Connection Fails

```bash
# Check if proxy is running
./manage.sh status

# View logs
./manage.sh logs

# Test manually
curl http://localhost:21435/v1/models
```

### IntelliJ Test Connection Fails

1. Verify proxy is running: `./manage.sh status`
2. Restart IntelliJ IDEA
3. Verify base URL is exactly: `http://localhost:21435` (no trailing slash)
4. Check you're using the correct port if you changed it

## Testing the Proxy

```bash
cd <PROJECT_ROOT>
./manage.sh test
```

This will test both the models endpoint and chat completions endpoint.

## Advanced Usage

### Run in Background (Manual Method)

```bash
cd <PROJECT_ROOT>
python3 zai-proxy.py > /tmp/zai-proxy.log 2>&1 &
```

### Run in Foreground (For Debugging)

```bash
cd <PROJECT_ROOT>
python3 zai-proxy.py
```

Press `Ctrl+C` to stop.

### Check Logs

```bash
# Follow logs in real-time
tail -f /tmp/zai-proxy.log

# View last 50 lines
tail -n 50 /tmp/zai-proxy.log
```

## Available Models

- `glm-4.7` - Latest model (recommended)
- `glm-4.6` - Previous generation
- `glm-4.5` - Older generation
- `glm-4.5-air` - Lightweight/faster version

## What This Proxy Does

```
IntelliJ sends:  GET /v1/models
                ↓
Proxy rewrites: GET /v4/models
                ↓
Z.AI receives:   GET /v4/models ✅
```

IntelliJ hardcodes `/v1/` but Z.AI uses `/v4/`. This proxy bridges the gap.

## Need Help?

For detailed documentation, see [README.md](./README.md)

### Quick Commands

```bash
# Check status
./manage.sh status

# View logs
./manage.sh logs

# Run tests
./manage.sh test

# Restart
./manage.sh restart
```

### Common Issues

| Problem | Solution |
|---------|----------|
| Port in use | `lsof -i :21435` then `kill -9 <PID>` |
| Invalid port | Use port 1024-65535 |
| Connection fails | Check `./manage.sh status` |
| IntelliJ fails | Restart IntelliJ, verify URL |

---

**Last Updated**: 2026-01-03
**Default Port**: 21435 (configurable, must be 0-65535)
**For More Info**: See [README.md](./README.md)
