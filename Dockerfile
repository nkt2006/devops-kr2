FROM python:3.12-slim@sha256:cb33f7f771ecec2ef1225cf39b159591a040391bd73e4c01f00fdfc4c47611d2

RUN useradd --system --no-create-home app
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

USER app
EXPOSE 8001
CMD ["gunicorn", "--bind", "0.0.0.0:8001", "--access-logfile", "-", "app:app"]
