import requests

url = "https://fixo-api.vercel.app/api/v1/services?limit=10"
response = requests.get(url, timeout=10)

assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
data = response.json()
assert 'items' in data, f"Key 'items' not found in response: {list(data.keys())}"
items = data['items']

assert isinstance(items, list), f"Expected list, got {type(items)}"
assert len(items) > 0, "Items list should not be empty"

first_item = items[0]
assert 'titleAr' in first_item, "Service should have titleAr"
assert 'flatPriceEgp' in first_item, "Service should have flatPriceEgp"
assert data.get('meta', {}).get('currency') == 'EGP', "Currency should be EGP"
print(f"SUCCESS: {len(items)} services verified in EGP market.")
