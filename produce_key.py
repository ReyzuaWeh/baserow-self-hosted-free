import base64, json, time, hashlib
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

def b64u(b): return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

priv = serialization.load_pem_private_key(open("private.pem","rb").read(), password=None)

payload = {
    "version": 1,
    "valid_from": "2026-11-01",
    "valid_through": "2027-10-31",
    "product_code": "enterprise",
    "seats": 999999,
    "aplication_users": 999999,
    "issued_on": int(time.time()),
    "issued_to_emai": "reybatos@gmail.com",
    "issued_to_name": "reybatos",
    "instance_id": "P03yQ0dnt9cCICtk18B8NPoZVBbsnJn5xiDWx8gbX8M"
}
payload_b64 = b64u(json.dumps(payload, sort_keys=True).encode())

hex_msg = hashlib.sha256(payload_b64.encode()).hexdigest().encode()

sig = priv.sign(
    hex_msg,
    padding.PSS(
        mgf=padding.MGF1(hashes.SHA256()),
        salt_length=padding.PSS.MAX_LENGTH
    ),
    hashes.SHA256()
)

license_token = f"{payload_b64}.{b64u(sig)}"
print(license_token)