import json
import urllib.error
import urllib.request

url = "https://fixo-api.vercel.app/api/v1/services/off-ac-deep-clean"
try:
    with urllib.request.urlopen(url, timeout=10) as response:
        status_code = response.status
        body_text = response.read().decode("utf-8")
except urllib.error.HTTPError as err:
    status_code = err.code
    body_text = err.read().decode("utf-8", errors="replace")

assert status_code == 200, f"Expected 200, got {status_code}: {body_text}"
data = json.loads(body_text)
service = data.get('service', data)
assert service.get('id') == 'off-ac-deep-clean', f"Expected off-ac-deep-clean, got {service.get('id')}"
assert 'titleAr' in service, "Expected titleAr in service details"
assert service.get('flatPriceEgp') > 0, "Flat price should be greater than 0 EGP"
print(f"SUCCESS: Service detail for '{service.get('titleAr')}' verified at {service.get('flatPriceEgp')} EGP.")
