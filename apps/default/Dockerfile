############################
# Stage 1: Base Stage
############################
FROM python:3.12-alpine AS base
COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /uvx /bin/

############################
# Stage 2: Builder Stage
############################
FROM base AS builder
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

############################
# Stage 3: Runtime Stage
############################
FROM base AS runtime
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY main.py ./
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

ENV CELERY_APP=main:app
ENV CELERY_LOGLEVEL=info
ENV CELERY_CONCURRENCY=1
ENV CELERY_QUEUES=connection_test__default
ENV CELERY_HOSTNAME=default-worker@%h

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
