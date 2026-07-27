#!/usr/bin/env bash
set -e

REDIS_HOST=${REDIS_HOST:-"127.0.0.1"}
REDIS_PORT=${REDIS_PORT:-"6379"}
REDIS_USER=${REDIS_USER:-""}
REDIS_PASSWORD=${REDIS_PASSWORD:-""}

TARGET_TYPE=${1:-"all"}

CLI_ARGS=("-h" "$REDIS_HOST" "-p" "$REDIS_PORT")

if [ -n "$REDIS_USER" ]; then
    CLI_ARGS+=("--user" "$REDIS_USER")
fi

if [ -n "$REDIS_PASSWORD" ]; then
    CLI_ARGS+=("-a" "$REDIS_PASSWORD")
fi

echo "--> Terminating connections (Target: $TARGET_TYPE) on $REDIS_HOST:$REDIS_PORT..."

# Determine best available execution method
if command -v redis-cli &>/dev/null; then
    EXEC_CMD=("redis-cli" "${CLI_ARGS[@]}")

elif [ -n "$REDIS_CONTAINER" ] && docker ps -q -f name="^${REDIS_CONTAINER}$" &>/dev/null; then
    EXEC_CMD=("docker" "exec" "-i" "$REDIS_CONTAINER" "redis-cli" "${CLI_ARGS[@]}")

elif command -v docker &>/dev/null; then
    EXEC_CMD=("docker" "run" "--rm" "-i" "--network=host" "redis:8.4.0-alpine" "redis-cli" "${CLI_ARGS[@]}")

else
    echo "Error: Neither redis-cli nor Docker is available." >&2
    exit 1
fi

if [ "$TARGET_TYPE" = "all" ]; then
    KILLED_COUNT=$("${EXEC_CMD[@]}" CLIENT KILL SKIPME yes 2>/dev/null | tr -d '\r')
else
    KILLED_COUNT=$("${EXEC_CMD[@]}" CLIENT KILL TYPE "$TARGET_TYPE" SKIPME yes 2>/dev/null | tr -d '\r')
fi

echo "--> Success: Terminated $KILLED_COUNT connection(s)."
