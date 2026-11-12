import json
import urllib.error
import urllib.request

url = "https://fixo-api.vercel.app/api/v1/health"
try:
    with urllib.request.urlopen(url, timeout=10) as response:
        status_code = response.status
        body_text = response.read().decode("utf-8")
except urllib.error.HTTPError as err:
    status_code = err.code
    body_text = err.read().decode("utf-8", errors="replace")

assert status_code == 200, f"Expected 200, got {status_code}: {body_text}"
data = json.loads(body_text)
assert data.get('status') == 'ok', f"Expected status 'ok', got {data.get('status')}"
print("SUCCESS: FIXO API health check passed, backend is online and healthy.")
