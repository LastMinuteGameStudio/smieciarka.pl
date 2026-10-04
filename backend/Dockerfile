FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /srv

# Dependencies first: this layer is cached until requirements.txt changes,
# so editing app code rebuilds in seconds instead of reinstalling torch-sized
# wheels (fastembed pulls onnxruntime) every time.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY alembic.ini ./
COPY migrations ./migrations
COPY app ./app

# fastembed caches downloaded models under HOME; give it a writable one.
RUN useradd --create-home --uid 10001 app
ENV HOME=/home/app
USER app

EXPOSE 8000

# --host 0.0.0.0 is required: the container's loopback is not reachable from
# the host, so the default 127.0.0.1 bind would publish a dead port.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
