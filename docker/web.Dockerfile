# ---- builder ----
FROM python:3.9 AS builder
WORKDIR /app
ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip wheel --wheel-dir /wheels -r requirements.txt

# ---- runtime ----
FROM python:3.9-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
# security: create non-root
RUN useradd -u 10001 -m appuser
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/*
COPY . .
# gunicorn defaults; tweak workers later
ENV PORT=8000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD python -c "import socket; s=socket.socket(); s.connect(('127.0.0.1', ${PORT})); s.close()"
USER appuser
CMD ["sh", "-c", "gunicorn -b 0.0.0.0:${PORT} wsgi:app"]
