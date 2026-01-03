#!/usr/bin/env python3
"""
Z.AI Proxy for IntelliJ IDEA
Rewrites /v1/ paths to /v4/ for Z.AI API compatibility

Usage: python3 zai-proxy.py
"""

from flask import Flask, request, Response
import requests
import sys

app = Flask(__name__)

# Z.AI coding endpoint
ZAI_CODING_BASE = "https://api.z.ai/api/coding/paas"

@app.route('/', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'])
@app.route('/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'])
def proxy(path):
    """Proxy requests to Z.AI, rewriting /v1/ to /v4/"""

    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = Response('')
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, PATCH, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        return response

    # Rewrite /v1/ to /v4/
    original_path = f"/{path}" if path else "/"
    if '/v1/' in original_path:
        rewritten_path = original_path.replace('/v1/', '/v4/')
        print(f"[PROXY] Rewriting path: {original_path} -> {rewritten_path}")
    else:
        rewritten_path = original_path
        print(f"[PROXY] No rewrite needed: {original_path}")

    # Construct target URL
    target_url = f"{ZAI_CODING_BASE}{rewritten_path}"
    print(f"[PROXY] Forwarding to: {target_url}")

    # Forward headers (remove Host header)
    headers = {k: v for k, v in request.headers if k.lower() not in ['host']}

    try:
        # Forward the request
        resp = requests.request(
            method=request.method,
            url=target_url,
            headers=headers,
            data=request.get_data(),
            cookies=request.cookies,
            allow_redirects=False,
            timeout=30
        )

        # Log response
        print(f"[PROXY] Response: {resp.status_code}")

        # Return response with appropriate headers
        excluded_headers = ['content-encoding', 'content-length', 'transfer-encoding', 'connection']
        response_headers = [(k, v) for k, v in resp.headers.items()
                           if k.lower() not in excluded_headers]

        return Response(resp.content, resp.status_code, response_headers)

    except Exception as e:
        print(f"[PROXY] ERROR: {e}", file=sys.stderr)
        return Response(f"Proxy error: {str(e)}", 502, {'Content-Type': 'text/plain'})

if __name__ == '__main__':
    print("=" * 60)
    print("Z.AI Proxy for IntelliJ IDEA")
    print("=" * 60)
    print(f"Proxy listening on: http://localhost:21435")
    print(f"Target endpoint: {ZAI_CODING_BASE}")
    print(f"Path rewriting: /v1/ -> /v4/")
    print("=" * 60)
    print("\nReady to accept requests...")
    print("Press Ctrl+C to stop\n")

    app.run(host='localhost', port=21435, debug=False)
