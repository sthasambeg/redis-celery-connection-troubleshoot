#!/bin/sh
set -e

# Replaces PID 1 with Celery process
exec celery -A ${CELERY_APP} worker \
    --loglevel=${CELERY_LOGLEVEL} \
    --concurrency=${CELERY_CONCURRENCY} \
    -Q ${CELERY_QUEUES} \
    -E -n ${CELERY_HOSTNAME}
