import json
import urllib.error
import urllib.request

url = "https://fixo-api.vercel.app/api/v1/services/categories"
try:
    with urllib.request.urlopen(url, timeout=10) as response:
        status_code = response.status
        body_text = response.read().decode("utf-8")
except urllib.error.HTTPError as err:
    status_code = err.code
    body_text = err.read().decode("utf-8", errors="replace")

assert status_code == 200, f"Expected 200, got {status_code}: {body_text}"
data = json.loads(body_text)
assert 'categories' in data, f"Key 'categories' not found in response: {list(data.keys())}"
categories = data['categories']

assert isinstance(categories, list), f"Expected list, got {type(categories)}"
assert len(categories) == 21, f"Expected 21 categories, got {len(categories)}"

assert 'zones' in data, "Key 'zones' not found in response"
assert data.get('meta', {}).get('currency') == 'EGP', "Currency should be EGP"
print("SUCCESS: 21 categories verified in EGP market.")
