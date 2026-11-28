-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 28, 2026 at 07:38 AM
-- Server version: 10.11.16-MariaDB
-- PHP Version: 8.5.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bean_bloom`
--
CREATE DATABASE IF NOT EXISTS `bean_bloom` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `bean_bloom`;

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `actor_user_id` int(10) UNSIGNED DEFAULT NULL,
  `action` varchar(80) NOT NULL,
  `entity_type` varchar(40) DEFAULT NULL,
  `entity_id` bigint(20) UNSIGNED DEFAULT NULL,
  `details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details`)),
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cashier_shifts`
--

CREATE TABLE `cashier_shifts` (
  `id` int(10) UNSIGNED NOT NULL,
  `employee_id` int(10) UNSIGNED NOT NULL,
  `manager_id` int(10) UNSIGNED DEFAULT NULL,
  `work_date` date NOT NULL,
  `status` enum('pending','approved','rejected','ended') NOT NULL DEFAULT 'pending',
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `approved_at` timestamp NULL DEFAULT NULL,
  `ended_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `menu_items`
--

CREATE TABLE `menu_items` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `category` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `available` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `menu_items`
--

INSERT INTO `menu_items` (`id`, `name`, `category`, `description`, `price`, `available`, `created_at`, `updated_at`) VALUES
(1, 'House Latte', 'Coffee', 'Espresso, steamed milk', 145.00, 1, '2026-11-04 08:46:21', '2026-11-04 08:46:21'),
(2, 'Caramel Macchiato', 'Coffee', 'Vanilla, caramel drizzle', 165.00, 1, '2026-11-04 08:46:21', '2026-11-04 08:46:21'),
(3, 'Cold Brew', 'Coffee', 'Smooth, slow-steeped coffee', 135.00, 1, '2026-11-04 08:46:21', '2026-11-04 08:46:21'),
(4, 'Matcha Cloud', 'Non-coffee', 'Ceremonial matcha, milk', 160.00, 1, '2026-11-04 08:46:21', '2026-11-04 08:46:21'),
(5, 'Chocolate Frappe', 'Non-coffee', 'Chocolate, cream, cocoa', 175.00, 1, '2026-11-04 08:46:21', '2026-11-04 08:46:21'),
(6, 'Butter Croissant', 'Pastries', 'Flaky and baked fresh', 95.00, 1, '2026-11-04 08:46:21', '2026-11-04 08:46:21'),
(7, 'Cinnamon Roll', 'Pastries', 'Warm cinnamon glaze', 110.00, 1, '2026-11-04 08:46:21', '2026-11-04 08:46:21'),
(8, 'Bacon & Egg Toast', 'Meals', 'Sourdough, egg, bacon', 210.00, 1, '2026-11-04 08:46:21', '2026-11-04 08:46:21');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cashier_id` int(10) UNSIGNED NOT NULL,
  `shift_id` int(10) UNSIGNED NOT NULL,
  `order_type` enum('Dine in','Takeaway') NOT NULL,
  `status` enum('pending','ready','paid','cancelled') NOT NULL DEFAULT 'pending',
  `subtotal` decimal(10,2) NOT NULL,
  `service_charge` decimal(10,2) NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `payment_method` varchar(30) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `paid_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `menu_item_id` int(10) UNSIGNED NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `quantity` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('manager','cashier') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_audit_actor` (`actor_user_id`),
  ADD KEY `idx_audit_created` (`created_at`),
  ADD KEY `idx_audit_action` (`action`);

--
-- Indexes for table `cashier_shifts`
--
ALTER TABLE `cashier_shifts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_shift_employee` (`employee_id`),
  ADD KEY `fk_shift_manager` (`manager_id`),
  ADD KEY `idx_shift_status_date` (`status`,`work_date`);

--
-- Indexes for table `menu_items`
--
ALTER TABLE `menu_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_order_cashier` (`cashier_id`),
  ADD KEY `fk_order_shift` (`shift_id`),
  ADD KEY `idx_orders_created` (`created_at`),
  ADD KEY `idx_orders_status` (`status`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_order_item_order` (`order_id`),
  ADD KEY `fk_order_item_menu` (`menu_item_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cashier_shifts`
--
ALTER TABLE `cashier_shifts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `menu_items`
--
ALTER TABLE `menu_items`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `fk_audit_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `cashier_shifts`
--
ALTER TABLE `cashier_shifts`
  ADD CONSTRAINT `fk_shift_employee` FOREIGN KEY (`employee_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_shift_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_order_cashier` FOREIGN KEY (`cashier_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_order_shift` FOREIGN KEY (`shift_id`) REFERENCES `cashier_shifts` (`id`);

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_order_item_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`),
  ADD CONSTRAINT `fk_order_item_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;
--
-- Database: `bean_bloom_demo`
--
CREATE DATABASE IF NOT EXISTS `bean_bloom_demo` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `bean_bloom_demo`;

-- --------------------------------------------------------

--
-- Table structure for table `ingredients`
--

CREATE TABLE `ingredients` (
  `ingredient_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(80) NOT NULL,
  `quantity` decimal(12,3) NOT NULL,
  `unit` varchar(20) NOT NULL,
  `purchase_price` decimal(12,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ingredients`
--

INSERT INTO `ingredients` (`ingredient_id`, `name`, `quantity`, `unit`, `purchase_price`) VALUES
(1, 'Espresso beans', 1000.000, 'g', 850.00),
(2, 'Fresh milk', 1000.000, 'ml', 95.00),
(3, 'Matcha powder', 250.000, 'g', 600.00),
(4, 'Chocolate syrup', 1000.000, 'ml', 260.00),
(5, 'Croissant', 12.000, 'piece', 720.00),
(6, 'Bacon', 1000.000, 'g', 420.00),
(7, 'Egg', 30.000, 'piece', 270.00);

-- --------------------------------------------------------

--
-- Table structure for table `menu_items`
--

CREATE TABLE `menu_items` (
  `menu_item_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(80) NOT NULL,
  `category` varchar(40) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `description` varchar(255) NOT NULL DEFAULT '',
  `icon` varchar(20) NOT NULL DEFAULT '☕',
  `available` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `menu_items`
--

INSERT INTO `menu_items` (`menu_item_id`, `name`, `category`, `price`, `description`, `icon`, `available`) VALUES
(1, 'House Latte', 'Coffee', 145.00, 'Espresso, steamed milk', '☕', 1),
(2, 'Caramel Macchiato', 'Coffee', 165.00, 'Vanilla, caramel drizzle', '🧋', 1),
(3, 'Cold Brew', 'Coffee', 135.00, 'Smooth, slow-steeped coffee', '🥤', 1),
(4, 'Matcha Cloud', 'Non-coffee', 160.00, 'Ceremonial matcha, milk', '🍵', 1),
(5, 'Chocolate Frappe', 'Non-coffee', 175.00, 'Chocolate, cream, cocoa', '🍫', 1),
(6, 'Butter Croissant', 'Pastries', 95.00, 'Flaky and baked fresh', '🥐', 1),
(7, 'Cinnamon Roll', 'Pastries', 110.00, 'Warm cinnamon glaze', '🍥', 1),
(8, 'Bacon & Egg Toast', 'Meals', 210.00, 'Sourdough, egg, bacon', '🍳', 1);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `order_number` varchar(30) NOT NULL,
  `order_date` date NOT NULL,
  `order_time` varchar(12) NOT NULL,
  `order_type` varchar(20) NOT NULL,
  `status` enum('pending','ready','paid') NOT NULL DEFAULT 'pending',
  `payment_method` varchar(20) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  `service_charge` decimal(12,2) NOT NULL,
  `total` decimal(12,2) NOT NULL,
  `amount_received` decimal(12,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `order_item_id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `menu_item_id` bigint(20) UNSIGNED DEFAULT NULL,
  `item_name` varchar(80) NOT NULL,
  `quantity` int(10) UNSIGNED NOT NULL,
  `unit_price` decimal(12,2) NOT NULL,
  `unit_cost` decimal(12,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `recipe_ingredients`
--

CREATE TABLE `recipe_ingredients` (
  `menu_item_id` bigint(20) UNSIGNED NOT NULL,
  `ingredient_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(12,3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `recipe_ingredients`
--

INSERT INTO `recipe_ingredients` (`menu_item_id`, `ingredient_id`, `quantity`) VALUES
(1, 1, 18.000),
(1, 2, 180.000),
(2, 1, 18.000),
(2, 2, 160.000),
(2, 4, 20.000),
(3, 1, 22.000),
(4, 2, 180.000),
(4, 3, 5.000),
(5, 2, 150.000),
(5, 4, 35.000),
(6, 5, 1.000),
(8, 6, 60.000),
(8, 7, 1.000);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ingredients`
--
ALTER TABLE `ingredients`
  ADD PRIMARY KEY (`ingredient_id`);

--
-- Indexes for table `menu_items`
--
ALTER TABLE `menu_items`
  ADD PRIMARY KEY (`menu_item_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD UNIQUE KEY `order_number` (`order_number`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD KEY `fk_items_order` (`order_id`),
  ADD KEY `fk_items_menu` (`menu_item_id`);

--
-- Indexes for table `recipe_ingredients`
--
ALTER TABLE `recipe_ingredients`
  ADD PRIMARY KEY (`menu_item_id`,`ingredient_id`),
  ADD KEY `fk_recipe_ingredient` (`ingredient_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ingredients`
--
ALTER TABLE `ingredients`
  MODIFY `ingredient_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `menu_items`
--
ALTER TABLE `menu_items`
  MODIFY `menu_item_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `order_item_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_items_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`menu_item_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE;

--
-- Constraints for table `recipe_ingredients`
--
ALTER TABLE `recipe_ingredients`
  ADD CONSTRAINT `fk_recipe_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_recipe_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`menu_item_id`) ON DELETE CASCADE;
--
-- Database: `brew_cost`
--
CREATE DATABASE IF NOT EXISTS `brew_cost` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `brew_cost`;

-- --------------------------------------------------------

--
-- Table structure for table `ingredients`
--

CREATE TABLE `ingredients` (
  `ingredient_id` int(10) UNSIGNED NOT NULL,
  `ingredient_name` varchar(100) NOT NULL,
  `unit_of_measure` varchar(20) NOT NULL,
  `price_per_unit` decimal(10,2) NOT NULL,
  `date_updated` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ingredients`
--

INSERT INTO `ingredients` (`ingredient_id`, `ingredient_name`, `unit_of_measure`, `price_per_unit`, `date_updated`) VALUES
(1, 'Coffee Beans (Arabica)', 'g', 1.20, '2026-11-01'),
(2, 'Fresh Milk', 'mL', 0.09, '2026-11-01'),
(3, 'Refined Sugar', 'g', 0.08, '2026-10-28'),
(4, 'Paper Cup 16oz', 'pcs', 3.50, '2026-10-15'),
(5, 'Cup Lid', 'pcs', 1.50, '2026-10-15'),
(6, 'Ice Cubes', 'g', 0.01, '2026-11-01');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `payment_id` int(10) UNSIGNED NOT NULL,
  `sale_id` int(10) UNSIGNED NOT NULL,
  `method` enum('cash','gcash','maya','qr_ph') NOT NULL,
  `amount_paid` decimal(10,2) NOT NULL,
  `scan_reference_no` varchar(20) DEFAULT NULL,
  `proof_image_path` varchar(255) DEFAULT NULL,
  `payer_mobile` varchar(15) DEFAULT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `submitted_by` int(10) UNSIGNED NOT NULL,
  `submitted_at` datetime NOT NULL DEFAULT current_timestamp(),
  `approved_by` int(10) UNSIGNED DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `remarks` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`payment_id`, `sale_id`, `method`, `amount_paid`, `scan_reference_no`, `proof_image_path`, `payer_mobile`, `status`, `submitted_by`, `submitted_at`, `approved_by`, `approved_at`, `remarks`) VALUES
(1, 1, 'gcash', 456.75, '096953352092', 'uploads/proofs/pay_0001.jpg', NULL, 'approved', 2, '2026-11-21 07:46:00', 1, '2026-11-21 07:48:00', NULL),
(2, 2, 'gcash', 336.00, '09695352992', 'uploads/proofs/pay_0002.jpg', NULL, 'approved', 2, '2026-11-23 08:33:00', 1, '2026-11-23 08:35:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `product_id` int(10) UNSIGNED NOT NULL,
  `product_name` varchar(100) NOT NULL,
  `category` varchar(50) NOT NULL DEFAULT 'Beverages',
  `selling_price` decimal(10,2) NOT NULL,
  `date_added` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`product_id`, `product_name`, `category`, `selling_price`, `date_added`) VALUES
(1, 'Cappuccino', 'Beverages', 130.00, '2026-09-01'),
(2, 'Cold Brew', 'Beverages', 140.00, '2026-09-01'),
(3, 'Spanish Latte', 'Beverages', 150.00, '2026-09-01'),
(4, 'Mocha Latte', 'Beverages', 155.00, '2026-09-01'),
(5, 'Caramel Macchiato', 'Beverages', 165.00, '2026-09-01'),
(6, 'Salted Caramel Latte', 'Beverages', 170.00, '2026-09-01');

-- --------------------------------------------------------

--
-- Table structure for table `product_costs`
--

CREATE TABLE `product_costs` (
  `product_id` int(10) UNSIGNED NOT NULL,
  `estimated_ing_cost` decimal(10,2) NOT NULL DEFAULT 0.00,
  `gross_profit_per_unit` decimal(10,2) NOT NULL DEFAULT 0.00,
  `gross_margin_pct` decimal(5,2) NOT NULL DEFAULT 0.00,
  `last_computed_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `product_costs`
--

INSERT INTO `product_costs` (`product_id`, `estimated_ing_cost`, `gross_profit_per_unit`, `gross_margin_pct`, `last_computed_at`) VALUES
(1, 37.80, 92.20, 70.92, '2026-11-23 21:56:50'),
(2, 32.60, 107.40, 76.71, '2026-11-23 21:56:50'),
(3, 41.30, 108.70, 72.47, '2026-11-23 21:56:50'),
(4, 44.10, 110.90, 71.55, '2026-11-23 21:56:50'),
(5, 46.90, 118.10, 71.58, '2026-11-23 21:56:50'),
(6, 48.20, 121.80, 71.65, '2026-11-23 21:56:50');

-- --------------------------------------------------------

--
-- Table structure for table `recipe_items`
--

CREATE TABLE `recipe_items` (
  `recipe_item_id` int(10) UNSIGNED NOT NULL,
  `product_id` int(10) UNSIGNED NOT NULL,
  `ingredient_id` int(10) UNSIGNED NOT NULL,
  `quantity_required` decimal(10,3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `recipe_items`
--

INSERT INTO `recipe_items` (`recipe_item_id`, `product_id`, `ingredient_id`, `quantity_required`) VALUES
(1, 1, 1, 18.000),
(2, 1, 2, 120.000),
(3, 1, 3, 5.000),
(4, 1, 4, 1.000),
(5, 2, 1, 22.000),
(6, 2, 4, 1.000),
(7, 2, 5, 1.000),
(8, 2, 6, 120.000),
(9, 6, 1, 18.000),
(10, 6, 2, 150.000),
(11, 6, 3, 8.000),
(12, 6, 4, 1.000);

-- --------------------------------------------------------

--
-- Table structure for table `sales`
--

CREATE TABLE `sales` (
  `sale_id` int(10) UNSIGNED NOT NULL,
  `sale_date` datetime NOT NULL DEFAULT current_timestamp(),
  `order_type` enum('Dine in','Take out') NOT NULL DEFAULT 'Dine in',
  `total_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `service_charge` decimal(10,2) NOT NULL DEFAULT 0.00,
  `recorded_by` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sales`
--

INSERT INTO `sales` (`sale_id`, `sale_date`, `order_type`, `total_amount`, `service_charge`, `recorded_by`) VALUES
(1, '2026-11-21 07:46:00', 'Dine in', 456.75, 21.75, 2),
(2, '2026-11-23 08:33:00', 'Dine in', 336.00, 16.00, 2);

-- --------------------------------------------------------

--
-- Table structure for table `sale_items`
--

CREATE TABLE `sale_items` (
  `sale_item_id` int(10) UNSIGNED NOT NULL,
  `sale_id` int(10) UNSIGNED NOT NULL,
  `product_id` int(10) UNSIGNED NOT NULL,
  `quantity` int(10) UNSIGNED NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `line_total` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sale_items`
--

INSERT INTO `sale_items` (`sale_item_id`, `sale_id`, `product_id`, `quantity`, `unit_price`, `line_total`) VALUES
(1, 1, 1, 1, 130.00, 130.00),
(2, 1, 5, 1, 165.00, 165.00),
(3, 1, 2, 1, 140.00, 140.00),
(4, 2, 6, 1, 170.00, 170.00),
(5, 2, 3, 1, 150.00, 150.00);

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `setting_id` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `merchant_qr_image_path` varchar(255) DEFAULT NULL,
  `merchant_name` varchar(100) DEFAULT NULL,
  `wallet_number` varchar(20) DEFAULT NULL,
  `network` enum('gcash','maya','qr_ph') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `system_settings`
--

INSERT INTO `system_settings` (`setting_id`, `merchant_qr_image_path`, `merchant_name`, `wallet_number`, `network`) VALUES
(1, NULL, 'Brew Haven Cafe', '0917 000 0000', 'gcash');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `role` enum('administrator','staff') NOT NULL DEFAULT 'staff',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password_hash`, `full_name`, `role`, `created_at`) VALUES
(1, 'admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Cafe Administrator', 'administrator', '2026-11-23 13:56:50'),
(2, 'staff01', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Jomari Tupaz', 'staff', '2026-11-23 13:56:50');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ingredients`
--
ALTER TABLE `ingredients`
  ADD PRIMARY KEY (`ingredient_id`),
  ADD UNIQUE KEY `uq_ingredients_name` (`ingredient_name`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD UNIQUE KEY `uq_payments_ref` (`scan_reference_no`),
  ADD KEY `fk_pay_sale` (`sale_id`),
  ADD KEY `fk_pay_submitted` (`submitted_by`),
  ADD KEY `fk_pay_approved` (`approved_by`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_id`),
  ADD UNIQUE KEY `uq_products_name` (`product_name`);

--
-- Indexes for table `product_costs`
--
ALTER TABLE `product_costs`
  ADD PRIMARY KEY (`product_id`);

--
-- Indexes for table `recipe_items`
--
ALTER TABLE `recipe_items`
  ADD PRIMARY KEY (`recipe_item_id`),
  ADD UNIQUE KEY `uq_recipe_prod_ing` (`product_id`,`ingredient_id`),
  ADD KEY `fk_recipe_ingredient` (`ingredient_id`);

--
-- Indexes for table `sales`
--
ALTER TABLE `sales`
  ADD PRIMARY KEY (`sale_id`),
  ADD KEY `fk_sales_user` (`recorded_by`);

--
-- Indexes for table `sale_items`
--
ALTER TABLE `sale_items`
  ADD PRIMARY KEY (`sale_item_id`),
  ADD KEY `fk_si_sale` (`sale_id`),
  ADD KEY `fk_si_product` (`product_id`);

--
-- Indexes for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`setting_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_users_username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ingredients`
--
ALTER TABLE `ingredients`
  MODIFY `ingredient_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `product_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `recipe_items`
--
ALTER TABLE `recipe_items`
  MODIFY `recipe_item_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `sales`
--
ALTER TABLE `sales`
  MODIFY `sale_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `sale_items`
--
ALTER TABLE `sale_items`
  MODIFY `sale_item_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `fk_pay_approved` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pay_sale` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`sale_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pay_submitted` FOREIGN KEY (`submitted_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `product_costs`
--
ALTER TABLE `product_costs`
  ADD CONSTRAINT `fk_cost_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `recipe_items`
--
ALTER TABLE `recipe_items`
  ADD CONSTRAINT `fk_recipe_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_recipe_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `sales`
--
ALTER TABLE `sales`
  ADD CONSTRAINT `fk_sales_user` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `sale_items`
--
ALTER TABLE `sale_items`
  ADD CONSTRAINT `fk_si_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_si_sale` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`sale_id`) ON DELETE CASCADE ON UPDATE CASCADE;
--
-- Database: `phpmyadmin`
--
CREATE DATABASE IF NOT EXISTS `phpmyadmin` DEFAULT CHARACTER SET utf8mb3 COLLATE utf8mb3_bin;
USE `phpmyadmin`;

-- --------------------------------------------------------

--
-- Table structure for table `pma__bookmark`
--

CREATE TABLE `pma__bookmark` (
  `id` int(10) UNSIGNED NOT NULL,
  `dbase` varchar(255) NOT NULL DEFAULT '',
  `user` varchar(255) NOT NULL DEFAULT '',
  `label` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '',
  `query` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Bookmarks';

-- --------------------------------------------------------

--
-- Table structure for table `pma__central_columns`
--

CREATE TABLE `pma__central_columns` (
  `db_name` varchar(64) NOT NULL,
  `col_name` varchar(64) NOT NULL,
  `col_type` varchar(64) NOT NULL,
  `col_length` text DEFAULT NULL,
  `col_collation` varchar(64) NOT NULL,
  `col_isNull` tinyint(1) NOT NULL,
  `col_extra` varchar(255) DEFAULT '',
  `col_default` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Central list of columns';

-- --------------------------------------------------------

--
-- Table structure for table `pma__column_info`
--

CREATE TABLE `pma__column_info` (
  `id` int(5) UNSIGNED NOT NULL,
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `table_name` varchar(64) NOT NULL DEFAULT '',
  `column_name` varchar(64) NOT NULL DEFAULT '',
  `comment` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '',
  `mimetype` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '',
  `transformation` varchar(255) NOT NULL DEFAULT '',
  `transformation_options` varchar(255) NOT NULL DEFAULT '',
  `input_transformation` varchar(255) NOT NULL DEFAULT '',
  `input_transformation_options` varchar(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Column information for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__designer_settings`
--

CREATE TABLE `pma__designer_settings` (
  `username` varchar(64) NOT NULL,
  `settings_data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Settings related to Designer';

-- --------------------------------------------------------

--
-- Table structure for table `pma__export_templates`
--

CREATE TABLE `pma__export_templates` (
  `id` int(5) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL,
  `export_type` varchar(10) NOT NULL,
  `template_name` varchar(64) NOT NULL,
  `template_data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Saved export templates';

-- --------------------------------------------------------

--
-- Table structure for table `pma__favorite`
--

CREATE TABLE `pma__favorite` (
  `username` varchar(64) NOT NULL,
  `tables` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Favorite tables';

-- --------------------------------------------------------

--
-- Table structure for table `pma__history`
--

CREATE TABLE `pma__history` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `db` varchar(64) NOT NULL DEFAULT '',
  `table` varchar(64) NOT NULL DEFAULT '',
  `timevalue` timestamp NOT NULL DEFAULT current_timestamp(),
  `sqlquery` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='SQL history for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__navigationhiding`
--

CREATE TABLE `pma__navigationhiding` (
  `username` varchar(64) NOT NULL,
  `item_name` varchar(64) NOT NULL,
  `item_type` varchar(64) NOT NULL,
  `db_name` varchar(64) NOT NULL,
  `table_name` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Hidden items of navigation tree';

-- --------------------------------------------------------

--
-- Table structure for table `pma__pdf_pages`
--

CREATE TABLE `pma__pdf_pages` (
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `page_nr` int(10) UNSIGNED NOT NULL,
  `page_descr` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='PDF relation pages for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__recent`
--

CREATE TABLE `pma__recent` (
  `username` varchar(64) NOT NULL,
  `tables` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Recently accessed tables';

--
-- Dumping data for table `pma__recent`
--

INSERT INTO `pma__recent` (`username`, `tables`) VALUES
('root', '[{\"db\":\"brew_cost\",\"table\":\"payments\"},{\"db\":\"pos_db\",\"table\":\"ingredients\"},{\"db\":\"information_schema\",\"table\":\"TABLES\"},{\"db\":\"pos_db\",\"table\":\"staff\"},{\"db\":\"pos_db\",\"table\":\"order_items\"},{\"db\":\"pos_db\",\"table\":\"recipes\"},{\"db\":\"pos_db\",\"table\":\"orders\"},{\"db\":\"pos_db\",\"table\":\"menu_items\"},{\"db\":\"phpmyadmin\",\"table\":\"pma__table_coords\"},{\"db\":\"phpmyadmin\",\"table\":\"pma__history\"}]');

-- --------------------------------------------------------

--
-- Table structure for table `pma__relation`
--

CREATE TABLE `pma__relation` (
  `master_db` varchar(64) NOT NULL DEFAULT '',
  `master_table` varchar(64) NOT NULL DEFAULT '',
  `master_field` varchar(64) NOT NULL DEFAULT '',
  `foreign_db` varchar(64) NOT NULL DEFAULT '',
  `foreign_table` varchar(64) NOT NULL DEFAULT '',
  `foreign_field` varchar(64) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Relation table';

-- --------------------------------------------------------

--
-- Table structure for table `pma__savedsearches`
--

CREATE TABLE `pma__savedsearches` (
  `id` int(5) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `search_name` varchar(64) NOT NULL DEFAULT '',
  `search_data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Saved searches';

-- --------------------------------------------------------

--
-- Table structure for table `pma__table_coords`
--

CREATE TABLE `pma__table_coords` (
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `table_name` varchar(64) NOT NULL DEFAULT '',
  `pdf_page_number` int(11) NOT NULL DEFAULT 0,
  `x` float UNSIGNED NOT NULL DEFAULT 0,
  `y` float UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Table coordinates for phpMyAdmin PDF output';

-- --------------------------------------------------------

--
-- Table structure for table `pma__table_info`
--

CREATE TABLE `pma__table_info` (
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `table_name` varchar(64) NOT NULL DEFAULT '',
  `display_field` varchar(64) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Table information for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__table_uiprefs`
--

CREATE TABLE `pma__table_uiprefs` (
  `username` varchar(64) NOT NULL,
  `db_name` varchar(64) NOT NULL,
  `table_name` varchar(64) NOT NULL,
  `prefs` text NOT NULL,
  `last_update` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Tables'' UI preferences';

-- --------------------------------------------------------

--
-- Table structure for table `pma__tracking`
--

CREATE TABLE `pma__tracking` (
  `db_name` varchar(64) NOT NULL,
  `table_name` varchar(64) NOT NULL,
  `version` int(10) UNSIGNED NOT NULL,
  `date_created` datetime NOT NULL,
  `date_updated` datetime NOT NULL,
  `schema_snapshot` text NOT NULL,
  `schema_sql` text DEFAULT NULL,
  `data_sql` longtext DEFAULT NULL,
  `tracking` set('UPDATE','REPLACE','INSERT','DELETE','TRUNCATE','CREATE DATABASE','ALTER DATABASE','DROP DATABASE','CREATE TABLE','ALTER TABLE','RENAME TABLE','DROP TABLE','CREATE INDEX','DROP INDEX','CREATE VIEW','ALTER VIEW','DROP VIEW') DEFAULT NULL,
  `tracking_active` int(1) UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Database changes tracking for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__userconfig`
--

CREATE TABLE `pma__userconfig` (
  `username` varchar(64) NOT NULL,
  `timevalue` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `config_data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='User preferences storage for phpMyAdmin';

--
-- Dumping data for table `pma__userconfig`
--

INSERT INTO `pma__userconfig` (`username`, `timevalue`, `config_data`) VALUES
('root', '2026-11-28 06:38:30', '{\"Console\\/Mode\":\"collapse\"}');

-- --------------------------------------------------------

--
-- Table structure for table `pma__usergroups`
--

CREATE TABLE `pma__usergroups` (
  `usergroup` varchar(64) NOT NULL,
  `tab` varchar(64) NOT NULL,
  `allowed` enum('Y','N') NOT NULL DEFAULT 'N'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='User groups with configured menu items';

-- --------------------------------------------------------

--
-- Table structure for table `pma__users`
--

CREATE TABLE `pma__users` (
  `username` varchar(64) NOT NULL,
  `usergroup` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin COMMENT='Users and their assignments to user groups';

--
-- Indexes for dumped tables
--

--
-- Indexes for table `pma__bookmark`
--
ALTER TABLE `pma__bookmark`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pma__central_columns`
--
ALTER TABLE `pma__central_columns`
  ADD PRIMARY KEY (`db_name`,`col_name`);

--
-- Indexes for table `pma__column_info`
--
ALTER TABLE `pma__column_info`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `db_name` (`db_name`,`table_name`,`column_name`);

--
-- Indexes for table `pma__designer_settings`
--
ALTER TABLE `pma__designer_settings`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `pma__export_templates`
--
ALTER TABLE `pma__export_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `u_user_type_template` (`username`,`export_type`,`template_name`);

--
-- Indexes for table `pma__favorite`
--
ALTER TABLE `pma__favorite`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `pma__history`
--
ALTER TABLE `pma__history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`,`db`,`table`,`timevalue`);

--
-- Indexes for table `pma__navigationhiding`
--
ALTER TABLE `pma__navigationhiding`
  ADD PRIMARY KEY (`username`,`item_name`,`item_type`,`db_name`,`table_name`);

--
-- Indexes for table `pma__pdf_pages`
--
ALTER TABLE `pma__pdf_pages`
  ADD PRIMARY KEY (`page_nr`),
  ADD KEY `db_name` (`db_name`);

--
-- Indexes for table `pma__recent`
--
ALTER TABLE `pma__recent`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `pma__relation`
--
ALTER TABLE `pma__relation`
  ADD PRIMARY KEY (`master_db`,`master_table`,`master_field`),
  ADD KEY `foreign_field` (`foreign_db`,`foreign_table`);

--
-- Indexes for table `pma__savedsearches`
--
ALTER TABLE `pma__savedsearches`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `u_savedsearches_username_dbname` (`username`,`db_name`,`search_name`);

--
-- Indexes for table `pma__table_coords`
--
ALTER TABLE `pma__table_coords`
  ADD PRIMARY KEY (`db_name`,`table_name`,`pdf_page_number`);

--
-- Indexes for table `pma__table_info`
--
ALTER TABLE `pma__table_info`
  ADD PRIMARY KEY (`db_name`,`table_name`);

--
-- Indexes for table `pma__table_uiprefs`
--
ALTER TABLE `pma__table_uiprefs`
  ADD PRIMARY KEY (`username`,`db_name`,`table_name`);

--
-- Indexes for table `pma__tracking`
--
ALTER TABLE `pma__tracking`
  ADD PRIMARY KEY (`db_name`,`table_name`,`version`);

--
-- Indexes for table `pma__userconfig`
--
ALTER TABLE `pma__userconfig`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `pma__usergroups`
--
ALTER TABLE `pma__usergroups`
  ADD PRIMARY KEY (`usergroup`,`tab`,`allowed`);

--
-- Indexes for table `pma__users`
--
ALTER TABLE `pma__users`
  ADD PRIMARY KEY (`username`,`usergroup`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `pma__bookmark`
--
ALTER TABLE `pma__bookmark`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__column_info`
--
ALTER TABLE `pma__column_info`
  MODIFY `id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__export_templates`
--
ALTER TABLE `pma__export_templates`
  MODIFY `id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__history`
--
ALTER TABLE `pma__history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__pdf_pages`
--
ALTER TABLE `pma__pdf_pages`
  MODIFY `page_nr` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__savedsearches`
--
ALTER TABLE `pma__savedsearches`
  MODIFY `id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT;
--
-- Database: `pos_db`
--
CREATE DATABASE IF NOT EXISTS `pos_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `pos_db`;

-- --------------------------------------------------------

--
-- Table structure for table `ingredients`
--

CREATE TABLE `ingredients` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(80) NOT NULL,
  `unit` varchar(20) NOT NULL DEFAULT 'g',
  `purchase_qty` decimal(12,3) NOT NULL,
  `purchase_price` decimal(10,2) NOT NULL,
  `stock` decimal(12,3) NOT NULL DEFAULT 0.000,
  `reorder_level` decimal(12,3) NOT NULL DEFAULT 0.000,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ingredients`
--

INSERT INTO `ingredients` (`id`, `name`, `unit`, `purchase_qty`, `purchase_price`, `stock`, `reorder_level`, `updated_at`) VALUES
(1, 'Espresso beans', 'g', 1000.000, 850.00, 590.000, 200.000, '2026-11-26 06:54:48'),
(2, 'Fresh milk', 'ml', 1000.000, 95.00, 1150.000, 250.000, '2026-11-26 06:55:32'),
(3, 'Condensed milk', 'ml', 1000.000, 120.00, 720.000, 250.000, '2026-11-25 07:19:06'),
(4, 'Chocolate sauce', 'ml', 750.000, 300.00, 460.000, 150.000, '2026-11-25 04:18:13'),
(5, 'White chocolate sauce', 'ml', 750.000, 330.00, 360.000, 150.000, '2026-11-25 04:18:13'),
(6, 'Sea salt', 'g', 250.000, 45.00, 197.000, 50.000, '2026-11-25 07:19:06'),
(7, 'Whipped cream', 'ml', 500.000, 180.00, 180.000, 100.000, '2026-11-25 11:10:09'),
(8, 'Cinnamon powder', 'g', 100.000, 60.00, 87.000, 25.000, '2026-11-25 11:10:09'),
(19, 'Vanilla syrup', 'ml', 750.000, 320.00, 349.000, 150.000, '2026-11-25 11:10:09'),
(20, 'Caramel sauce', 'ml', 750.000, 340.00, 445.000, 100.000, '2026-11-25 11:10:09');

-- --------------------------------------------------------

--
-- Table structure for table `menu_items`
--

CREATE TABLE `menu_items` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(80) NOT NULL,
  `category` varchar(40) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `description` varchar(120) NOT NULL DEFAULT '',
  `icon` varchar(16) NOT NULL DEFAULT '☕',
  `available` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `menu_items`
--

INSERT INTO `menu_items` (`id`, `name`, `category`, `price`, `description`, `icon`, `available`, `created_at`) VALUES
(1, 'Spanish Latte', 'Coffee', 150.00, 'Sweet condensed milk espresso', '☕', 1, '2026-11-25 04:02:21'),
(2, 'Cappuccino', 'Coffee', 130.00, 'Espresso with steamed milk foam', '☕', 1, '2026-11-25 04:02:21'),
(3, 'Americano', 'Coffee', 110.00, 'Double shot with hot water', '☕', 1, '2026-11-25 04:02:21'),
(4, 'Café Latte', 'Coffee', 125.00, 'Smooth espresso and silky milk', '☕', 1, '2026-11-25 04:02:21'),
(5, 'Caramel Macchiato', 'Coffee', 165.00, 'Vanilla, milk, caramel drizzle', '🍮', 1, '2026-11-25 04:02:21'),
(6, 'Cold Brew', 'Coffee', 140.00, '18-hour steeped, served iced', '🧊', 1, '2026-11-25 04:02:21'),
(7, 'Mocha Latte', 'Coffee', 155.00, 'Espresso, chocolate and steamed milk', '🍫', 1, '2026-11-25 04:02:21'),
(8, 'White Mocha', 'Coffee', 160.00, 'White chocolate and espresso', '🤍', 1, '2026-11-25 04:02:21'),
(9, 'Salted Caramel Latte', 'Coffee', 170.00, 'Caramel, milk and a pinch of sea salt', '🧂', 1, '2026-11-25 04:02:21'),
(10, 'Vanilla Cold Brew', 'Coffee', 150.00, 'Cold brew, vanilla, splash of milk', '🍦', 1, '2026-11-25 04:02:21'),
(11, 'Espresso', 'Coffee', 95.00, 'Double shot, straight up', '⚡', 1, '2026-11-25 04:02:21'),
(12, 'Macchiato', 'Coffee', 120.00, 'Espresso marked with milk foam', '🥛', 1, '2026-11-25 04:02:21');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` int(10) UNSIGNED NOT NULL,
  `number` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'Dine in',
  `status` enum('pending','ready','paid','cancelled') NOT NULL DEFAULT 'pending',
  `payment` varchar(20) DEFAULT NULL,
  `payment_ref` varchar(40) DEFAULT NULL,
  `received` decimal(10,2) DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `order_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `number`, `type`, `status`, `payment`, `payment_ref`, `received`, `subtotal`, `total`, `order_date`, `created_at`) VALUES
(1, '01', 'Dine in', 'paid', 'GCash', '09695352992', NULL, 1670.00, 1753.50, '2026-11-25', '2026-11-25 04:18:13'),
(2, '02', 'Dine in', 'paid', 'Card', '2443 499', NULL, 335.00, 351.75, '2026-11-25', '2026-11-25 04:21:00'),
(3, '03', 'Dine in', 'paid', 'Cash', NULL, 1000.00, 550.00, 577.50, '2026-11-25', '2026-11-25 04:30:02'),
(4, '04', 'Dine in', 'paid', 'Cash', NULL, 1000.00, 765.00, 803.25, '2026-11-25', '2026-11-25 04:32:07'),
(5, '05', 'Dine in', 'paid', 'GCash', '09695352992', NULL, 320.00, 336.00, '2026-11-25', '2026-11-25 07:19:06'),
(6, '06', 'Dine in', 'paid', 'Cash', NULL, 1000.00, 670.00, 703.50, '2026-11-25', '2026-11-25 11:10:09'),
(7, '07', 'Dine in', 'paid', 'GCash', '09695352992', NULL, 235.00, 246.75, '2026-11-26', '2026-11-26 06:54:48');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `id` int(10) UNSIGNED NOT NULL,
  `order_id` int(10) UNSIGNED NOT NULL,
  `menu_item_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(80) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `qty` int(10) UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `menu_item_id`, `name`, `price`, `qty`) VALUES
(1, 1, 3, 'Americano', 110.00, 1),
(2, 1, 4, 'Café Latte', 125.00, 1),
(3, 1, 2, 'Cappuccino', 130.00, 1),
(4, 1, 5, 'Caramel Macchiato', 165.00, 1),
(5, 1, 6, 'Cold Brew', 140.00, 1),
(6, 1, 11, 'Espresso', 95.00, 1),
(7, 1, 12, 'Macchiato', 120.00, 1),
(8, 1, 7, 'Mocha Latte', 155.00, 1),
(9, 1, 9, 'Salted Caramel Latte', 170.00, 1),
(10, 1, 1, 'Spanish Latte', 150.00, 1),
(11, 1, 10, 'Vanilla Cold Brew', 150.00, 1),
(12, 1, 8, 'White Mocha', 160.00, 1),
(13, 2, 5, 'Caramel Macchiato', 165.00, 1),
(14, 2, 9, 'Salted Caramel Latte', 170.00, 1),
(15, 3, 3, 'Americano', 110.00, 5),
(16, 4, 3, 'Americano', 110.00, 1),
(17, 4, 4, 'Café Latte', 125.00, 1),
(18, 4, 2, 'Cappuccino', 130.00, 1),
(19, 4, 5, 'Caramel Macchiato', 165.00, 1),
(20, 4, 6, 'Cold Brew', 140.00, 1),
(21, 4, 11, 'Espresso', 95.00, 1),
(22, 5, 9, 'Salted Caramel Latte', 170.00, 1),
(23, 5, 1, 'Spanish Latte', 150.00, 1),
(24, 6, 3, 'Americano', 110.00, 1),
(25, 6, 4, 'Café Latte', 125.00, 1),
(26, 6, 2, 'Cappuccino', 130.00, 1),
(27, 6, 5, 'Caramel Macchiato', 165.00, 1),
(28, 6, 6, 'Cold Brew', 140.00, 1),
(29, 7, 3, 'Americano', 110.00, 1),
(30, 7, 4, 'Café Latte', 125.00, 1);

-- --------------------------------------------------------

--
-- Table structure for table `recipes`
--

CREATE TABLE `recipes` (
  `id` int(10) UNSIGNED NOT NULL,
  `menu_item_id` int(10) UNSIGNED NOT NULL,
  `ingredient_id` int(10) UNSIGNED NOT NULL,
  `quantity` decimal(12,3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `recipes`
--

INSERT INTO `recipes` (`id`, `menu_item_id`, `ingredient_id`, `quantity`) VALUES
(1, 1, 1, 18.000),
(2, 1, 2, 120.000),
(3, 1, 3, 40.000),
(4, 1, 19, 8.000),
(5, 2, 1, 18.000),
(6, 2, 2, 120.000),
(7, 2, 8, 1.000),
(8, 3, 1, 18.000),
(9, 4, 1, 18.000),
(10, 4, 2, 180.000),
(11, 5, 1, 18.000),
(12, 5, 2, 150.000),
(13, 5, 20, 20.000),
(14, 5, 19, 10.000),
(15, 5, 7, 20.000),
(16, 6, 1, 30.000),
(17, 7, 1, 18.000),
(18, 7, 2, 150.000),
(19, 7, 4, 20.000),
(20, 7, 7, 20.000),
(21, 8, 1, 18.000),
(22, 8, 2, 150.000),
(23, 8, 5, 20.000),
(24, 8, 7, 20.000),
(25, 9, 1, 18.000),
(26, 9, 2, 150.000),
(27, 9, 20, 20.000),
(28, 9, 6, 1.000),
(29, 10, 1, 30.000),
(30, 10, 19, 15.000),
(31, 10, 2, 60.000),
(32, 11, 1, 18.000),
(33, 12, 1, 18.000),
(34, 12, 2, 60.000);

-- --------------------------------------------------------

--
-- Table structure for table `staff`
--

CREATE TABLE `staff` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(60) NOT NULL,
  `username` varchar(60) DEFAULT NULL,
  `password_hash` varchar(255) DEFAULT NULL,
  `access_code_hash` varchar(255) DEFAULT NULL,
  `role` enum('admin','cashier') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `staff`
--

INSERT INTO `staff` (`id`, `name`, `username`, `password_hash`, `access_code_hash`, `role`, `created_at`) VALUES
(1, 'Admin', 'admin', '$2y$12$2qQdVH8LDPniX7FdY6sTEuYS6tDC40NdRGT3NZgV16lLmJvyhePrK', NULL, 'admin', '2026-11-25 04:02:21'),
(2, 'Front Counter', NULL, NULL, '$2y$12$B.59FjjVYdt.tdFqP/EFauyuAbiEkIkTVKivmz6QIJBO5jBgKNZ2q', 'cashier', '2026-11-25 04:02:21');

-- --------------------------------------------------------

--
-- Table structure for table `stock_movements`
--

CREATE TABLE `stock_movements` (
  `id` int(10) UNSIGNED NOT NULL,
  `ingredient_id` int(10) UNSIGNED NOT NULL,
  `change` decimal(12,3) NOT NULL,
  `reason` varchar(60) NOT NULL,
  `order_id` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stock_movements`
--

INSERT INTO `stock_movements` (`id`, `ingredient_id`, `change`, `reason`, `order_id`, `created_at`) VALUES
(1, 1, -180.000, 'order', NULL, '2026-11-25 01:02:21'),
(2, 2, -600.000, 'order', NULL, '2026-11-25 01:02:21'),
(3, 1, 750.000, 'restock', NULL, '2026-11-24 04:02:21'),
(4, 20, -40.000, 'order', NULL, '2026-11-25 02:02:21'),
(5, 19, -25.000, 'order', NULL, '2026-11-24 23:02:21'),
(6, 3, -160.000, 'order', NULL, '2026-11-25 01:02:21'),
(7, 4, -80.000, 'order', NULL, '2026-11-25 02:02:21'),
(8, 5, -60.000, 'order', NULL, '2026-11-25 02:02:21'),
(9, 7, -100.000, 'order', NULL, '2026-11-25 02:32:21'),
(10, 3, 800.000, 'restock', NULL, '2026-11-23 04:02:21'),
(11, 4, 750.000, 'restock', NULL, '2026-11-23 04:02:21'),
(12, 8, 90.000, 'restock', NULL, '2026-11-21 04:02:21'),
(13, 20, 500.000, 'restock', NULL, '2026-11-25 04:17:20'),
(14, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(15, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(16, 2, -180.000, 'order', 1, '2026-11-25 04:18:13'),
(17, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(18, 2, -120.000, 'order', 1, '2026-11-25 04:18:13'),
(19, 8, -1.000, 'order', 1, '2026-11-25 04:18:13'),
(20, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(21, 2, -150.000, 'order', 1, '2026-11-25 04:18:13'),
(22, 7, -20.000, 'order', 1, '2026-11-25 04:18:13'),
(23, 19, -10.000, 'order', 1, '2026-11-25 04:18:13'),
(24, 20, -20.000, 'order', 1, '2026-11-25 04:18:13'),
(25, 1, -30.000, 'order', 1, '2026-11-25 04:18:13'),
(26, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(27, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(28, 2, -60.000, 'order', 1, '2026-11-25 04:18:13'),
(29, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(30, 2, -150.000, 'order', 1, '2026-11-25 04:18:13'),
(31, 4, -20.000, 'order', 1, '2026-11-25 04:18:13'),
(32, 7, -20.000, 'order', 1, '2026-11-25 04:18:13'),
(33, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(34, 2, -150.000, 'order', 1, '2026-11-25 04:18:13'),
(35, 6, -1.000, 'order', 1, '2026-11-25 04:18:13'),
(36, 20, -20.000, 'order', 1, '2026-11-25 04:18:13'),
(37, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(38, 2, -120.000, 'order', 1, '2026-11-25 04:18:13'),
(39, 3, -40.000, 'order', 1, '2026-11-25 04:18:13'),
(40, 19, -8.000, 'order', 1, '2026-11-25 04:18:13'),
(41, 1, -30.000, 'order', 1, '2026-11-25 04:18:13'),
(42, 2, -60.000, 'order', 1, '2026-11-25 04:18:13'),
(43, 19, -15.000, 'order', 1, '2026-11-25 04:18:13'),
(44, 1, -18.000, 'order', 1, '2026-11-25 04:18:13'),
(45, 2, -150.000, 'order', 1, '2026-11-25 04:18:13'),
(46, 5, -20.000, 'order', 1, '2026-11-25 04:18:13'),
(47, 7, -20.000, 'order', 1, '2026-11-25 04:18:13'),
(48, 1, -18.000, 'order', 2, '2026-11-25 04:21:00'),
(49, 2, -150.000, 'order', 2, '2026-11-25 04:21:00'),
(50, 7, -20.000, 'order', 2, '2026-11-25 04:21:00'),
(51, 19, -10.000, 'order', 2, '2026-11-25 04:21:00'),
(52, 20, -20.000, 'order', 2, '2026-11-25 04:21:00'),
(53, 1, -18.000, 'order', 2, '2026-11-25 04:21:00'),
(54, 2, -150.000, 'order', 2, '2026-11-25 04:21:00'),
(55, 6, -1.000, 'order', 2, '2026-11-25 04:21:00'),
(56, 20, -20.000, 'order', 2, '2026-11-25 04:21:00'),
(57, 2, 500.000, 'restock', NULL, '2026-11-25 04:22:00'),
(58, 1, -90.000, 'order', 3, '2026-11-25 04:30:02'),
(59, 1, -18.000, 'order', 4, '2026-11-25 04:32:07'),
(60, 1, -18.000, 'order', 4, '2026-11-25 04:32:07'),
(61, 2, -180.000, 'order', 4, '2026-11-25 04:32:07'),
(62, 1, -18.000, 'order', 4, '2026-11-25 04:32:07'),
(63, 2, -120.000, 'order', 4, '2026-11-25 04:32:07'),
(64, 8, -1.000, 'order', 4, '2026-11-25 04:32:07'),
(65, 1, -18.000, 'order', 4, '2026-11-25 04:32:07'),
(66, 2, -150.000, 'order', 4, '2026-11-25 04:32:07'),
(67, 7, -20.000, 'order', 4, '2026-11-25 04:32:07'),
(68, 19, -10.000, 'order', 4, '2026-11-25 04:32:07'),
(69, 20, -20.000, 'order', 4, '2026-11-25 04:32:07'),
(70, 1, -30.000, 'order', 4, '2026-11-25 04:32:07'),
(71, 1, -18.000, 'order', 4, '2026-11-25 04:32:07'),
(72, 1, 500.000, 'restock', NULL, '2026-11-25 07:18:25'),
(73, 2, 500.000, 'restock', NULL, '2026-11-25 07:18:29'),
(74, 2, 500.000, 'restock', NULL, '2026-11-25 07:18:32'),
(75, 1, -18.000, 'order', 5, '2026-11-25 07:19:06'),
(76, 2, -150.000, 'order', 5, '2026-11-25 07:19:06'),
(77, 6, -1.000, 'order', 5, '2026-11-25 07:19:06'),
(78, 20, -20.000, 'order', 5, '2026-11-25 07:19:06'),
(79, 1, -18.000, 'order', 5, '2026-11-25 07:19:06'),
(80, 2, -120.000, 'order', 5, '2026-11-25 07:19:06'),
(81, 3, -40.000, 'order', 5, '2026-11-25 07:19:06'),
(82, 19, -8.000, 'order', 5, '2026-11-25 07:19:06'),
(83, 1, -18.000, 'order', 6, '2026-11-25 11:10:09'),
(84, 1, -18.000, 'order', 6, '2026-11-25 11:10:09'),
(85, 2, -180.000, 'order', 6, '2026-11-25 11:10:09'),
(86, 1, -18.000, 'order', 6, '2026-11-25 11:10:09'),
(87, 2, -120.000, 'order', 6, '2026-11-25 11:10:09'),
(88, 8, -1.000, 'order', 6, '2026-11-25 11:10:09'),
(89, 1, -18.000, 'order', 6, '2026-11-25 11:10:09'),
(90, 2, -150.000, 'order', 6, '2026-11-25 11:10:09'),
(91, 7, -20.000, 'order', 6, '2026-11-25 11:10:09'),
(92, 19, -10.000, 'order', 6, '2026-11-25 11:10:09'),
(93, 20, -20.000, 'order', 6, '2026-11-25 11:10:09'),
(94, 1, -30.000, 'order', 6, '2026-11-25 11:10:09'),
(95, 1, -18.000, 'order', 7, '2026-11-26 06:54:48'),
(96, 1, -18.000, 'order', 7, '2026-11-26 06:54:48'),
(97, 2, -180.000, 'order', 7, '2026-11-26 06:54:48'),
(98, 2, 500.000, 'restock', NULL, '2026-11-26 06:55:29'),
(99, 2, 500.000, 'restock', NULL, '2026-11-26 06:55:32');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ingredients`
--
ALTER TABLE `ingredients`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `menu_items`
--
ALTER TABLE `menu_items`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_oi_order` (`order_id`),
  ADD KEY `fk_oi_menu` (`menu_item_id`);

--
-- Indexes for table `recipes`
--
ALTER TABLE `recipes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_recipe` (`menu_item_id`,`ingredient_id`),
  ADD KEY `fk_r_ing` (`ingredient_id`);

--
-- Indexes for table `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_m_ing` (`ingredient_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ingredients`
--
ALTER TABLE `ingredients`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `menu_items`
--
ALTER TABLE `menu_items`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `recipes`
--
ALTER TABLE `recipes`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `staff`
--
ALTER TABLE `staff`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `stock_movements`
--
ALTER TABLE `stock_movements`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=100;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_oi_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`),
  ADD CONSTRAINT `fk_oi_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `recipes`
--
ALTER TABLE `recipes`
  ADD CONSTRAINT `fk_r_ing` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_r_menu` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD CONSTRAINT `fk_m_ing` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`id`) ON DELETE CASCADE;
--
-- Database: `pos_order_inventory`
--
CREATE DATABASE IF NOT EXISTS `pos_order_inventory` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `pos_order_inventory`;

-- --------------------------------------------------------

--
-- Table structure for table `ingredients`
--

CREATE TABLE `ingredients` (
  `ingredient_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `quantity` decimal(12,3) NOT NULL DEFAULT 0.000,
  `unit` varchar(30) NOT NULL,
  `purchase_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ingredients`
--

INSERT INTO `ingredients` (`ingredient_id`, `name`, `quantity`, `unit`, `purchase_price`, `created_at`, `updated_at`) VALUES
(1, 'Burger Bun', 100.000, 'pieces', 12.00, '2026-11-04 08:58:37', '2026-11-04 08:58:37'),
(2, 'Beef Patty', 50.000, 'pieces', 55.00, '2026-11-04 08:58:37', '2026-11-04 08:58:37'),
(3, 'Potatoes', 20.000, 'kg', 80.00, '2026-11-04 08:58:37', '2026-11-04 08:58:37'),
(4, 'Tea Concentrate', 8.000, 'liters', 90.00, '2026-11-04 08:58:37', '2026-11-04 08:58:37'),
(5, 'Sugar', 15.000, 'kg', 50.00, '2026-11-04 08:58:37', '2026-11-04 08:58:37');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int(10) UNSIGNED NOT NULL,
  `order_number` varchar(40) NOT NULL,
  `order_date` date NOT NULL,
  `order_time` time NOT NULL,
  `order_type` varchar(40) NOT NULL,
  `status` varchar(40) NOT NULL DEFAULT 'Pending',
  `payment_method` varchar(40) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total` decimal(12,2) NOT NULL DEFAULT 0.00,
  `amount_received` decimal(12,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`order_id`, `order_number`, `order_date`, `order_time`, `order_type`, `status`, `payment_method`, `subtotal`, `total`, `amount_received`, `created_at`) VALUES
(1, 'ORD-0001', '2026-11-04', '12:30:00', 'Dine In', 'Completed', 'Cash', 185.00, 185.00, 200.00, '2026-11-04 08:58:37'),
(2, 'ORD-0002', '2026-11-04', '13:15:00', 'Take Out', 'Completed', 'GCash', 90.00, 90.00, 90.00, '2026-11-04 08:58:37');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `order_item_id` int(10) UNSIGNED NOT NULL,
  `unique_id` varchar(36) DEFAULT NULL,
  `order_id` int(10) UNSIGNED NOT NULL,
  `product_id` int(10) UNSIGNED NOT NULL,
  `product_name` varchar(150) NOT NULL,
  `quantity` int(10) UNSIGNED NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `unit_cost_snapshot` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`order_item_id`, `unique_id`, `order_id`, `product_id`, `product_name`, `quantity`, `unit_price`, `unit_cost_snapshot`) VALUES
(1, 'OI-000001', 1, 1, 'Classic Burger', 1, 120.00, 67.00),
(2, 'OI-000002', 1, 2, 'French Fries', 1, 65.00, 28.00),
(3, 'OI-000003', 2, 3, 'Iced Tea', 2, 45.00, 15.00);

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `product_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `category` varchar(100) NOT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `available` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`product_id`, `name`, `category`, `price`, `available`, `created_at`, `updated_at`) VALUES
(1, 'Classic Burger', 'Food', 120.00, 1, '2026-11-04 08:58:37', '2026-11-04 08:58:37'),
(2, 'French Fries', 'Side Dish', 65.00, 1, '2026-11-04 08:58:37', '2026-11-04 08:58:37'),
(3, 'Iced Tea', 'Beverage', 45.00, 1, '2026-11-04 08:58:37', '2026-11-04 08:58:37');

-- --------------------------------------------------------

--
-- Table structure for table `recipe`
--

CREATE TABLE `recipe` (
  `recipe_id` int(10) UNSIGNED NOT NULL,
  `product_id` int(10) UNSIGNED NOT NULL,
  `ingredient_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `recipe`
--

INSERT INTO `recipe` (`recipe_id`, `product_id`, `ingredient_id`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 2, 3),
(4, 3, 4),
(5, 3, 5);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ingredients`
--
ALTER TABLE `ingredients`
  ADD PRIMARY KEY (`ingredient_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD UNIQUE KEY `uq_orders_order_number` (`order_number`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD UNIQUE KEY `uq_order_items_unique_id` (`unique_id`),
  ADD KEY `idx_order_items_order` (`order_id`),
  ADD KEY `idx_order_items_product` (`product_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_id`);

--
-- Indexes for table `recipe`
--
ALTER TABLE `recipe`
  ADD PRIMARY KEY (`recipe_id`),
  ADD UNIQUE KEY `uq_recipe_product_ingredient` (`product_id`,`ingredient_id`),
  ADD KEY `idx_recipe_ingredient` (`ingredient_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ingredients`
--
ALTER TABLE `ingredients`
  MODIFY `ingredient_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `order_item_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `product_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `recipe`
--
ALTER TABLE `recipe`
  MODIFY `recipe_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_order_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON UPDATE CASCADE;

--
-- Constraints for table `recipe`
--
ALTER TABLE `recipe`
  ADD CONSTRAINT `fk_recipe_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_recipe_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE;
--
-- Database: `test`
--
CREATE DATABASE IF NOT EXISTS `test` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `test`;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
