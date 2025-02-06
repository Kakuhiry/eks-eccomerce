FROM python:3.9

WORKDIR /app
COPY inventory.py requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000
CMD ["uvicorn", "inventory:app", "--host", "0.0.0.0", "--port", "8000"]
