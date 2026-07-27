#!/usr/bin/env bash
set -e

# Suppress redis-cli command-line password warning
export REDIS_CLI_SERVER_CONFIG_WARN=1

REDIS_HOST=${REDIS_HOST:-"127.0.0.1"}
REDIS_PORT=${REDIS_PORT:-"6379"}
REDIS_USER=${REDIS_USER:-""}
REDIS_PASSWORD=${REDIS_PASSWORD:-""}

CLIENT_TYPE=${1:-""}

CLI_ARGS=("-h" "$REDIS_HOST" "-p" "$REDIS_PORT")

if [ -n "$REDIS_USER" ]; then
    CLI_ARGS+=("--user" "$REDIS_USER")
fi

if [ -n "$REDIS_PASSWORD" ]; then
    CLI_ARGS+=("-a" "$REDIS_PASSWORD")
fi

# Detect execution mechanism
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

echo "--> Querying active connections on $REDIS_HOST:$REDIS_PORT..."

# Fetch raw client list output
if [ -n "$CLIENT_TYPE" ]; then
    RAW_OUTPUT=$("${EXEC_CMD[@]}" CLIENT LIST TYPE "$CLIENT_TYPE" 2>/dev/null)
else
    RAW_OUTPUT=$("${EXEC_CMD[@]}" CLIENT LIST 2>/dev/null)
fi

if [ -z "$RAW_OUTPUT" ]; then
    echo "No active connections found."
    exit 0
fi

# Format output into clean columns including NAME
{
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "ID" "NAME" "ADDR" "AGE(s)" "IDLE(s)" "FLAGS" "CMD" "LIB"
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "--" "----" "----" "------" "-------" "-----" "---" "---"

    echo "$RAW_OUTPUT" | awk '{
    id="-"; name="-"; addr="-"; age="-"; idle="-"; flags="-"; cmd="-"; lib_name=""; lib_ver=""
    for(i=1; i<=NF; i++) {
      split($i, a, "=")
      if (a[1]=="id") id=a[2]
      if (a[1]=="name" && a[2]!="") name=a[2]
      if (a[1]=="addr") addr=a[2]
      if (a[1]=="age") age=a[2]
      if (a[1]=="idle") idle=a[2]
      if (a[1]=="flags") flags=a[2]
      if (a[1]=="cmd") cmd=a[2]
      if (a[1]=="lib-name") lib_name=a[2]
      if (a[1]=="lib-ver") lib_ver=a[2]
    }
    lib = (lib_name != "" ? lib_name "-" lib_ver : "-")
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", id, name, addr, age, idle, flags, cmd, lib
  }'
} | column -t -s $'\t'
