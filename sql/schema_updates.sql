-- SMART FOOD SUPPLY CHAIN OVERHAUL - FINAL LOGIC UNIFICATION & ALERTS
-- 1. CLEANUP
DROP VIEW IF EXISTS v_production_pricing;
DROP VIEW IF EXISTS v_wholesaler_stock_pricing;
DROP VIEW IF EXISTS v_retail_stock_status;
DROP VIEW IF EXISTS v_available_cities;

-- 2. DYNAMIC PRICING VIEW FOR PRODUCTION (Farmer Inventory / Wholesaler Market)
CREATE VIEW v_production_pricing AS
SELECT 
    p.id, p.farmer_id, p.crop_id, p.remaining_quantity as quantity_kg, p.harvest_date, p.expiry_date, p.price_per_kg, p.region as city,
    c.name as crop_name,
    f.name as farmer_name,
    DATEDIFF(p.expiry_date, CURDATE()) as days_to_expiry,
    CASE 
        WHEN DATEDIFF(p.expiry_date, CURDATE()) < 0 THEN 'EXPIRED'
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 30 THEN 'NEAR_EXPIRY (1m)'
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 90 THEN 'MATURING (3m)'
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 180 THEN 'FRESH (6m)'
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 365 THEN 'OPTIMAL (1y)'
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 548 THEN 'STABLE (1.5y)'
        ELSE 'LONG_LIFE (>1.5y)'
    END as status,
    CASE 
        WHEN DATEDIFF(p.expiry_date, CURDATE()) < 0 THEN 0
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 30 THEN p.price_per_kg * 0.5
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 90 THEN p.price_per_kg * 0.7
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 180 THEN p.price_per_kg * 0.8
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 365 THEN p.price_per_kg * 0.85
        WHEN DATEDIFF(p.expiry_date, CURDATE()) <= 548 THEN p.price_per_kg * 0.9
        ELSE p.price_per_kg
    END as discounted_price
FROM PRODUCTION p
JOIN CROP c ON p.crop_id = c.id
JOIN FARMER f ON p.farmer_id = f.id;

-- 3. DYNAMIC PRICING VIEW FOR WHOLESALER STOCK (Retailer Market)
CREATE VIEW v_wholesaler_stock_pricing AS
SELECT 
    ws.id, ws.wholesaler_id, ws.crop_id, ws.quantity_kg, ws.harvest_date, ws.expiry_date, ws.purchase_price_per_kg, ws.selling_price_per_kg, ws.source_farmer_id,
    c.name as crop_name,
    w.name as wholesaler_name,
    w.city,
    DATEDIFF(ws.expiry_date, CURDATE()) as days_to_expiry,
    CASE 
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) < 0 THEN 'EXPIRED'
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 30 THEN 'NEAR_EXPIRY (1m)'
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 90 THEN 'MATURING (3m)'
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 180 THEN 'FRESH (6m)'
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 365 THEN 'OPTIMAL (1y)'
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 548 THEN 'STABLE (1.5y)'
        ELSE 'LONG_LIFE (>1.5y)'
    END as status,
    CASE 
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) < 0 THEN 0
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 30 THEN ws.selling_price_per_kg * 0.5
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 90 THEN ws.selling_price_per_kg * 0.7
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 180 THEN ws.selling_price_per_kg * 0.8
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 365 THEN ws.selling_price_per_kg * 0.85
        WHEN DATEDIFF(ws.expiry_date, CURDATE()) <= 548 THEN ws.selling_price_per_kg * 0.9
        ELSE ws.selling_price_per_kg
    END as discounted_price
FROM WHOLESALER_STOCK ws
JOIN CROP c ON ws.crop_id = c.id
JOIN WHOLESALER w ON ws.wholesaler_id = w.id;

-- 4. VIEW FOR RETAILER STOCK STATUS (Now with discounted_price)
CREATE VIEW v_retail_stock_status AS
SELECT 
    rs.id, rs.retailer_id, rs.crop_id, rs.quantity_kg, rs.harvest_date, rs.expiry_date, rs.purchase_price_per_kg, rs.selling_price_per_kg, rs.source_wholesaler_id,
    c.name as crop_name,
    DATEDIFF(rs.expiry_date, CURDATE()) as days_to_expiry,
    CASE 
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) < 0 THEN 'EXPIRED'
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 30 THEN 'NEAR_EXPIRY (1m)'
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 90 THEN 'MATURING (3m)'
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 180 THEN 'FRESH (6m)'
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 365 THEN 'OPTIMAL (1y)'
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 548 THEN 'STABLE (1.5y)'
        ELSE 'LONG_LIFE (>1.5y)'
    END as status,
    CASE 
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) < 0 THEN 0
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 30 THEN rs.selling_price_per_kg * 0.5
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 90 THEN rs.selling_price_per_kg * 0.7
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 180 THEN rs.selling_price_per_kg * 0.8
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 365 THEN rs.selling_price_per_kg * 0.85
        WHEN DATEDIFF(rs.expiry_date, CURDATE()) <= 548 THEN rs.selling_price_per_kg * 0.9
        ELSE rs.selling_price_per_kg
    END as discounted_price
FROM RETAIL_STOCK rs
JOIN CROP c ON rs.crop_id = c.id;

-- 5. CITIES FOR DROPDOWN
CREATE VIEW v_available_cities AS
SELECT DISTINCT city, 'farmer' as source FROM FARMER
UNION
SELECT DISTINCT city, 'wholesaler' as source FROM WHOLESALER;

-- 6. ALERTS SYSTEM
CREATE TABLE IF NOT EXISTS SYSTEM_ALERTS (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    role VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. PROCEDURES
DROP PROCEDURE IF EXISTS add_production;
CREATE PROCEDURE add_production(
    IN p_farmer_id INT,
    IN p_crop_id INT,
    IN p_quantity DECIMAL(10,2),
    IN p_harvest_date DATE,
    IN p_expiry_date DATE,
    IN p_price DECIMAL(10,2),
    IN p_region VARCHAR(100)
)
BEGIN
    DECLARE v_crop_exists INT;

    -- Validations
    IF p_crop_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'crop_id cannot be NULL';
    END IF;

    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'quantity must be greater than 0';
    END IF;

    SELECT COUNT(*) INTO v_crop_exists FROM CROP WHERE id = p_crop_id;
    IF v_crop_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid crop_id: Crop does not exist';
    END IF;

    -- Insert or Update Quantity if exact batch exists
    INSERT INTO PRODUCTION (farmer_id, crop_id, quantity_kg, remaining_quantity, harvest_date, expiry_date, price_per_kg, region)
    VALUES (p_farmer_id, p_crop_id, p_quantity, p_quantity, p_harvest_date, p_expiry_date, p_price, p_region)
    ON DUPLICATE KEY UPDATE 
        quantity_kg = quantity_kg + p_quantity,
        remaining_quantity = remaining_quantity + p_quantity,
        price_per_kg = p_price;
END;

DROP PROCEDURE IF EXISTS buy_crop;
CREATE PROCEDURE buy_crop(
    IN p_wholesaler_id INT,
    IN p_crop_id INT,
    IN p_quantity DECIMAL(10,2),
    IN p_selling_price DECIMAL(10,2)
)
BEGIN
    DECLARE v_remaining_to_buy DECIMAL(10,2) DEFAULT p_quantity;
    DECLARE v_prod_id INT;
    DECLARE v_rem_qty DECIMAL(10,2);
    DECLARE v_farmer_id INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_h_date DATE;
    DECLARE v_e_date DATE;
    DECLARE v_deduct DECIMAL(10,2);
    DECLARE v_done INT DEFAULT FALSE;
    
    DECLARE cur CURSOR FOR 
        SELECT id, quantity_kg, farmer_id, discounted_price, harvest_date, expiry_date 
        FROM v_production_pricing 
        WHERE crop_id = p_crop_id AND quantity_kg > 0 
        ORDER BY expiry_date ASC;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

    START TRANSACTION;

    IF (SELECT COALESCE(SUM(remaining_quantity),0) FROM PRODUCTION WHERE crop_id = p_crop_id) < p_quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_prod_id, v_rem_qty, v_farmer_id, v_price, v_h_date, v_e_date;
        IF v_done OR v_remaining_to_buy <= 0 THEN LEAVE read_loop; END IF;
        
        SET v_deduct = IF(v_rem_qty <= v_remaining_to_buy, v_rem_qty, v_remaining_to_buy);
        
        UPDATE PRODUCTION SET remaining_quantity = remaining_quantity - v_deduct WHERE id = v_prod_id;
        
        INSERT INTO TRANSACTIONS (wholesaler_id, farmer_id, crop_id, quantity, price)
        VALUES (p_wholesaler_id, v_farmer_id, p_crop_id, v_deduct, v_price);
        
        INSERT INTO WHOLESALER_STOCK (wholesaler_id, crop_id, quantity_kg, harvest_date, expiry_date, purchase_price_per_kg, selling_price_per_kg, source_farmer_id)
        VALUES (p_wholesaler_id, p_crop_id, v_deduct, v_h_date, v_e_date, v_price, p_selling_price, v_farmer_id);
        
        SET v_remaining_to_buy = v_remaining_to_buy - v_deduct;
    END LOOP;
    CLOSE cur;
    COMMIT;
END;

DROP PROCEDURE IF EXISTS sell_stock;
CREATE PROCEDURE sell_stock(
    IN p_wholesaler_stock_id INT,
    IN p_retailer_id INT,
    IN p_quantity DECIMAL(10,2),
    IN p_selling_price DECIMAL(10,2)
)
BEGIN
    DECLARE v_available_qty DECIMAL(10,2);
    DECLARE v_crop_id INT;
    DECLARE v_h_date DATE;
    DECLARE v_e_date DATE;
    DECLARE v_w_id INT;
    DECLARE v_price DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;

    IF p_wholesaler_stock_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'wholesaler_stock_id cannot be null';
    END IF;

    START TRANSACTION;
    
    SELECT quantity_kg, crop_id, harvest_date, expiry_date, wholesaler_id, discounted_price 
    INTO v_available_qty, v_crop_id, v_h_date, v_e_date, v_w_id, v_price
    FROM v_wholesaler_stock_pricing 
    WHERE id = p_wholesaler_stock_id FOR UPDATE;
    
    IF v_available_qty IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock item not found';
    ELSEIF v_available_qty < p_quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    ELSE
        UPDATE WHOLESALER_STOCK SET quantity_kg = quantity_kg - p_quantity WHERE id = p_wholesaler_stock_id;
        
        INSERT INTO RETAIL_STOCK (retailer_id, crop_id, quantity_kg, harvest_date, expiry_date, purchase_price_per_kg, selling_price_per_kg, source_wholesaler_id)
        VALUES (p_retailer_id, v_crop_id, p_quantity, v_h_date, v_e_date, v_price, p_selling_price, v_w_id);
        
        COMMIT;
    END IF;
END;

-- 8. TRIGGERS FOR ALERTS
DROP TRIGGER IF EXISTS after_transaction_insert;
CREATE TRIGGER after_transaction_insert
AFTER INSERT ON TRANSACTIONS
FOR EACH ROW
BEGIN
    DECLARE v_wholesaler_name VARCHAR(255);
    DECLARE v_crop_name VARCHAR(100);
    
    SELECT name INTO v_wholesaler_name FROM WHOLESALER WHERE id = NEW.wholesaler_id;
    SELECT name INTO v_crop_name FROM CROP WHERE id = NEW.crop_id;
    
    INSERT INTO SYSTEM_ALERTS (user_id, role, message)
    VALUES (NEW.farmer_id, 'FARMER', CONCAT('Wholesaler ', v_wholesaler_name, ' purchased ', NEW.quantity, 'kg of ', v_crop_name));
END;

DROP TRIGGER IF EXISTS after_retail_stock_insert;
CREATE TRIGGER after_retail_stock_insert
AFTER INSERT ON RETAIL_STOCK
FOR EACH ROW
BEGIN
    DECLARE v_retailer_name VARCHAR(255);
    DECLARE v_crop_name VARCHAR(100);
    
    IF NEW.source_wholesaler_id IS NOT NULL THEN
        SELECT name INTO v_retailer_name FROM RETAILER WHERE id = NEW.retailer_id;
        SELECT name INTO v_crop_name FROM CROP WHERE id = NEW.crop_id;
        
        INSERT INTO SYSTEM_ALERTS (user_id, role, message)
        VALUES (NEW.source_wholesaler_id, 'WHOLESALER', CONCAT('Retailer ', v_retailer_name, ' purchased ', NEW.quantity_kg, 'kg of ', v_crop_name));
    END IF;
END;
