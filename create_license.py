import base64  
import json
import hashlib  
from cryptography.hazmat.primitives import hashes  
from cryptography.hazmat.primitives.asymmetric import padding  
from cryptography.hazmat.primitives.serialization import load_pem_private_key  
from datetime import datetime

with open('private.pem') as f:
    private_key_pem =  f.read().encode("utf-8")
payload = {
    "version": 1,
    "valid_from": datetime.strptime("2026-11-01", "%Y-%m-%d").isoformat(),
    "valid_through": datetime.strptime("2027-10-31", "%Y-%m-%d").isoformat(),
    "product_code": "enterprise",
    "seats": 999999,
    "application_users": 999999,
    "issued_on": datetime.now().isoformat(),
    "issued_to_email": "reybatos@gmail.com",
    "issued_to_name": "reybatos",
    "instance_id": "P03yQ0dnt9cCICtk18B8NPoZVBbsnJn5xiDWx8gbX8M"
}
private_key = load_pem_private_key(private_key_pem, password=None)

json_string = json.dumps(payload, sort_keys=True)


payload_b64 = base64.urlsafe_b64encode(json_string.encode()).rstrip(b"=")
pre_hashed = hashlib.sha256(payload_b64).hexdigest().encode()

signature = private_key.sign(
    pre_hashed,
    padding.PSS(
        padding.MGF1(hashes.SHA256()),
        padding.PSS.MAX_LENGTH
    ),
    hashes.SHA256()
)
sig_b64 = base64.urlsafe_b64encode(signature).rstrip(b"=").decode()

license_token = f"{payload_b64.decode()}.{sig_b64}"

print(license_token)
with open("license_token.txt", "w") as f:
    f.write(license_token)