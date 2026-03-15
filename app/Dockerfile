FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose application port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1

# Run as non-root user
RUN useradd -m appuser
USER appuser

# Start the application
ENV ENVIRONMENT=PROD \
    HOST=0.0.0.0 \
    PORT=8000 \
    REDIS_PORT=6379 \
    REDIS_DB=0

CMD ["python", "hello.py"]
