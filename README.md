# Redis Celery Connection Tester

This setup tests Celery worker socket timeouts, heartbeats, and connection resilience under two distinct failure scenarios using Traffic Control (`tc`) and Redis Client Termination.

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

### 3. Inspect Active Redis Connections

```bash
export $(grep -v '^#' .env | xargs)
./list_connections.sh

```

> [!Note]
> Scripts automatically detect whether to use local `redis-cli`, a local Docker container (`REDIS_CONTAINER`), or a temporary `redis:8.4.0-alpine` fallback container.

---

## Connection Inspection & Verification Pipeline

Run the end-to-end connection termination and reconnect verification test:

```bash
./list_connections.sh && \
echo "Connections before kill: $(($(./list_connections.sh | wc -l) - 4))" && \
printf "\n" && \
./kill_connections.sh && \
echo "Connections after kill: $(($(./list_connections.sh | wc -l) - 4))" && \
printf "\nSleeping 5 seconds...\n\n" && \
sleep 5 && \
echo "Connections after sleep: $(($(./list_connections.sh | wc -l) - 4))"
```

This pipeline displays active client connections, forcefully terminates them, verifies dropped sockets, and confirms Celery worker automatic reconnects after 5 seconds.

---

## Failure Testing Strategies

### Strategy 1: Simulate Unannounced Network Drops (`toggle_drop.sh`)

Simulates a silent network drop (e.g., intermediate firewall dropping idle sockets, cloud network split). Packets are dropped silently without sending a `FIN`/`RST`, triggering a **`redis.exceptions.TimeoutError`**.

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

### Strategy 2: Simulate Server-Closed Connections (`kill_connections.sh`)

Simulates Redis actively closing idle connections or restarting. Redis sends a TCP `FIN` packet to the client, triggering a **`redis.exceptions.ConnectionError: Connection closed by server`**.

- **Kill All Connections (Workers + PubSub Listeners):**

```bash
export $(grep -v '^#' .env | xargs)
./kill_connections.sh all

```

- **Kill Specific Connection Types (`normal` or `pubsub`):**

```bash
export $(grep -v '^#' .env | xargs)
./kill_connections.sh pubsub

```

---

## Cleanup

```bash
docker compose -f compose.deps.yml -f compose.yml down -v

```
