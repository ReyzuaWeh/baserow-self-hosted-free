#!/usr/bin/env bash
set -e
docker compose down
. venv/bin/activate
echo "Regenerating key..."
sudo python create_pem.py

echo "Recreating Instance..."
docker compose up -d

echo "Waiting for Baserow to be fully ready..."
until [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/)" -eq 200 ] || [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/)" -eq 302 ]; do
    sleep 2
done

echo "Checking Key Result..."
chmod +x ./pemcheck.sh
./pemcheck.sh

echo "Re-registering / Validating License..."
python create_license.py