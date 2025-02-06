# Inventory Service Health Check (checks the health of Product and Order Services)
curl http://localhost:8000/inventory/health

# Product Service Health Check (checks the health of Inventory and Order Services)
curl http://localhost:8001/product/health

# Order Service Health Check (checks the health of Product and Inventory Services)
curl http://localhost:8002/order/health

# Product Service - Add a new product (POST request to add a product)
curl -X 'POST' \
  'http://localhost:8001/products/PutProducts' \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "Smartphone",
  "price": 500.0
}'

# Product Service - Get list of products (GET request to fetch all products)
curl http://localhost:8001/product/GetProducts

# Inventory Service - Get inventory (GET request to fetch all inventory)
curl http://localhost:8000/inventory/GetInventory

# Inventory Service - Update inventory (POST request to update stock for a product)
curl -X 'POST' \
  'http://localhost:8000/inventory/PutInventory' \
  -H 'Content-Type: application/json' \
  -d '{
  "product_id": 1,
  "stock": 100
}'

# Order Service - Create a new order (POST request to create an order)
curl -X 'POST' \
  'http://localhost:8002/order/PutOrder' \
  -H 'Content-Type: application/json' \
  -d '{
  "product_id": 1,
  "quantity": 2
}'

# Order Service - Get list of orders (GET request to fetch all orders)
curl http://localhost:8002/order/GetOrders


# Inventory Service - Check the health of Product Service
curl http://localhost:8000/inventory/health/product

# Inventory Service - Check the health of Order Service
curl http://localhost:8000/inventory/health/order

# Product Service - Check the health of Inventory Service
curl http://localhost:8001/product/health/inventory

# Product Service - Check the health of Order Service
curl http://localhost:8001/product/health/order

# Order Service - Check the health of Product Service
curl http://localhost:8002/order/health/product

# Order Service - Check the health of Inventory Service
curl http://localhost:8002/order/health/inventory
