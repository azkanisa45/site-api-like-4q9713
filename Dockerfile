FROM python:3.10-slim

RUN useradd -m -u 1000 user
USER user

WORKDIR /app

COPY --chown=user:user . .

RUN pip install --no-cache-dir -r requirements.txt || pip install flask gunicorn

# Railway menyediakan PORT env var; Gunicorn bind ke 0.0.0.0
CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 2 --threads 4 --timeout 120
