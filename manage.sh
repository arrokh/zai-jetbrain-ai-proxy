#!/bin/bash
# Z.AI Proxy Management Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_SCRIPT="$SCRIPT_DIR/zai-proxy.py"
PID_FILE="/tmp/zai-proxy.pid"
LOG_FILE="/tmp/zai-proxy.log"

case "$1" in
  start)
    if [ -f "$PID_FILE" ]; then
      PID=$(cat "$PID_FILE")
      if ps -p "$PID" > /dev/null 2>&1; then
        echo "Z.AI Proxy is already running (PID: $PID)"
        exit 1
      else
        rm "$PID_FILE"
      fi
    fi

    echo "Starting Z.AI Proxy..."
    python3 "$PROXY_SCRIPT" > "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 2

    if ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
      echo "✓ Z.AI Proxy started successfully"
      echo "  PID: $(cat $PID_FILE)"
      echo "  URL: http://localhost:21435"
      echo "  Logs: $LOG_FILE"
    else
      echo "✗ Failed to start Z.AI Proxy"
      echo "  Check logs: tail -n 20 $LOG_FILE"
      rm "$PID_FILE"
      exit 1
    fi
    ;;

  stop)
    if [ ! -f "$PID_FILE" ]; then
      echo "Z.AI Proxy is not running"
      exit 1
    fi

    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
      echo "Stopping Z.AI Proxy (PID: $PID)..."
      kill "$PID"
      sleep 1
      if ps -p "$PID" > /dev/null 2>&1; then
        echo "Force killing..."
        kill -9 "$PID"
      fi
      rm "$PID_FILE"
      echo "✓ Z.AI Proxy stopped"
    else
      echo "Z.AI Proxy was not running (cleaning up PID file)"
      rm "$PID_FILE"
    fi
    ;;

  restart)
    $0 stop
    sleep 1
    $0 start
    ;;

  status)
    if [ -f "$PID_FILE" ]; then
      PID=$(cat "$PID_FILE")
      if ps -p "$PID" > /dev/null 2>&1; then
        echo "✓ Z.AI Proxy is running"
        echo "  PID: $PID"
        echo "  URL: http://localhost:21435"
        echo "  Logs: $LOG_FILE"
        echo ""
        echo "Recent logs:"
        tail -n 5 "$LOG_FILE" 2>/dev/null || echo "  No logs available"
      else
        echo "✗ Z.AI Proxy is not running (stale PID file)"
        exit 1
      fi
    else
      echo "✗ Z.AI Proxy is not running"
      exit 1
    fi
    ;;

  logs)
    if [ -f "$LOG_FILE" ]; then
      echo "Showing Z.AI Proxy logs (Ctrl+C to exit):"
      echo "=========================================="
      tail -f "$LOG_FILE"
    else
      echo "No log file found at: $LOG_FILE"
      exit 1
    fi
    ;;

  test)
    echo "Testing Z.AI Proxy..."
    echo ""

    # Test models endpoint
    echo "1. Testing /v1/models endpoint..."
    RESPONSE=$(curl -s http://localhost:21435/v1/models 2>&1)
    if echo "$RESPONSE" | jq -e '.data' > /dev/null 2>&1; then
      echo "   ✓ Models endpoint working"
      echo "   Available models:"
      echo "$RESPONSE" | jq -r '.data[].id' | sed 's/^/     - /'
    else
      echo "   ✗ Models endpoint failed"
      echo "   Response: $RESPONSE"
    fi
    echo ""

    # Test chat endpoint
    echo "2. Testing /v1/chat/completions endpoint..."
    CHAT_RESPONSE=$(curl -s http://localhost:21435/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d '{"model":"glm-4.7","messages":[{"role":"user","content":"test"}],"max_tokens":5}' 2>&1)

    if echo "$CHAT_RESPONSE" | jq -e '.choices' > /dev/null 2>&1; then
      echo "   ✓ Chat completions endpoint working"
      CONTENT=$(echo "$CHAT_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)
      echo "   Response: $CONTENT"
    else
      echo "   ✗ Chat completions endpoint failed"
      echo "   Response: $CHAT_RESPONSE"
    fi
    echo ""

    echo "Test complete!"
    ;;

  *)
    echo "Z.AI Proxy Management Script"
    echo ""
    echo "Usage: $0 {start|stop|restart|status|logs|test}"
    echo ""
    echo "Commands:"
    echo "  start   - Start the proxy server"
    echo "  stop    - Stop the proxy server"
    echo "  restart - Restart the proxy server"
    echo "  status  - Show proxy status and recent logs"
    echo "  logs    - Follow proxy logs in real-time"
    echo "  test    - Test proxy endpoints"
    echo ""
    echo "Examples:"
    echo "  $0 start     # Start the proxy"
    echo "  $0 status    # Check if running"
    echo "  $0 logs      # View logs"
    echo "  $0 test      # Test endpoints"
    exit 1
    ;;
esac

exit 0
