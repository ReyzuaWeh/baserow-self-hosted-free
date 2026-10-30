# BAS-1: Generate Key Pair and Self Signe
*CODE:DEV-886*

## Overview
Produce the two artifacts the patch needs: a public key to place into the container, and a signed license blob to register. This is self-contained cryptographic work with no Baserow dependency, so it can be built and tested in isolation before any container is touched.

## Why?
1. Why PSS? To create different signature result
2. Why SHA-256? To lock and hide our real data because SHA can't be decrypt

## Steps
1. Get Instance ID

Because we don't create a database container, we can use this command bellow to access our Instance ID
- Command:
```bash
docker compose exec baserow ./baserow.sh backend-cmd shell

# use this after entering python shell
from baserow.core.models import Settings
print(Settings.objects.first().instance_id)
```
- Expected : Got Instance ID
- Evidence : 

![Getting Instance ID](./screenshots/01-get-instance-id.png)

2. 
