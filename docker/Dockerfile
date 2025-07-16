FROM n8nio/n8n

# ติดตั้ง Python และ pip
RUN apk add --no-cache python3 py3-pip

# คัดลอกไฟล์ requirements.txt เข้า container
COPY requirements.txt /tmp/requirements.txt

# ติดตั้ง Python packages จาก requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
