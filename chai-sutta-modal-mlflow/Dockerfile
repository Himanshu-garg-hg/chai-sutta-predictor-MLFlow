FROM python:3.9-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install -r requirements.txt
EXPOSE 5000
ARG MODEL_VERSION
ENV MODEL_VERSION=$MODEL_VERSION
CMD ["python", "src/app.py"]