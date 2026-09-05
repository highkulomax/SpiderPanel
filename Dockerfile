# Multi-stage build for SpiderPanel with Xray-core
FROM python:3.13-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download latest stable Xray-core release
RUN mkdir -p /app/xray && \
    XRAY_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    if [ -z "$XRAY_VERSION" ]; then XRAY_VERSION="v25.1.1"; fi && \
    curl -L -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip" && \
    unzip /tmp/xray.zip -d /app/xray && \
    rm /tmp/xray.zip

FROM python:3.13-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --from=builder /app/xray /app/xray
COPY . .

RUN chmod +x /app/xray/xray /app/start.sh /app/run.sh 2>/dev/null || true

ENV PORT=8080
EXPOSE $PORT

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || false

CMD ["python", "main.py"]
