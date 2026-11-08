#!/usr/bin/env bash
HOST_HASH=$(sha256sum ./public.pem | awk '{print $1}')
CONTAINER_HASH=$(docker compose exec baserow sha256sum /baserow/premium/backend/src/baserow_premium/public_key.pem | awk '{print $1}')

echo "Host Key SHA256      : $HOST_HASH"
echo "Container Key SHA256 : $CONTAINER_HASH"

if [ "$HOST_HASH" = "$CONTAINER_HASH" ]; then
    echo "VERDICT: MATCH — Baserow startup did not overwrite the mounted key."
else
    echo "VERDICT: MISMATCH — Key was overwritten or not mounted correctly!"
fi