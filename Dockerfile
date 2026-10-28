ARG PYTHON_IMAGE=python:3.14-slim@sha256:0514bc76712d64f8bb48adcb95b1ab0d88c69fee95d62fe4c18ee948bee9b1e1
FROM ${PYTHON_IMAGE} AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /srv
COPY requirements.lock .
RUN pip install --no-cache-dir -r requirements.lock

FROM base AS test
COPY requirements-test.lock .
RUN pip install --no-cache-dir -r requirements-test.lock
COPY app ./app
COPY tests ./tests
CMD ["python", "-m", "pytest", "-q", "-p", "no:cacheprovider"]

FROM base AS runtime
ARG APP_VERSION=1.0.1
ARG SOURCE_COMMIT=local
ENV APP_VERSION=${APP_VERSION} SOURCE_COMMIT=${SOURCE_COMMIT}
LABEL org.opencontainers.image.revision=${SOURCE_COMMIT}
RUN groupadd --gid 10001 appuser && useradd --uid 10001 --gid 10001 --no-create-home appuser
COPY --chown=10001:10001 app ./app
COPY --chown=10001:10001 wsgi.py .
USER 10001:10001
EXPOSE 8080
CMD ["gunicorn", "--bind=0.0.0.0:8080", "--workers=1", "--threads=4", "--worker-tmp-dir=/tmp", "--access-logfile=-", "--error-logfile=-", "wsgi:app"]
