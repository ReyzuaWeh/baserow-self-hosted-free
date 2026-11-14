#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && . .env

EVIDENCE_DIR="$SCRIPT_DIR/docs/bas-9/evidence"
mkdir -p "$EVIDENCE_DIR"

NOW_EPOCH=$(date +%s)
NOW_ISO=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

START_FILE="$EVIDENCE_DIR/.start_epoch"
STATE_FILE="$EVIDENCE_DIR/.last_check_epoch"

[ ! -f "$START_FILE" ] && echo "$NOW_EPOCH" > "$START_FILE"
START_EPOCH=$(cat "$START_FILE")

INTERVAL_SEC=0
[ -f "$STATE_FILE" ] && INTERVAL_SEC=$((NOW_EPOCH - $(cat "$STATE_FILE")))
echo "$NOW_EPOCH" > "$STATE_FILE"

ELAPSED_SEC=$((NOW_EPOCH - START_EPOCH))
BLOCK_NUM=$(( (ELAPSED_SEC / 43200) + 1 ))
[ "$BLOCK_NUM" -gt 6 ] && BLOCK_NUM=6
TARGET_HOUR=$((BLOCK_NUM * 12))

LOG_FILE="$EVIDENCE_DIR/checkpoint_${BLOCK_NUM}_${TARGET_HOUR}h.log"
JSONL_FILE="$EVIDENCE_DIR/checkpoint_${BLOCK_NUM}_${TARGET_HOUR}h.jsonl"

# 1-3. License Status Check 
JWT_ACCESS=$(curl -s -X POST http://localhost/api/user/token-auth/ \
    -H "Content-Type: application/json" \
    -d '{"email": "'$BASEROW_LICENSE_EMAIL'", "password": "'$BASEROW_LICENSE_PASSWORD'"}' | jq -r '.access_token')

LIC_JSON=$(curl -s http://localhost/api/licenses/ \
    -H "Authorization: JWT $JWT_ACCESS" | \
    jq -c '.[0] // {id: null, seats: 0, is_active: false} | {id, seats, is_active, valid_from, valid_through, last_check, product_code}')

# 4. Premium View Check (Kanban API end-to-end)
TABLE_ID=$(curl -s http://localhost/api/applications/ \
  -H "Authorization: JWT $JWT_ACCESS" | jq -r '[.[].tables[]?][0].id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://localhost/api/database/views/table/$TABLE_ID/" \
  -H "Authorization: JWT $JWT_ACCESS" \
  -H "Content-Type: application/json" \
  -d '{"name": "soak-check-kanban", "type": "kanban"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
VIEW_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id')
[ "$HTTP_CODE" = "200" ] && curl -s -o /dev/null -X DELETE "http://localhost/api/database/views/$VIEW_ID/" -H "Authorization: JWT $JWT_ACCESS"

# 5. Container Health, Uptime & Backend PID
HEALTH_INFO=$(docker inspect --format='health={{.State.Health.Status}} | started_at={{.State.StartedAt}} | restart_count={{.RestartCount}}' $(docker compose ps -q baserow))
GUNICORN_INFO=$(docker compose exec -T baserow ps -eo pid,etime,args | grep "[g]unicorn.*baserow" | head -n 1 | xargs)

# 6. License-related backend logs since last check
SINCE_ARG="${INTERVAL_SEC}s"
[ "$INTERVAL_SEC" -eq 0 ] && SINCE_ARG="1h"
LIC_LOGS=$(docker compose logs --since "$SINCE_ARG" baserow 2>&1 | grep -iE "license|premium|baserow\.io|invalid|expired" || echo "no_license_log_lines")

# 7. Resource Usage
CONTAINER_RES=$(docker compose stats --no-stream --format "cpu={{.CPUPerc}} | mem={{.MemUsage}} ({{.MemPerc}})" baserow)
DISK_RES=$(df -h . | awk 'NR==2 {print "disk_used=" $3 "/" $2 " (" $5 ")"}')
HOST_RAM=$(free -h | awk '/^Mem:/ {print "host_ram=" $3 "/" $2}')

# Output ke Append-only Log & Machine-readable JSONL di docs/bas-9/evidence/
{
  echo "=== [$NOW_ISO] interval_sec=$INTERVAL_SEC ==="
  echo "License: $LIC_JSON"
  echo "Kanban API HTTP: $HTTP_CODE | View ID: $VIEW_ID"
  echo "Container: $HEALTH_INFO | Gunicorn: $GUNICORN_INFO"
  echo "Resources: $CONTAINER_RES | $DISK_RES | $HOST_RAM"
  echo "License Logs: $LIC_LOGS"
} >> "$LOG_FILE"

jq -n -c \
  --arg ts "$NOW_ISO" \
  --argjson interval "$INTERVAL_SEC" \
  --argjson lic "$LIC_JSON" \
  --arg kanban_http "$HTTP_CODE" \
  --arg health "$HEALTH_INFO" \
  --arg gunicorn "$GUNICORN_INFO" \
  --arg res "$CONTAINER_RES | $DISK_RES | $HOST_RAM" \
  --arg logs "$LIC_LOGS" \
  '{timestamp: $ts, interval_sec: $interval, license: $lic, kanban_http_status: $kanban_http, container: $health, backend_proc: $gunicorn, resources: $res, license_logs: $logs}' >> "$JSONL_FILE"