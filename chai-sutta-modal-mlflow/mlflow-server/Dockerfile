FROM python:3.10-slim

WORKDIR /app
RUN pip install --no-cache-dir --upgrade pip
RUN pip install mlflow azure-storage-blob

EXPOSE 5000

CMD mlflow server \
    --host 0.0.0.0 \
    --port 5000 \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root "wasbs://chai-sutta-container@modalstorageacc.blob.core.windows.net/mlflow" \
    --serve-artifacts \
    --cors-allowed-origins "*" \
    --allowed-hosts "*"
