# Redis Celery Connection Tester

This setup tests Celery worker socket timeouts and connection resilience under simulated network failures using Traffic Control (`tc`).

---

## Quick Start

### 1. Start Services

```bash
# Start Redis dependencies
docker compose -f compose.deps.yml up -d

# Build and start Celery workers
docker compose up --build -d

```

### 2. View Worker Logs

```bash
docker logs -f rct-settings

```

---

## Simulating Network Drops

Use `toggle_drop.sh` to simulate a dropped socket on any worker container (`rct-default`, `rct-settings`, `rct-package`).

### Commands

- **Enable Packet Loss (Simulate Drop):**

```bash
./toggle_drop.sh rct-settings on

```

- **Restore Network:**

```bash
./toggle_drop.sh rct-settings off

```

- **Check Status:**

```bash
./toggle_drop.sh rct-settings status

```

---

## Cleanup

```bash
docker compose -f compose.deps.yml -f compose.yml down -v

```
