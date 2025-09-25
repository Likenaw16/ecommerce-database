-- ecommerce_schema.sql
-- E-commerce store relational schema (MySQL / InnoDB)
-- Creates database, tables, PKs, FKs, constraints, and many-to-many join tables.

CREATE DATABASE IF NOT EXISTS ecommerce_store
  CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
USE ecommerce_store;

-- ---------------------------------------------------------
-- Table: roles (simple lookup for user roles)
-- ---------------------------------------------------------
CREATE TABLE roles (
  role_id     SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_name   VARCHAR(50) NOT NULL UNIQUE, -- e.g., 'customer', 'admin', 'seller'
  description VARCHAR(255),
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: customers (users who place orders)
-- ---------------------------------------------------------
CREATE TABLE customers (
  customer_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  first_name     VARCHAR(100) NOT NULL,
  last_name      VARCHAR(100) NOT NULL,
  email          VARCHAR(255) NOT NULL UNIQUE,
  username       VARCHAR(100) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  phone_number   VARCHAR(30),
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_customers_roles FOREIGN KEY (role_id) REFERENCES roles(role_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: addresses (1-to-many: customer -> addresses)
-- A customer may have multiple addresses (billing/shipping).
-- ---------------------------------------------------------
CREATE TABLE addresses (
  address_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id    BIGINT UNSIGNED NOT NULL,
  label          VARCHAR(50) DEFAULT 'Home', -- 'Home', 'Office', etc.
  address_line1  VARCHAR(255) NOT NULL,
  address_line2  VARCHAR(255),
  city           VARCHAR(100) NOT NULL,
  state_province VARCHAR(100),
  postal_code    VARCHAR(30),
  country        VARCHAR(100) NOT NULL,
  is_default     TINYINT(1) NOT NULL DEFAULT 0,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_addresses_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: suppliers
-- ---------------------------------------------------------
CREATE TABLE suppliers (
  supplier_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(200) NOT NULL,
  contact_name  VARCHAR(150),
  contact_email VARCHAR(255),
  phone         VARCHAR(30),
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_supplier_name (name)
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: categories (hierarchical via parent_category_id)
-- ---------------------------------------------------------
CREATE TABLE categories (
  category_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parent_id      INT UNSIGNED NULL,
  name           VARCHAR(150) NOT NULL,
  slug           VARCHAR(160) NOT NULL UNIQUE,
  description    TEXT,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: products
-- ---------------------------------------------------------
CREATE TABLE products (
  product_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  supplier_id     INT UNSIGNED NULL,
  sku             VARCHAR(100) NOT NULL UNIQUE,
  name            VARCHAR(255) NOT NULL,
  short_desc      VARCHAR(512),
  long_desc       TEXT,
  price           DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  weight_kg       DECIMAL(8,3) DEFAULT 0,
  is_active       TINYINT(1) NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_products_price (price),
  INDEX idx_products_name (name(100))
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: product_images (1-to-many: product -> images)
-- ---------------------------------------------------------
CREATE TABLE product_images (
  image_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id  BIGINT UNSIGNED NOT NULL,
  url         VARCHAR(1024) NOT NULL,
  alt_text    VARCHAR(255),
  sort_order  INT UNSIGNED NOT NULL DEFAULT 0,
  is_primary  TINYINT(1) NOT NULL DEFAULT 0,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_prodimg_product FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: inventory (per product inventory tracking)
-- ---------------------------------------------------------
CREATE TABLE inventory (
  inventory_id   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id     BIGINT UNSIGNED NOT NULL UNIQUE,
  quantity       INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reorder_level   INT NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
  last_restocked DATETIME,
  CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: product_categories (many-to-many)
-- ---------------------------------------------------------
CREATE TABLE product_categories (
  product_id  BIGINT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (product_id, category_id),
  CONSTRAINT fk_pc_product FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pc_category FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: tags and product_tags (many-to-many)
-- ---------------------------------------------------------
CREATE TABLE tags (
  tag_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name     VARCHAR(100) NOT NULL UNIQUE,
  slug     VARCHAR(120) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE product_tags (
  product_id BIGINT UNSIGNED NOT NULL,
  tag_id     INT UNSIGNED NOT NULL,
  PRIMARY KEY (product_id, tag_id),
  CONSTRAINT fk_pt_product FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pt_tag FOREIGN KEY (tag_id) REFERENCES tags(tag_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: coupons (simple coupon system)
-- ---------------------------------------------------------
CREATE TABLE coupons (
  coupon_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code          VARCHAR(50) NOT NULL UNIQUE,
  description   VARCHAR(255),
  discount_pct  DECIMAL(5,2) CHECK (discount_pct >= 0 AND discount_pct <= 100),
  max_discount  DECIMAL(12,2) CHECK (max_discount >= 0),
  valid_from    DATETIME,
  valid_until   DATETIME,
  uses_left     INT DEFAULT NULL, -- NULL = unlimited
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: orders (one order per placement) - 1-to-many: customer -> orders
-- ---------------------------------------------------------
CREATE TABLE orders (
  order_id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id     BIGINT UNSIGNED NOT NULL,
  billing_address_id  BIGINT UNSIGNED NULL,
  shipping_address_id BIGINT UNSIGNED NULL,
  coupon_id       INT UNSIGNED NULL,
  order_number    VARCHAR(50) NOT NULL UNIQUE, -- human-friendly order num
  subtotal        DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  shipping_cost   DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (shipping_cost >= 0),
  tax_amount      DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
  total_amount    DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
  order_status    ENUM('pending','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
  placed_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_orders_billing_addr FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_orders_shipping_addr FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: order_items (many-to-many between orders and products)
-- Composite PK: (order_id, order_item_id) or (order_id, product_id) depending on design.
-- We'll use order_item_id as surrogate PK and add unique constraint for (order_id, product_id)
-- ---------------------------------------------------------
CREATE TABLE order_items (
  order_item_id   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id        BIGINT UNSIGNED NOT NULL,
  product_id      BIGINT UNSIGNED NOT NULL,
  product_name    VARCHAR(255) NOT NULL, -- snapshot of product name
  sku             VARCHAR(100) NOT NULL,
  unit_price      DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  quantity        INT NOT NULL CHECK (quantity > 0),
  line_total      DECIMAL(12,2) NOT NULL CHECK (line_total >= 0),
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT uq_order_product UNIQUE (order_id, product_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: payments (1-to-1 or 1-to-many depending on split payments)
-- ---------------------------------------------------------
CREATE TABLE payments (
  payment_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id       BIGINT UNSIGNED NOT NULL,
  payment_method ENUM('card','paypal','bank_transfer','cash_on_delivery') NOT NULL,
  payment_status ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
  amount_paid    DECIMAL(12,2) NOT NULL CHECK (amount_paid >= 0),
  transaction_ref VARCHAR(255),
  paid_at        DATETIME,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: product_reviews (customers can review products)
-- ---------------------------------------------------------
CREATE TABLE product_reviews (
  review_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id     BIGINT UNSIGNED NOT NULL,
  customer_id    BIGINT UNSIGNED NOT NULL,
  rating         TINYINT UNSIGNED NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title          VARCHAR(255),
  body           TEXT,
  is_verified    TINYINT(1) DEFAULT 0, -- verified purchaser
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Table: wishlists (one wishlist per customer; many-to-many with products)
-- ---------------------------------------------------------
CREATE TABLE wishlists (
  wishlist_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id    BIGINT UNSIGNED NOT NULL UNIQUE, -- one wishlist per customer
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_wishlist_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE wishlist_items (
  wishlist_id  BIGINT UNSIGNED NOT NULL,
  product_id   BIGINT UNSIGNED NOT NULL,
  added_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (wishlist_id, product_id),
  CONSTRAINT fk_wi_wishlist FOREIGN KEY (wishlist_id) REFERENCES wishlists(wishlist_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_wi_product FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Optional: audit table for product price history (1-to-many)
-- ---------------------------------------------------------
CREATE TABLE product_price_history (
  history_id   BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id   BIGINT UNSIGNED NOT NULL,
  old_price    DECIMAL(12,2) NOT NULL CHECK (old_price >= 0),
  new_price    DECIMAL(12,2) NOT NULL CHECK (new_price >= 0),
  changed_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  changed_by   BIGINT UNSIGNED, -- admin user id in customers table typically
  CONSTRAINT fk_pph_product FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pph_user FOREIGN KEY (changed_by) REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------
-- Example view: orders_summary (read-only convenience)
-- ---------------------------------------------------------
DROP VIEW IF EXISTS v_orders_summary;
CREATE VIEW v_orders_summary AS
SELECT
  o.order_id,
  o.order_number,
  o.customer_id,
  CONCAT(c.first_name,' ',c.last_name) AS customer_name,
  o.total_amount,
  o.order_status,
  o.placed_at
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

-- ---------------------------------------------------------
-- Stored procedure example: Add product to inventory and create product
-- (Optional helper - demonstrates transactional DDL/DML; can be expanded)
-- ---------------------------------------------------------
-- Note: For some MySQL configurations, DEFINER privileges matter.
DROP PROCEDURE IF EXISTS sp_create_product_with_inventory;
DELIMITER $$
CREATE PROCEDURE sp_create_product_with_inventory (
  IN p_sku VARCHAR(100),
  IN p_name VARCHAR(255),
  IN p_price DECIMAL(12,2),
  IN p_supplier INT UNSIGNED,
  IN p_quantity INT
)
BEGIN
  DECLARE new_pid BIGINT UNSIGNED;
  START TRANSACTION;
    INSERT INTO products (supplier_id, sku, name, price)
    VALUES (p_supplier, p_sku, p_name, p_price);
    SET new_pid = LAST_INSERT_ID();
    INSERT INTO inventory (product_id, quantity, reorder_level, last_restocked)
    VALUES (new_pid, p_quantity, 10, NOW());
  COMMIT;
END $$
DELIMITER ;

-- ---------------------------------------------------------
-- Final notes:
-- - All tables use InnoDB engine to support transactions and FKs.
-- - CHECK constraints are included where supported by MySQL version.
-- - Adjust ENUMs, sizes, and defaults to suit your app.
-- ---------------------------------------------------------
