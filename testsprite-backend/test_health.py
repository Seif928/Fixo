import requests

url = "https://fixo-api.vercel.app/api/v1/health"
response = requests.get(url, timeout=10)

assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
data = response.json()
assert data.get('status') == 'ok', f"Expected status 'ok', got {data.get('status')}"
print("SUCCESS: FIXO API health check passed, backend is online and healthy.")
