# ecommerce-database
# 🛒 E-commerce Database Schema (MySQL)

This repository contains a **relational database schema** for an **E-commerce Store**, designed in MySQL.  
It models core entities such as customers, products, orders, inventory, payments, reviews, and more.

---

## 📂 Contents
- `ecommerce_schema.sql` → SQL script to create the full database schema.
- `README.md` → Documentation for usage and schema overview.

---

## 🎯 Features
- **Well-structured tables** with:
  - `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE` constraints
  - `CHECK` constraints (where supported)
- **Relationships**:
  - One-to-One (e.g., customer ↔ wishlist)
  - One-to-Many (e.g., customer → orders, product → reviews)
  - Many-to-Many (e.g., products ↔ categories, products ↔ tags, orders ↔ products)
- **Stored procedure** example for product + inventory creation.
- **View** example (`v_orders_summary`) for quick reporting.

---

## 📊 Main Tables
| Table              | Description |
|--------------------|-------------|
| `customers`        | Stores customer accounts & roles |
| `addresses`        | Billing and shipping addresses |
| `suppliers`        | Product suppliers |
| `categories`       | Product categories (supports hierarchy) |
| `products`         | Store products with supplier, price, and details |
| `inventory`        | Tracks stock per product |
| `orders`           | Customer orders with billing, shipping, totals |
| `order_items`      | Line items (products within an order) |
| `payments`         | Payment details for orders |
| `product_reviews`  | Customer product feedback |
| `wishlists`        | Wishlist per customer |

---


