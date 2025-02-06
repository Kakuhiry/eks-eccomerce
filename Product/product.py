from fastapi import FastAPI, HTTPException
import httpx
import os
import psycopg2

app = FastAPI()
INVENTORY_SERVICE_URL = os.getenv("INVENTORY_SERVICE_URL", "http://inventory:8000")
ORDER_SERVICE_URL = os.getenv("ORDER_SERVICE_URL", "http://order:8000")

DB_CONN = psycopg2.connect(
    host=os.getenv("PG_HOST"),
    user=os.getenv("PG_USERNAME"),
    password=os.getenv("PG_PASSWORD"),
    dbname=os.getenv("PG_DATABASE")
)
DB_CURSOR = DB_CONN.cursor()

DB_CURSOR.execute("""
    CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        price FLOAT NOT NULL
    );
""")
DB_CURSOR.execute("INSERT INTO products (name, price) VALUES ('Laptop', 1000.0) ON CONFLICT DO NOTHING;")
DB_CONN.commit()

@app.get("/product")
def read_root():
    return {"message": "Product Service Running!"}

@app.get("/product/GetProducts")
def get_products():
    DB_CURSOR.execute("SELECT * FROM products")
    products = DB_CURSOR.fetchall()
    return [{"id": row[0], "name": row[1], "price": row[2]} for row in products]

@app.post("/product/PutProducts")
def add_product(name: str, price: float):
    DB_CURSOR.execute("INSERT INTO products (name, price) VALUES (%s, %s) ON CONFLICT DO NOTHING", (name, price))
    DB_CONN.commit()
    return {"name": name, "price": price}

@app.get("/product/health")
def health_check():
    return {"status": "Product Service is healthy"}

@app.get("/product/health/inventory")
def check_inventory_health():
    try:
        response = httpx.get(f"{INVENTORY_SERVICE_URL}/health")
        return response.json()
    except httpx.HTTPError:
        raise HTTPException(status_code=500, detail="Inventory service unreachable")

@app.get("/product/health/order")
def check_order_health():
    try:
        response = httpx.get(f"{ORDER_SERVICE_URL}/health")
        return response.json()
    except httpx.HTTPError:
        raise HTTPException(status_code=500, detail="Order service unreachable")
