-- ============================================
-- Smart Food Supply Chain Management System
-- SAMPLE SEED DATA
-- ============================================

USE smart_food_supply;

-- Disable foreign key checks for clean loading
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Crops
INSERT INTO CROP (id, name, category, base_price_per_kg, shelf_life_days) VALUES
(101, 'Wheat', 'Rabi', 24.25, 365),
(102, 'Paddy', 'Kharif', 23.69, 365),
(103, 'Maize', 'Kharif', 24.00, 180),
(104, 'Bajra', 'Kharif', 27.75, 150),
(105, 'Mustard', 'Rabi', 56.50, 180),
(106, 'Groundnut', 'Kharif', 72.63, 180),
(107, 'Cotton', 'Kharif', 72.00, 730),
(108, 'Sugarcane', 'Annual', 3.15, 15),
(109, 'Gram', 'Rabi', 54.00, 240),
(110, 'Moong Dal', 'Kharif', 87.68, 240),
(111, 'Apple', 'Kharif', 70.00, 90),
(112, 'Watermelon', 'Zaid', 8.00, 14),
(113, 'Potato', 'Rabi', 14.00, 120),
(114, 'Onion', 'Kharif/Rabi', 16.00, 180),
(115, 'Cumin', 'Rabi', 260.00, 730)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 2. Farmers
INSERT INTO FARMER (id, name, city, state, contact) VALUES
(1, 'Hans Raj', 'Ferozpur', 'Punjab', '7201942509'),
(2, 'Amarjeet Singh', 'Sangrur', 'Punjab', '9676685950'),
(3, 'Rimpi Saini', 'Gurdaspur', 'Punjab', '9477448785'),
(4, 'Sultan Singh', 'Bhatinda', 'Punjab', '9045547439'),
(5, 'Bhupinder Singh', 'Faridkot', 'Punjab', '8701076637'),
(6, 'Kishan Lal', 'Alwar', 'Rajasthan', '8125817769'),
(7, 'Mahavir Sinver', 'Hanumangarh', 'Rajasthan', '7403949315'),
(8, 'Jaideep Pareek', 'Jaipur', 'Rajasthan', '9984964632'),
(9, 'Sunita Yadav', 'Rewari', 'Haryana', '9308533810'),
(10, 'Prashant Chauhan', 'Yamuna Nagar', 'Haryana', '8142551469'),
(11, 'Sandeep Hooda', 'Rohtak', 'Haryana', '9011064304'),
(12, 'Jain Bhagchandra', 'Vadodara', 'Gujarat', '7087531859'),
(13, 'Devji Patel', 'Bhavnagar', 'Gujarat', '7582351551'),
(14, 'Ankit Chauhan', 'Shimla', 'Himachal Pradesh', '9055385348'),
(15, 'Rajesh Sharma', 'Hamirpur', 'Himachal Pradesh', '8743834974')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 3. Wholesalers
INSERT INTO WHOLESALER (id, name, city, state, contact) VALUES
(1, 'Mother Pure Mustard Oil', 'Delhi', 'Delhi', '8950294578'),
(2, 'Jai Mata Trading Company', 'Haldwani', 'Uttarakhand', '6167557318'),
(3, 'Shree Krishna Exports', 'Nagpur', 'Maharashtra', '6739782424'),
(4, 'Ramesh Gupta & Co', 'Jodhpur', 'Rajasthan', '6773288799'),
(5, 'Abhidnya Agro Industries', 'Taraori', 'Haryana', '8988996658'),
(6, 'Maa Ambe Enterprises', 'Sikar', 'Rajasthan', '7582593386'),
(7, 'Maa Vaishno Traders', 'Udaipur', 'Rajasthan', '7937365550'),
(8, 'Rajshri Agro Techno Foods', 'Patna', 'Bihar', '6231670868'),
(9, 'Sewa Enterprises', 'Jaipur', 'Rajasthan', '9239954607'),
(10, 'Mahaluxmi Seeds & Rice', 'Indore', 'Madhya Pradesh', '8305768057'),
(11, 'Grocery Bazar', 'Ahmedabad', 'Gujarat', '6272018683'),
(12, 'Deshi Adda Traders', 'Bilaspur', 'Chhattisgarh', '8168494619')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 4. Retailers
INSERT INTO RETAILER (id, name, city, state, contact) VALUES
(1, 'Reliance Smart', 'Delhi', 'Delhi', '9000000001'),
(2, 'DMart Ready', 'Delhi', 'Delhi', '9000000002'),
(3, 'More Supermarket', 'Delhi', 'Delhi', '9000000003'),
(4, 'Spencers Retail', 'Delhi', 'Delhi', '9000000004'),
(5, 'Vishal Mega Mart', 'Delhi', 'Delhi', '9000000005'),
(6, 'Reliance Smart', 'Gurgaon', 'Haryana', '9000000011'),
(7, 'Easyday Club', 'Gurgaon', 'Haryana', '9000000012'),
(8, 'FreshCo Retail', 'Gurgaon', 'Haryana', '9000000014'),
(9, 'Daily Needs Store', 'Panipat', 'Haryana', '9000000016'),
(10, 'Reliance Fresh', 'Rohtak', 'Haryana', '9000000017'),
(11, 'More Supermarket', 'Karnal', 'Haryana', '9000000020'),
(12, 'Apna Bazaar', 'Jaipur', 'Rajasthan', '9000000025'),
(13, 'City Kirana Store', 'Jodhpur', 'Rajasthan', '9000000026'),
(14, 'Metro Supermarket', 'Ludhiana', 'Punjab', '9000000030'),
(15, 'Kisan Agro Mart', 'Amritsar', 'Punjab', '9000000031')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 5. Wholesaler Stock
INSERT INTO WHOLESALER_STOCK (id, wholesaler_id, crop_id, quantity_kg, purchase_date, expiry_date, purchase_price, selling_price) VALUES
(1, 1, 101, 5000.00, '2026-09-01', '2027-05-31', 24.25, 27.50),
(2, 2, 102, 3500.00, '2026-08-15', '2027-10-31', 23.69, 26.00),
(3, 3, 105, 1200.00, '2026-04-10', '2026-10-25', 56.50, 62.00),
(4, 4, 113, 2000.00, '2026-07-01', '2026-10-18', 14.00, 18.00),
(5, 5, 112, 800.00, '2026-06-01', '2026-07-15', 8.00, 11.00),
(6, 6, 115, 600.00, '2026-05-10', '2028-04-30', 260.00, 290.00),
(7, 7, 109, 1500.00, '2026-09-12', '2027-01-31', 54.00, 59.00),
(8, 8, 114, 2200.00, '2026-08-20', '2026-11-05', 16.00, 20.00),
(9, 9, 111, 950.00, '2026-08-01', '2026-10-01', 70.00, 85.00),
(10, 10, 103, 3100.00, '2026-09-05', '2027-04-30', 24.00, 28.00),
(11, 11, 104, 1800.00, '2026-09-15', '2027-04-30', 27.75, 31.00),
(12, 12, 106, 2500.00, '2026-07-10', '2027-05-31', 72.63, 78.00)
ON DUPLICATE KEY UPDATE quantity_kg=VALUES(quantity_kg);

-- 6. Retail Stock
INSERT INTO RETAIL_STOCK (id, retailer_id, crop_id, quantity_kg, purchase_date, expiry_date, cost_price, selling_price) VALUES
(1, 1, 101, 800.00, '2026-09-10', '2027-05-31', 27.50, 31.00),
(2, 2, 102, 650.00, '2026-09-05', '2027-10-31', 26.00, 30.00),
(3, 3, 105, 300.00, '2026-09-15', '2026-10-28', 62.00, 70.00),
(4, 4, 113, 450.00, '2026-09-20', '2026-10-15', 18.00, 22.00),
(5, 5, 112, 200.00, '2026-06-15', '2026-07-20', 11.00, 15.00),
(6, 6, 114, 500.00, '2026-09-25', '2026-11-02', 20.00, 25.00),
(7, 7, 111, 250.00, '2026-09-01', '2026-09-30', 85.00, 110.00),
(8, 8, 109, 400.00, '2026-09-18', '2027-01-31', 59.00, 68.00),
(9, 9, 103, 700.00, '2026-09-12', '2027-04-30', 28.00, 33.00),
(10, 10, 115, 120.00, '2026-09-10', '2028-04-30', 290.00, 340.00)
ON DUPLICATE KEY UPDATE quantity_kg=VALUES(quantity_kg);

-- 7. Optional Transactions (Demand Proxy)
CREATE TABLE IF NOT EXISTS TRANSACTIONS (
    id INT AUTO_INCREMENT PRIMARY KEY,
    wholesaler_id INT,
    farmer_id INT,
    crop_id INT,
    quantity DECIMAL(10,2),
    price DECIMAL(10,2),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (crop_id) REFERENCES CROP(id)
);

INSERT INTO TRANSACTIONS (id, wholesaler_id, farmer_id, crop_id, quantity, price) VALUES
(1, 1, 1, 101, 2500.00, 24.25),
(2, 2, 2, 102, 1800.00, 23.69),
(3, 3, 3, 101, 3000.00, 24.25),
(4, 4, 4, 105, 900.00, 56.50),
(5, 5, 5, 113, 1500.00, 14.00),
(6, 6, 6, 101, 2100.00, 24.25),
(7, 7, 7, 105, 1200.00, 56.50),
(8, 8, 8, 102, 1600.00, 23.69),
(9, 9, 9, 114, 1400.00, 16.00),
(10, 10, 10, 111, 750.00, 70.00)
ON DUPLICATE KEY UPDATE quantity=VALUES(quantity);

SET FOREIGN_KEY_CHECKS = 1;
