#!/usr/bin/env bash
set -e

LOG_FILE="docs/bas-6/evidence/upgrade-execution.txt"

START_TIME=$(date +%s)
echo "Downtime start: $(date -u -d @"$START_TIME" '+%Y-%m-%d %H:%M:%S UTC')"

# Restart container
docker compose down
docker compose up -d

echo "Waiting for Baserow service to respond on http://localhost:80 ..."

until [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/api/health/)" -eq 200 ] || [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/)" -eq 200 ] || [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/)" -eq 302 ]; do
    sleep 2
done

END_TIME=$(date +%s)
TOTAL_DOWNTIME=$((END_TIME - START_TIME))

echo "Downtime end: $(date -u -d @"$END_TIME" '+%Y-%m-%d %H:%M:%S UTC')"
echo "Total Downtime: ${TOTAL_DOWNTIME} seconds"

cat <<EOF >> "$LOG_FILE"

### Downtime Measurement
- **Downtime Start:** $(date -u -d @"$START_TIME" '+%Y-%m-%d %H:%M:%S UTC')
- **Downtime End:** $(date -u -d @"$END_TIME" '+%Y-%m-%d %H:%M:%S UTC')
- **Total Downtime:** ${TOTAL_DOWNTIME} seconds ($((TOTAL_DOWNTIME / 60))m $((TOTAL_DOWNTIME % 60))s)
EOF