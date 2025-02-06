FROM python:3.9

WORKDIR /app
COPY product.py requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000
CMD ["uvicorn", "product:app", "--host", "0.0.0.0", "--port", "8000"]
