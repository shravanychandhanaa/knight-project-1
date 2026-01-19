FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN useradd --create-home --shell /bin/bash appuser || true

WORKDIR /app

COPY requirements.txt /app/
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential gcc libpq-dev curl \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get remove -y build-essential gcc \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY app.py /app/

EXPOSE 80

USER appuser

CMD ["gunicorn", "--bind", "0.0.0.0:80", "app:app"]
