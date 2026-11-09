import requests

url = "https://fixo-api.vercel.app/api/v1/services/off-ac-deep-clean"
response = requests.get(url, timeout=10)

assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
data = response.json()
service = data.get('service', data)
assert service.get('id') == 'off-ac-deep-clean', f"Expected off-ac-deep-clean, got {service.get('id')}"
assert 'titleAr' in service, "Expected titleAr in service details"
assert service.get('flatPriceEgp') > 0, "Flat price should be greater than 0 EGP"
print(f"SUCCESS: Service detail for '{service.get('titleAr')}' verified at {service.get('flatPriceEgp')} EGP.")
