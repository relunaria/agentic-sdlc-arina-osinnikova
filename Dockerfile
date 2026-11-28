FROM python:3.12-slim

WORKDIR /app

# Dependencies first (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Source and tests
COPY src/ src/
COPY tests/ tests/

ENV PYTHONPATH=/app/src

CMD ["pytest", "tests/", "-v", "--tb=short"]
