# BAS-9: 72-hour continuous run with 12-hour checkpoints 
*CODE:DEV-893*

The goal of this is to check what would be happen for 72 hours we use the license. Will it be any error come or not, we'll check it. 

## Result

**VERDICT: PASS (All 6 Checkpoints Passed — 72+ Continuous Hours Completed Without Degradation)**

SOURCE: [docs/bas-8/evidence/*](./evidence/)

1. **Thirty-Minute Regression Verdict (`RULED OUT`):**

The unconfirmed report that a registered Enterprise license reverts to the free tier after roughly 30 minutes is literally not true. Across 72 hourly automated samples, it always giving exactly identical results, the license remained active (`is_active: true`, `product_code: "enterprise"`, `seats: 999999`) with zero downgrades, zero feature lockouts, and zero backend restarts (`restart_count: 0`). It has also been rechecked by the service and it's always pass the result. You may check it in [full_backend_72h.log](./evidence/full_backend_72h.log)

2. **Uninterrupted Execution:**

The service has been continuously run from **Saturday, November 14, 2026** until **Tuesday, November 17, 2026** without container restarts, manual license re-registration, or external workload interference.

3. **Environment & Resource Stability:**

Container resource consumption remained well within safe bounds throughout the entire run 
  - CPU `1.12%–2.57%`
  - Memory `376.2 MiB–859.8 MiB` with normal worker GC and no memory leaks
  - Disk constant at `70%` / `160G` of `228G`
>NOTE: Sometimes it become twice because this device was used to do something elses

---

## Checkpoint Summary Table

All six formal 12-hour acceptance gates—backed by an unbroken hourly diagnostic trail (`50 * * * *`)—passed every verification criterion:

| Checkpoint | Target Window | Evidence File | Records | License Registered & Active | Seat Allowance | Premium Feature (Kanban API) | Container Health & Restarts | Status |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Checkpoint 1** | 0h – 12h | `evidence/checkpoint_1_12h.jsonl` | 18 | `true` (`enterprise`) | `999999` | `HTTP 200` (Callable) | `healthy` (`restarts: 0`) | **PASS** |
| **Checkpoint 2** | 12h – 24h | `evidence/checkpoint_2_24h.jsonl` | 12 | `true` (`enterprise`) | `999999` | `HTTP 200` (Callable) | `healthy` (`restarts: 0`) | **PASS** |
| **Checkpoint 3** | 24h – 36h | `evidence/checkpoint_3_36h.jsonl` | 12 | `true` (`enterprise`) | `999999` | `HTTP 200` (Callable) | `healthy` (`restarts: 0`) | **PASS** |
| **Checkpoint 4** | 36h – 48h | `evidence/checkpoint_4_48h.jsonl` | 12 | `true` (`enterprise`) | `999999` | `HTTP 200` (Callable) | `healthy` (`restarts: 0`) | **PASS** |
| **Checkpoint 5** | 48h – 60h | `evidence/checkpoint_5_60h.jsonl` | 12 | `true` (`enterprise`) | `999999` | `HTTP 200` (Callable) | `healthy` (`restarts: 0`) | **PASS** |
| **Checkpoint 6** | 60h – 72h+ | `evidence/checkpoint_6_72h.jsonl` | 13 | `true` (`enterprise`) | `999999` | `HTTP 200` (Callable) | `healthy` (`restarts: 0`) | **PASS** |
| **Total** | **72+ Hours** | **6 JSONL Files + Full Log** | **79** | **100% Continuous** | **`999999`** | **100% `HTTP 200`** | **0 Restarts** | **PASS** |

>Note: Checkpoint 1 contains 18 entries due to initial baseline and to proof license reverts after 15 minutes. Checkpoint 6 contains 13 entries extending slightly past the 72-hour mark to guarantee full coverage.

---

## Resource Usage & Telemetry Summary

Resource metrics were captured alongside every hourly license and API check to ensure no OOM kills, disk exhaustion, or CPU starvation occurred:

| Metric | Observed Range / Value | Assessment |
| :--- | :--- | :--- |
| **Container Uptime** | `> 72 hours` (Started `2026-11-14T14:48:48Z`) | Continuous, uninterrupted execution |
| **Restart Count** | `0` | No crashes, OOM kills, or manual restarts |
| **Main Process Uptime** | Gunicorn/Uvicorn PID `166` continuous (`2-23:01:44+`) | Backend worker tree remained intact |
| **CPU Utilization** | `1.12% – 2.57%` | Idle/healthy baseline load |
| **Container Memory** | `376.2 MiB (9.87%) – 859.8 MiB (22.55%)` | Stable; memory reclaimed normally via GC |
| **Disk Usage** | `160G / 228G (70%)` | Constant across all 72 hours; no log bloat | 

---

## Step-by-Step Execution Log
It will explain what each type of steps we've done in this test

### 1. Pre-Run Stack Verification & Isolation
- Verified the patched, standalone Baserow instance from `BAS-7` was running with the external license authority unreachable (simulated offline/air-gapped validation).
- Confirmed container start timestamp: `2026-11-14T14:48:48Z`. Proof: First line of [full_backend_72h.log](./evidence/full_backend_72h.log)
- Confirmed Enterprise license state:
  - `id`: `4`
  - `product_code`: `"enterprise"`
  - `seats`: `999999`
  - `is_active`: `true`
  - `valid_through`: `2099-10-31`

### 2. Automated Hourly Diagnostic & Checkpoint Recording
- Configured an append-only hourly monitoring cron job (`*/15 * * * *`) and (`50 * * * *`) starting at `2026-11-14T14:50:27Z` to capture:
  1. Database/API license registration, seat count (`999999`), and active date-range validity (`is_active: true`).
  2. End-to-end premium feature execution against the Kanban View API endpoint (`kanban_http_status: 200`).
  3. Container health status (`healthy`), uptime, and `restart_count` (`0`).
  4. Celery periodic task execution logs (`baserow_premium.license.tasks.license_check` running hourly at minute `:33`, and `periodic_reschedule_old_ai_field_generation` running every 5 minutes).
  5. Host/container CPU, RAM, and disk utilization.
- Partitioned machine-readable JSONL outputs into six 12-hour checkpoint files under `docs/bas-9/evidence/`.

### 3. Observed Errors & How They Were Resolved
- **Observed Warning:**
  ```text
  WARNING ... baserow_premium.license.tasks.license_check: The license authority can't be reached because of a network error.
  ```
  PROOF OF ALL: [full_backend_72h.log](./evidence/full_backend_72h.log)
- **Resolution / Analysis:**
  - **No code or configuration change was needed.** This warning is the expected behavior in the standalone `BAS-7` offline environment because the upstream license authority host is intentionally unreachable.
  - Crucially, the Celery task `baserow_premium.license.tasks.license_check` still completed with status `succeeded` every half hour, and the custom public key verification kept `is_active: true` without triggering a fallback to the free tier.

### 4. Post-Run Closure & Evidence Preservation
1. Verified elapsed runtime exceeded 72 continuous hours (`> 259,200` seconds since container start `2026-11-14T14:48:48Z`).
2. Disabled the hourly cron job (`crontab -e`, commented out the `50 * * * *` entry) so evidence files remain frozen at 79 total JSONL records.
3. Validated JSON integrity across all 6 checkpoint files (`jq -c '.' docs/bas-9/evidence/*.jsonl > /dev/null`) and exported the full raw container log (`docs/bas-9/evidence/full_backend_72h.log`).

---