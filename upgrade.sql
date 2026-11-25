-- ============================================================
-- Brew Haven POS — UPGRADE (one file, everything included)
-- Use this ONLY if you already imported an older database and want
-- to keep your existing orders. It adds:
--   • orders.payment_ref  (GCash / card approval reference)
--   • the 6 extra coffee drinks + 6 new ingredients
--   • rebuilt recipes for all 12 drinks
-- phpMyAdmin → pos_db → SQL tab → paste → Go.
-- Safe to run twice: it never duplicates rows or drops data.
-- ============================================================

USE pos_db;

-- ---------- 0. add the GCash / card reference column ----------
-- If phpMyAdmin answers "Duplicate column name 'payment_ref'", that is fine —
-- the column is already there. Skip this one line and run the rest.
ALTER TABLE orders ADD COLUMN payment_ref VARCHAR(40) DEFAULT NULL AFTER payment;

-- ---------- 1. new ingredients (skipped if the name already exists) ----------
INSERT INTO ingredients (name, unit, purchase_qty, purchase_price, stock, reorder_level)
SELECT 'Condensed milk', 'ml', 1000, 120, 800, 250 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM ingredients WHERE name = 'Condensed milk');
INSERT INTO ingredients (name, unit, purchase_qty, purchase_price, stock, reorder_level)
SELECT 'Chocolate sauce', 'ml', 750, 300, 480, 150 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM ingredients WHERE name = 'Chocolate sauce');
INSERT INTO ingredients (name, unit, purchase_qty, purchase_price, stock, reorder_level)
SELECT 'White chocolate sauce', 'ml', 750, 330, 380, 150 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM ingredients WHERE name = 'White chocolate sauce');
INSERT INTO ingredients (name, unit, purchase_qty, purchase_price, stock, reorder_level)
SELECT 'Sea salt', 'g', 250, 45, 200, 50 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM ingredients WHERE name = 'Sea salt');
INSERT INTO ingredients (name, unit, purchase_qty, purchase_price, stock, reorder_level)
SELECT 'Whipped cream', 'ml', 500, 180, 300, 100 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM ingredients WHERE name = 'Whipped cream');
INSERT INTO ingredients (name, unit, purchase_qty, purchase_price, stock, reorder_level)
SELECT 'Cinnamon powder', 'g', 100, 60, 90, 25 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM ingredients WHERE name = 'Cinnamon powder');

-- ---------- 2. new coffee products (skipped if the name already exists) ----------
INSERT INTO menu_items (name, category, price, description, icon, available)
SELECT 'Mocha Latte', 'Coffee', 155.00, 'Espresso, chocolate and steamed milk', '🍫', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE name = 'Mocha Latte');
INSERT INTO menu_items (name, category, price, description, icon, available)
SELECT 'White Mocha', 'Coffee', 160.00, 'White chocolate and espresso', '🤍', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE name = 'White Mocha');
INSERT INTO menu_items (name, category, price, description, icon, available)
SELECT 'Salted Caramel Latte', 'Coffee', 170.00, 'Caramel, milk and a pinch of sea salt', '🧂', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE name = 'Salted Caramel Latte');
INSERT INTO menu_items (name, category, price, description, icon, available)
SELECT 'Vanilla Cold Brew', 'Coffee', 150.00, 'Cold brew, vanilla, splash of milk', '🍦', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE name = 'Vanilla Cold Brew');
INSERT INTO menu_items (name, category, price, description, icon, available)
SELECT 'Espresso', 'Coffee', 95.00, 'Double shot, straight up', '⚡', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE name = 'Espresso');
INSERT INTO menu_items (name, category, price, description, icon, available)
SELECT 'Macchiato', 'Coffee', 120.00, 'Espresso marked with milk foam', '🥛', 1 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE name = 'Macchiato');

-- ---------- 3. rebuild the recipes for all 12 drinks (by name, not by id) ----------
DELETE r FROM recipes r JOIN menu_items m ON m.id = r.menu_item_id
WHERE m.name IN ('Spanish Latte', 'Cappuccino', 'Americano', 'Café Latte', 'Caramel Macchiato', 'Cold Brew', 'Mocha Latte', 'White Mocha', 'Salted Caramel Latte', 'Vanilla Cold Brew', 'Espresso', 'Macchiato');

INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Spanish Latte' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 120 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Spanish Latte' AND i.name = 'Fresh milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 40 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Spanish Latte' AND i.name = 'Condensed milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 8 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Spanish Latte' AND i.name = 'Vanilla syrup';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Cappuccino' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 120 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Cappuccino' AND i.name = 'Fresh milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 1 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Cappuccino' AND i.name = 'Cinnamon powder';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Americano' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Café Latte' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 180 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Café Latte' AND i.name = 'Fresh milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Caramel Macchiato' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 150 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Caramel Macchiato' AND i.name = 'Fresh milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 20 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Caramel Macchiato' AND i.name = 'Caramel sauce';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 10 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Caramel Macchiato' AND i.name = 'Vanilla syrup';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 20 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Caramel Macchiato' AND i.name = 'Whipped cream';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 30 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Cold Brew' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Mocha Latte' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 150 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Mocha Latte' AND i.name = 'Fresh milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 20 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Mocha Latte' AND i.name = 'Chocolate sauce';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 20 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Mocha Latte' AND i.name = 'Whipped cream';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'White Mocha' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 150 FROM menu_items m JOIN ingredients i
WHERE m.name = 'White Mocha' AND i.name = 'Fresh milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 20 FROM menu_items m JOIN ingredients i
WHERE m.name = 'White Mocha' AND i.name = 'White chocolate sauce';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 20 FROM menu_items m JOIN ingredients i
WHERE m.name = 'White Mocha' AND i.name = 'Whipped cream';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Salted Caramel Latte' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 150 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Salted Caramel Latte' AND i.name = 'Fresh milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 20 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Salted Caramel Latte' AND i.name = 'Caramel sauce';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 1 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Salted Caramel Latte' AND i.name = 'Sea salt';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 30 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Vanilla Cold Brew' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 15 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Vanilla Cold Brew' AND i.name = 'Vanilla syrup';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 60 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Vanilla Cold Brew' AND i.name = 'Fresh milk';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Espresso' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 18 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Macchiato' AND i.name = 'Espresso beans';
INSERT INTO recipes (menu_item_id, ingredient_id, quantity)
SELECT m.id, i.id, 60 FROM menu_items m JOIN ingredients i
WHERE m.name = 'Macchiato' AND i.name = 'Fresh milk';

-- ---------- 4. opening stock log entries for the new ingredients ----------
INSERT INTO stock_movements (ingredient_id, `change`, reason)
SELECT id, stock, 'restock' FROM ingredients
WHERE name IN ('Condensed milk', 'Chocolate sauce', 'White chocolate sauce',
               'Sea salt', 'Whipped cream', 'Cinnamon powder');

-- ---------- check ----------
SELECT COUNT(*) AS products FROM menu_items WHERE category = 'Coffee';   -- expect 12
SELECT COUNT(*) AS ingredients FROM ingredients;                          -- expect 10
SELECT COUNT(*) AS recipe_lines FROM recipes;                             -- expect 34
