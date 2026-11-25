-- ============================================================
-- Brew Haven POS · XAMPP / MySQL  (v6: login, reports, coffee-only menu)
-- Import in phpMyAdmin  →  http://localhost/phpmyadmin
-- Menu = COFFEE only (matches the paper & the Brew Haven old system)
-- ============================================================

CREATE DATABASE IF NOT EXISTS pos_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pos_db;

DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS recipes;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS ingredients;
DROP TABLE IF EXISTS menu_items;

-- ---------- products (cafe menu) ----------
CREATE TABLE menu_items (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(80)  NOT NULL,
  category    VARCHAR(40)  NOT NULL,              -- Coffee | Non-coffee | Pastries | Meals
  price       DECIMAL(10,2) NOT NULL,
  description VARCHAR(120) NOT NULL DEFAULT '',
  icon        VARCHAR(16)  NOT NULL DEFAULT '☕',
  available   TINYINT(1)   NOT NULL DEFAULT 1,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- orders ----------
CREATE TABLE orders (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  number      VARCHAR(20)  NOT NULL,
  type        VARCHAR(20)  NOT NULL DEFAULT 'Dine in',
  status      ENUM('pending','ready','paid','cancelled') NOT NULL DEFAULT 'pending',
  payment     VARCHAR(20)  DEFAULT NULL,
  payment_ref VARCHAR(40)  DEFAULT NULL,           -- GCash reference no. (optional)
  received    DECIMAL(10,2) DEFAULT NULL,
  subtotal    DECIMAL(10,2) NOT NULL DEFAULT 0,
  total       DECIMAL(10,2) NOT NULL DEFAULT 0,
  order_date  DATE         NOT NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE order_items (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id     INT UNSIGNED NOT NULL,
  menu_item_id INT UNSIGNED NOT NULL,
  name         VARCHAR(80) NOT NULL,
  price        DECIMAL(10,2) NOT NULL,
  qty          INT UNSIGNED NOT NULL DEFAULT 1,
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_oi_menu  FOREIGN KEY (menu_item_id) REFERENCES menu_items(id)
) ENGINE=InnoDB;

-- ---------- ingredients (costing + realtime stock) ----------
CREATE TABLE ingredients (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(80)  NOT NULL,
  unit           VARCHAR(20)  NOT NULL DEFAULT 'g',
  purchase_qty   DECIMAL(12,3) NOT NULL,          -- qty bought (for unit cost)
  purchase_price DECIMAL(10,2) NOT NULL,          -- price paid for purchase_qty
  stock          DECIMAL(12,3) NOT NULL DEFAULT 0,-- current stock on hand
  reorder_level  DECIMAL(12,3) NOT NULL DEFAULT 0,-- low-stock alert threshold
  updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- recipes (product → ingredients per serving) ----------
CREATE TABLE recipes (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  menu_item_id  INT UNSIGNED NOT NULL,
  ingredient_id INT UNSIGNED NOT NULL,
  quantity      DECIMAL(12,3) NOT NULL,
  UNIQUE KEY uq_recipe (menu_item_id, ingredient_id),
  CONSTRAINT fk_r_menu FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE,
  CONSTRAINT fk_r_ing  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- stock movements (realtime tracking log) ----------
CREATE TABLE stock_movements (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ingredient_id INT UNSIGNED NOT NULL,
  `change`      DECIMAL(12,3) NOT NULL,           -- negative = used, positive = restocked (backticked: reserved word)
  reason        VARCHAR(60)  NOT NULL,            -- 'order' | 'restock' | 'adjust'
  order_id      INT UNSIGNED DEFAULT NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_m_ing FOREIGN KEY (ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ---------- staff (logins) ----------
-- Passwords are hashed by api.php on first run:
--   admin  → admin123      (change after first login in phpMyAdmin or code)
--   cashier access code → 1234
CREATE TABLE staff (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name             VARCHAR(60)  NOT NULL,
  username         VARCHAR(60)  DEFAULT NULL,
  password_hash    VARCHAR(255) DEFAULT NULL,   -- admin login
  access_code_hash VARCHAR(255) DEFAULT NULL,   -- cashier code
  role             ENUM('admin','cashier') NOT NULL,
  created_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO staff (name, username, role) VALUES
('Admin', 'admin', 'admin'),
('Front Counter', NULL, 'cashier');

-- ================= MENU — COFFEE ONLY (12 drinks) =================
INSERT INTO menu_items (name, category, price, description, icon, available) VALUES
('Spanish Latte', 'Coffee', 150.00, 'Sweet condensed milk espresso', '☕', 1),
('Cappuccino', 'Coffee', 130.00, 'Espresso with steamed milk foam', '☕', 1),
('Americano', 'Coffee', 110.00, 'Double shot with hot water', '☕', 1),
('Café Latte', 'Coffee', 125.00, 'Smooth espresso and silky milk', '☕', 1),
('Caramel Macchiato', 'Coffee', 165.00, 'Vanilla, milk, caramel drizzle', '🍮', 1),
('Cold Brew', 'Coffee', 140.00, '18-hour steeped, served iced', '🧊', 1),
('Mocha Latte', 'Coffee', 155.00, 'Espresso, chocolate and steamed milk', '🍫', 1),
('White Mocha', 'Coffee', 160.00, 'White chocolate and espresso', '🤍', 1),
('Salted Caramel Latte', 'Coffee', 170.00, 'Caramel, milk and a pinch of sea salt', '🧂', 1),
('Vanilla Cold Brew', 'Coffee', 150.00, 'Cold brew, vanilla, splash of milk', '🍦', 1),
('Espresso', 'Coffee', 95.00, 'Double shot, straight up', '⚡', 1),
('Macchiato', 'Coffee', 120.00, 'Espresso marked with milk foam', '🥛', 1);

-- ================= INGREDIENTS — coffee recipes only (10) =================
-- unit cost = purchase_price / purchase_qty ;  stock = current on hand
-- ids 1-8 are the espresso-bar items, 19/20 keep their original ids, so
-- ingredients added later in the app start at 21
INSERT INTO ingredients (id, name, unit, purchase_qty, purchase_price, stock, reorder_level) VALUES
(1, 'Espresso beans', 'g', 1000, 850, 750, 200),
(2, 'Fresh milk', 'ml', 1000, 95, 600, 250),
(3, 'Condensed milk', 'ml', 1000, 120, 800, 250),
(4, 'Chocolate sauce', 'ml', 750, 300, 480, 150),
(5, 'White chocolate sauce', 'ml', 750, 330, 380, 150),
(6, 'Sea salt', 'g', 250, 45, 200, 50),
(7, 'Whipped cream', 'ml', 500, 180, 300, 100),
(8, 'Cinnamon powder', 'g', 100, 60, 90, 25),
(19, 'Vanilla syrup', 'ml', 750, 320, 420, 150),
(20, 'Caramel sauce', 'ml', 750, 340, 85, 100);

-- ================= RECIPES (per serving) — coffee only =================
INSERT INTO recipes (menu_item_id, ingredient_id, quantity) VALUES
(1, 1, 18), (1, 2, 120), (1, 3, 40), (1, 19, 8),            -- Spanish Latte
(2, 1, 18), (2, 2, 120), (2, 8, 1),                         -- Cappuccino
(3, 1, 18),                                                 -- Americano
(4, 1, 18), (4, 2, 180),                                    -- Café Latte
(5, 1, 18), (5, 2, 150), (5, 20, 20), (5, 19, 10), (5, 7, 20), -- Caramel Macchiato
(6, 1, 30),                                                 -- Cold Brew
(7, 1, 18), (7, 2, 150), (7, 4, 20), (7, 7, 20),            -- Mocha Latte
(8, 1, 18), (8, 2, 150), (8, 5, 20), (8, 7, 20),            -- White Mocha
(9, 1, 18), (9, 2, 150), (9, 20, 20), (9, 6, 1),            -- Salted Caramel Latte
(10, 1, 30), (10, 19, 15), (10, 2, 60),                     -- Vanilla Cold Brew
(11, 1, 18),                                                -- Espresso
(12, 1, 18), (12, 2, 60)                                    -- Macchiato
;

-- ================= STOCK LOG SEED =================
INSERT INTO stock_movements (ingredient_id, `change`, reason, created_at) VALUES
(1, -180, 'order', NOW() - INTERVAL 3 HOUR),
(2, -600, 'order', NOW() - INTERVAL 3 HOUR),
(1,  750, 'restock', NOW() - INTERVAL 1 DAY),
(20, -40, 'order', NOW() - INTERVAL 2 HOUR),
(19, -25, 'order', NOW() - INTERVAL 5 HOUR),
(3, -160, 'order', NOW() - INTERVAL 3 HOUR),
(4,  -80, 'order', NOW() - INTERVAL 2 HOUR),
(5,  -60, 'order', NOW() - INTERVAL 2 HOUR),
(7, -100, 'order', NOW() - INTERVAL 90 MINUTE),
(3,  800, 'restock', NOW() - INTERVAL 2 DAY),
(4,  750, 'restock', NOW() - INTERVAL 2 DAY),
(8,   90, 'restock', NOW() - INTERVAL 4 DAY);
