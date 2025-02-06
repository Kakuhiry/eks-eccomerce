from fastapi import FastAPI, HTTPException
import os
import psycopg2
import httpx

app = FastAPI()
PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL", "http://product:8000")
INVENTORY_SERVICE_URL = os.getenv("INVENTORY_SERVICE_URL", "http://inventory:8000")


DB_CONN = psycopg2.connect(
    host=os.getenv("PG_HOST"),
    user=os.getenv("PG_USERNAME"),
    password=os.getenv("PG_PASSWORD"),
    dbname=os.getenv("PG_DATABASE")
)
DB_CURSOR = DB_CONN.cursor()

DB_CURSOR.execute("""
    CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        product_id INT NOT NULL,
        quantity INT NOT NULL
    );
""")
DB_CURSOR.execute("INSERT INTO orders (product_id, quantity) VALUES (1, 2) ON CONFLICT DO NOTHING;")
DB_CONN.commit()

@app.post("/order/PutOrders")
def create_order(product_id: int, quantity: int):
    DB_CURSOR.execute("INSERT INTO orders (product_id, quantity) VALUES (%s, %s) ON CONFLICT DO NOTHING", (product_id, quantity))
    DB_CONN.commit()
    return {"product_id": product_id, "quantity": quantity}

@app.get("/order/GetOrders")
def get_orders():
    DB_CURSOR.execute("SELECT * FROM orders")
    orders = DB_CURSOR.fetchall()
    return [{"id": row[0], "product_id": row[1], "quantity": row[2]} for row in orders]

@app.get("/order/health/product")
def check_product_health():
    try:
        response = httpx.get(f"{PRODUCT_SERVICE_URL}/health")
        return response.json()
    except httpx.HTTPError:
        raise HTTPException(status_code=500, detail="Product service unreachable")

@app.get("/order/health/inventory")
def check_inventory_health():
    try:
        response = httpx.get(f"{INVENTORY_SERVICE_URL}/health")
        return response.json()
    except httpx.HTTPError:
        raise HTTPException(status_code=500, detail="Inventory service unreachable")

@app.get("/order/health")
def health_check():
    return {"status": "Order Service is healthy"}
