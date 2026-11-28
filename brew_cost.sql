-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 28, 2026 at 08:07 AM
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
-- Database: `brew_cost`
--

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
