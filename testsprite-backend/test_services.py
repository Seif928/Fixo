import json
import urllib.error
import urllib.request

url = "https://fixo-api.vercel.app/api/v1/services?limit=10"
try:
    with urllib.request.urlopen(url, timeout=10) as response:
        status_code = response.status
        body_text = response.read().decode("utf-8")
except urllib.error.HTTPError as err:
    status_code = err.code
    body_text = err.read().decode("utf-8", errors="replace")

assert status_code == 200, f"Expected 200, got {status_code}: {body_text}"
data = json.loads(body_text)
assert 'items' in data, f"Key 'items' not found in response: {list(data.keys())}"
items = data['items']

assert isinstance(items, list), f"Expected list, got {type(items)}"
assert len(items) > 0, "Items list should not be empty"

first_item = items[0]
assert 'titleAr' in first_item, "Service should have titleAr"
assert 'flatPriceEgp' in first_item, "Service should have flatPriceEgp"
assert data.get('meta', {}).get('currency') == 'EGP', "Currency should be EGP"
print(f"SUCCESS: {len(items)} services verified in EGP market.")
