FROM python:3.9-alpine

WORKDIR /app

# Cài đặt các dependencies cần thiết
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy mã nguồn
COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]