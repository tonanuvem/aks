FROM python:3.10-alpine

WORKDIR /app

# Instala dependências para compilar psutil no Alpine
RUN apk add --no-cache gcc musl-dev python3-dev linux-headers

COPY . .
RUN pip install -r requirements.txt

EXPOSE 5000
CMD ["python", "app.py"]
