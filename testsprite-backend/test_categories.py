import requests

url = "https://fixo-api.vercel.app/api/v1/services/categories"
response = requests.get(url, timeout=10)

assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
data = response.json()
assert 'categories' in data, f"Key 'categories' not found in response: {list(data.keys())}"
categories = data['categories']

assert isinstance(categories, list), f"Expected list, got {type(categories)}"
assert len(categories) == 21, f"Expected 21 categories, got {len(categories)}"

assert 'zones' in data, "Key 'zones' not found in response"
assert data.get('meta', {}).get('currency') == 'EGP', "Currency should be EGP"
print("SUCCESS: 21 categories verified in EGP market.")
