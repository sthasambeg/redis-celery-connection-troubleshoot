import logging
import os
from dataclasses import dataclass

import celery
from celery.signals import task_failure
from kombu import Exchange, Queue

logger = logging.getLogger(__name__)


TIME_ZONE = "America/Toronto"


try:
    BROKER_URL = os.environ["BROKER_URL"]
except KeyError as e:
    raise RuntimeError("BROKER_URL environment variable is missing!") from e


@dataclass(frozen=True, slots=True)
class Exchanges:
    DEFAULT = "crm-exchange"


default_exchange = Exchange(Exchanges.DEFAULT, type="direct")


@dataclass(frozen=True, slots=True)
class Queues:
    DEFAULT = "connection_test__default"


CELERY_QUEUES = (
    Queue(
        Queues.DEFAULT,
        default_exchange,
        routing_key=Queues.DEFAULT,
        queue_arguments={"x-max-priority": 10},
    ),
)


app = celery.Celery("app.core", broker=BROKER_URL)
app.autodiscover_tasks()

# Config updated with lowercase settings
app.conf.update(
    task_queues=CELERY_QUEUES,
    task_default_queue=Queues.DEFAULT,
    timezone=TIME_ZONE,
    # Fix Redis idle drop issue
    broker_transport_options={
        "socket_keepalive": True,  # Enable OS TCP keepalives
        "socket_timeout": 30,  # Read/write socket timeout (seconds)
        "socket_connect_timeout": 30,  # Initial connection timeout (seconds)
        "retry_on_timeout": True,  # Automatically retry on socket timeout
    },
    broker_connection_retry_on_startup=True,  # Prevent worker crash if Redis is starting up
)


@task_failure.connect
def celery_task_failure_email(task_id, sender, exception, einfo, *args, **kwargs):  # noqa: ANN001, ANN002, ANN003
    logger.info("Celery task failure occurred.")
    logger.info(f"{task_id=} {sender=} {exception=} {einfo=} *{args=} **{kwargs=}")


if __name__ == "__main__":
    app.start()
