from fastapi import FastAPI, HTTPException
import httpx
import os
import psycopg2

app = FastAPI()
PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL", "http://product:8000")
ORDER_SERVICE_URL = os.getenv("ORDER_SERVICE_URL", "http://order:8000")

DB_CONN = psycopg2.connect(
    host=os.getenv("PG_HOST"),
    user=os.getenv("PG_USERNAME"),
    password=os.getenv("PG_PASSWORD"),
    dbname=os.getenv("PG_DATABASE")
)
DB_CURSOR = DB_CONN.cursor()

DB_CURSOR.execute("""
    CREATE TABLE IF NOT EXISTS inventory (
        id SERIAL PRIMARY KEY,
        product_id INT UNIQUE NOT NULL,
        stock INT NOT NULL
    );
""")
DB_CURSOR.execute("INSERT INTO inventory (product_id, stock) VALUES (1, 50) ON CONFLICT (product_id) DO NOTHING;")
DB_CONN.commit()

@app.post("/inventory/PutInventory")
def update_inventory(product_id: int, stock: int):
    DB_CURSOR.execute("INSERT INTO inventory (product_id, stock) VALUES (%s, %s) ON CONFLICT (product_id) DO UPDATE SET stock = EXCLUDED.stock", (product_id, stock))
    DB_CONN.commit()
    try:
        response = httpx.post(f"{ORDER_SERVICE_URL}/orders", json={"product_id": product_id, "stock": stock})
        response.raise_for_status()
    except httpx.HTTPError:
        raise HTTPException(status_code=500, detail="Failed to notify order service")
    return {"product_id": product_id, "stock": stock}

@app.get("/inventory/GetInventory")
def get_inventory():
    DB_CURSOR.execute("SELECT * FROM inventory")
    inventory = DB_CURSOR.fetchall()
    return [{"id": row[0], "product_id": row[1], "stock": row[2]} for row in inventory]

@app.get("/inventory/health/product")
def check_product_health():
    try:
        response = httpx.get(f"{PRODUCT_SERVICE_URL}/health")
        return response.json()
    except httpx.HTTPError:
        raise HTTPException(status_code=500, detail="Product service unreachable")

@app.get("/inventory/health/order")
def check_order_health():
    try:
        response = httpx.get(f"{ORDER_SERVICE_URL}/health")
        return response.json()
    except httpx.HTTPError:
        raise HTTPException(status_code=500, detail="Order service unreachable")

@app.get("/inventory/health")
def health_check():
    return {"status": "Inventory Service is healthy"}
