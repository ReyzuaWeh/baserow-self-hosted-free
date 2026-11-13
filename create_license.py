import base64  
import json
import hashlib
import os
import subprocess
import sys  
from cryptography.hazmat.primitives import hashes  
from cryptography.hazmat.primitives.asymmetric import padding  
from cryptography.hazmat.primitives.serialization import load_pem_private_key  
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()
instance_id = sys.argv[1] if len(sys.argv) > 1 else None
ISSUED_TO_EMAIL = os.getenv("BASEROW_LICENSE_EMAIL", "reybatos@gmail.com")
ISSUED_TO_NAME = os.getenv("BASEROW_LICENSE_NAME", "reybatos")
if not instance_id:
    cmd = 'docker compose exec baserow ./baserow.sh backend-cmd python -c "import django; django.setup(); from baserow.core.models import Settings; print(Settings.objects.first().instance_id)" | tail -n 1'
    instance_id = subprocess.check_output(cmd, shell=True).decode().strip()

if not instance_id:
    raise ValueError("instance_id tidak ditemukan!")
print(f"instance_id: {instance_id}")
with open('private.pem') as f:
    private_key_pem =  f.read().encode("utf-8")
payload = {
    "version": 1,
    "id": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
    "valid_from": datetime.strptime("2025-11-01", "%Y-%m-%d").isoformat(),
    "valid_through": datetime.strptime("2099-10-31", "%Y-%m-%d").isoformat(),
    "product_code": "enterprise",
    "seats": 5,
    "application_users": 5,
    "issued_on": datetime.now().isoformat(),
    "issued_to_email": ISSUED_TO_EMAIL,
    "issued_to_name": ISSUED_TO_NAME,
    "instance_id": instance_id
}
private_key = load_pem_private_key(private_key_pem, password=None)

json_string = json.dumps(payload, sort_keys=True)


payload_b64 = base64.urlsafe_b64encode(json_string.encode())
pre_hashed = hashlib.sha256(payload_b64).hexdigest().encode()

signature = private_key.sign(
    pre_hashed,
    padding.PSS(
        padding.MGF1(hashes.SHA256()),
        padding.PSS.MAX_LENGTH
    ),
    hashes.SHA256()
)
sig_b64 = base64.urlsafe_b64encode(signature).decode('utf-8')

license_token = f"{payload_b64.decode('utf-8')}.{sig_b64}"

print(license_token)
with open("docs/bas-8/evidence/license_token_5s.txt", "w") as f:
    f.write(license_token)