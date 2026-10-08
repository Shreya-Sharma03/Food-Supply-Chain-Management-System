-- ============================================
-- Smart Food Supply Chain Management System
-- CLEAN + CSV-ALIGNED SCHEMA
-- ============================================

CREATE DATABASE IF NOT EXISTS smart_food_supply;
USE smart_food_supply;

-- ================= USER AUTH =================
CREATE TABLE USER_AUTH (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('FARMER', 'WHOLESALER', 'RETAILER', 'ADMIN') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================= CROP =================
CREATE TABLE CROP (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    base_price_per_kg DECIMAL(10,2) NOT NULL,
    shelf_life_days INT NOT NULL
);

-- ================= FARMER =================
CREATE TABLE FARMER (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    contact VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES USER_AUTH(id)
);

-- ================= WHOLESALER =================
CREATE TABLE WHOLESALER (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    contact VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES USER_AUTH(id)
);

-- ================= RETAILER =================
CREATE TABLE RETAILER (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    contact VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES USER_AUTH(id)
);

-- ================= WHOLESALER STOCK =================
CREATE TABLE WHOLESALER_STOCK (
    id INT AUTO_INCREMENT PRIMARY KEY,
    wholesaler_id INT NOT NULL,
    crop_id INT NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,

    -- mapped from CSV
    purchase_date DATE,
    expiry_date DATE,

    purchase_price DECIMAL(10,2),
    selling_price DECIMAL(10,2),

    FOREIGN KEY (wholesaler_id) REFERENCES WHOLESALER(id),
    FOREIGN KEY (crop_id) REFERENCES CROP(id)
);

-- ================= RETAIL STOCK =================
CREATE TABLE RETAIL_STOCK (
    id INT AUTO_INCREMENT PRIMARY KEY,
    retailer_id INT NOT NULL,
    crop_id INT NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,

    -- since CSV doesn't provide these properly
    purchase_date DATE,
    expiry_date DATE,

    cost_price DECIMAL(10,2),
    selling_price DECIMAL(10,2),

    FOREIGN KEY (retailer_id) REFERENCES RETAILER(id),
    FOREIGN KEY (crop_id) REFERENCES CROP(id)
);

-- ================= OPTIONAL: ALERTS =================
CREATE TABLE EXPIRY_ALERTS (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stock_type ENUM('WHOLESALER_STOCK', 'RETAIL_STOCK') NOT NULL,
    stock_id INT NOT NULL,
    alert_type ENUM('FRESH', 'NEAR_EXPIRY', 'EXPIRED') NOT NULL,
    days_left INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);