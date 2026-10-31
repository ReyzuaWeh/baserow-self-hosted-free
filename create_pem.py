from cryptography.hazmat.primitives.asymmetric import rsa  
from cryptography.hazmat.primitives import serialization

private_key = rsa.generate_private_key(  
    public_exponent=65537,  
    key_size=2048,  
)  
public_key = private_key.public_key()  

private_pem = private_key.private_bytes(  
    encoding=serialization.Encoding.PEM,  
    format=serialization.PrivateFormat.PKCS8,  
    encryption_algorithm=serialization.NoEncryption()  
)  
private_decode = private_pem.decode()
print("=== PRIVATE KEY ===")  
print(private_decode)  

public_pem = public_key.public_bytes(  
    encoding=serialization.Encoding.PEM,  
    format=serialization.PublicFormat.SubjectPublicKeyInfo,  
)  
public_decode = public_pem.decode()

print("=== PUBLIC KEY ===")  
print(public_decode)


with open("private.pem","w") as f:
  f.write(private_decode)

with open("public.pem", "w") as f:
    f.write(public_decode)