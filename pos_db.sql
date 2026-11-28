-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 28, 2026 at 08:06 AM
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
-- Database: `pos_db`
--

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
(1, 'Espresso beans', 'g', 1000.000, 850.00, 648.000, 200.000, '2026-11-28 07:02:59'),
(2, 'Fresh milk', 'ml', 1000.000, 95.00, 1150.000, 250.000, '2026-11-28 07:04:26'),
(3, 'Condensed milk', 'ml', 1000.000, 120.00, 800.000, 250.000, '2026-11-28 07:01:45'),
(4, 'Chocolate sauce', 'ml', 750.000, 300.00, 480.000, 150.000, '2026-11-28 07:01:45'),
(5, 'White chocolate sauce', 'ml', 750.000, 330.00, 380.000, 150.000, '2026-11-28 07:01:45'),
(6, 'Sea salt', 'g', 250.000, 45.00, 200.000, 50.000, '2026-11-28 07:01:45'),
(7, 'Whipped cream', 'ml', 500.000, 180.00, 280.000, 100.000, '2026-11-28 07:02:59'),
(8, 'Cinnamon powder', 'g', 100.000, 60.00, 89.000, 25.000, '2026-11-28 07:02:59'),
(19, 'Vanilla syrup', 'ml', 750.000, 320.00, 410.000, 150.000, '2026-11-28 07:02:59'),
(20, 'Caramel sauce', 'ml', 750.000, 340.00, 565.000, 100.000, '2026-11-28 07:02:59');

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
(1, 'Spanish Latte', 'Coffee', 150.00, 'Sweet condensed milk espresso', '☕', 1, '2026-11-28 07:01:44'),
(2, 'Cappuccino', 'Coffee', 130.00, 'Espresso with steamed milk foam', '☕', 1, '2026-11-28 07:01:44'),
(3, 'Americano', 'Coffee', 110.00, 'Double shot with hot water', '☕', 1, '2026-11-28 07:01:44'),
(4, 'Café Latte', 'Coffee', 125.00, 'Smooth espresso and silky milk', '☕', 1, '2026-11-28 07:01:44'),
(5, 'Caramel Macchiato', 'Coffee', 165.00, 'Vanilla, milk, caramel drizzle', '🍮', 1, '2026-11-28 07:01:44'),
(6, 'Cold Brew', 'Coffee', 140.00, '18-hour steeped, served iced', '🧊', 1, '2026-11-28 07:01:44'),
(7, 'Mocha Latte', 'Coffee', 155.00, 'Espresso, chocolate and steamed milk', '🍫', 1, '2026-11-28 07:01:44'),
(8, 'White Mocha', 'Coffee', 160.00, 'White chocolate and espresso', '🤍', 1, '2026-11-28 07:01:44'),
(9, 'Salted Caramel Latte', 'Coffee', 170.00, 'Caramel, milk and a pinch of sea salt', '🧂', 1, '2026-11-28 07:01:44'),
(10, 'Vanilla Cold Brew', 'Coffee', 150.00, 'Cold brew, vanilla, splash of milk', '🍦', 1, '2026-11-28 07:01:44'),
(11, 'Espresso', 'Coffee', 95.00, 'Double shot, straight up', '⚡', 1, '2026-11-28 07:01:44'),
(12, 'Macchiato', 'Coffee', 120.00, 'Espresso marked with milk foam', '🥛', 1, '2026-11-28 07:01:44');

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
(1, '01', 'Dine in', 'paid', 'GCash', '09695352992', NULL, 670.00, 703.50, '2026-11-28', '2026-11-28 07:02:59');

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
(5, 1, 6, 'Cold Brew', 140.00, 1);

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
(1, 'Admin', 'admin', '$2y$12$5sQBOUty0N6TqO/iHYvH1esPu6sujY3Sq9iOZ4jC3QUqgf/vQPypa', NULL, 'admin', '2026-11-28 07:01:44'),
(2, 'Front Counter', NULL, NULL, '$2y$12$7adky02LRRE7lcV4M5KjkuMKVZ7tmN0miZgMyTvId2T15.hJLjRIq', 'cashier', '2026-11-28 07:01:44');

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
(1, 1, -180.000, 'order', NULL, '2026-11-28 04:01:45'),
(2, 2, -600.000, 'order', NULL, '2026-11-28 04:01:45'),
(3, 1, 750.000, 'restock', NULL, '2026-11-27 07:01:45'),
(4, 20, -40.000, 'order', NULL, '2026-11-28 05:01:45'),
(5, 19, -25.000, 'order', NULL, '2026-11-28 02:01:45'),
(6, 3, -160.000, 'order', NULL, '2026-11-28 04:01:45'),
(7, 4, -80.000, 'order', NULL, '2026-11-28 05:01:45'),
(8, 5, -60.000, 'order', NULL, '2026-11-28 05:01:45'),
(9, 7, -100.000, 'order', NULL, '2026-11-28 05:31:45'),
(10, 3, 800.000, 'restock', NULL, '2026-11-26 07:01:45'),
(11, 4, 750.000, 'restock', NULL, '2026-11-26 07:01:45'),
(12, 8, 90.000, 'restock', NULL, '2026-11-24 07:01:45'),
(13, 20, 500.000, 'restock', NULL, '2026-11-28 07:02:44'),
(14, 1, -18.000, 'order', 1, '2026-11-28 07:02:59'),
(15, 1, -18.000, 'order', 1, '2026-11-28 07:02:59'),
(16, 2, -180.000, 'order', 1, '2026-11-28 07:02:59'),
(17, 1, -18.000, 'order', 1, '2026-11-28 07:02:59'),
(18, 2, -120.000, 'order', 1, '2026-11-28 07:02:59'),
(19, 8, -1.000, 'order', 1, '2026-11-28 07:02:59'),
(20, 1, -18.000, 'order', 1, '2026-11-28 07:02:59'),
(21, 2, -150.000, 'order', 1, '2026-11-28 07:02:59'),
(22, 7, -20.000, 'order', 1, '2026-11-28 07:02:59'),
(23, 19, -10.000, 'order', 1, '2026-11-28 07:02:59'),
(24, 20, -20.000, 'order', 1, '2026-11-28 07:02:59'),
(25, 1, -30.000, 'order', 1, '2026-11-28 07:02:59'),
(26, 2, 500.000, 'restock', NULL, '2026-11-28 07:04:24'),
(27, 2, 500.000, 'restock', NULL, '2026-11-28 07:04:26');

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
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

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
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
