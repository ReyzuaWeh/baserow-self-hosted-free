import base64
import json
import hashlib  
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric import padding  
from cryptography.hazmat.primitives import hashes, serialization  
from cryptography.hazmat.primitives.asymmetric.types import PublicKeyTypes

with open("public.pem", "rb") as f:
    public_key = serialization.load_pem_public_key(f.read())

with open("license_token.txt", "r") as f:
    license_token = f.read()

def verify_token(token:bytes, public_key_obj:PublicKeyTypes|None = None) -> str:
    payload_b64, sig_b64 = token.split(".")
    sig_bytes = base64.urlsafe_b64decode(sig_b64)
    # payload in signature is the base64 encoded payload, not the original json string
    hex_msg = hashlib.sha256(payload_b64.encode()).hexdigest().encode()

    if public_key_obj is None:
        public_key_obj = public_key

    try:
        # The standard RSA (PKCS1v15) will be rejected because the signature was generated using PSS padding, so we need to use the same padding scheme for verification.
        public_key_obj.verify(
            sig_bytes, hex_msg,
            padding.PSS(padding.MGF1(hashes.SHA256()), padding.PSS.MAX_LENGTH),
            hashes.SHA256()
        )
        
        payload_bytes = base64.urlsafe_b64decode(payload_b64)
        payload_data = json.loads(payload_bytes)
        
        return f"SUCCESS: Valid License. Seats: {payload_data.get('seats')}, Application Users: {payload_data.get('application_users')}"
    except InvalidSignature:
        return "FAILED: License Rejected (Tampered)"

if __name__ == "__main__":
    print("Original Test:", verify_token(license_token, public_key))
    tampered_token = "A" + license_token[1:] 
    print("Manipulated Test:", verify_token(tampered_token, public_key))