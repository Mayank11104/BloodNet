-- ============================================
--   BLOODNET DATABASE
--   Complete Schema + Dummy Data
-- ============================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+05:30";

-- ============================================
-- CREATE DATABASE
-- ============================================
CREATE DATABASE IF NOT EXISTS `bloodnet_db`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `bloodnet_db`;

-- ============================================
-- TABLE: cities
-- ============================================
CREATE TABLE `cities` (
  `id`         INT(11) NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(100) NOT NULL,
  `state`      VARCHAR(100) NOT NULL,
  `pincode`    VARCHAR(10)  NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `cities` (`id`,`name`,`state`,`pincode`) VALUES
(1,  'Mumbai',    'Maharashtra',    '400001'),
(2,  'Pune',      'Maharashtra',    '411001'),
(3,  'Nagpur',    'Maharashtra',    '440001'),
(4,  'Delhi',     'Delhi',          '110001'),
(5,  'Bangalore', 'Karnataka',      '560001'),
(6,  'Hyderabad', 'Telangana',      '500001'),
(7,  'Chennai',   'Tamil Nadu',     '600001'),
(8,  'Kolkata',   'West Bengal',    '700001'),
(9,  'Ahmedabad', 'Gujarat',        '380001'),
(10, 'Jaipur',    'Rajasthan',      '302001'),
(11, 'Lucknow',   'Uttar Pradesh',  '226001'),
(12, 'Bhopal',    'Madhya Pradesh', '462001');

-- ============================================
-- TABLE: blood_banks
-- ============================================
CREATE TABLE `blood_banks` (
  `id`         INT(11) NOT NULL AUTO_INCREMENT,
  `city_id`    INT(11) NOT NULL,
  `name`       VARCHAR(150) NOT NULL,
  `address`    VARCHAR(255) NOT NULL,
  `contact`    VARCHAR(15)  NOT NULL,
  `email`      VARCHAR(100) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`city_id`) REFERENCES `cities`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `blood_banks` (`id`,`city_id`,`name`,`address`,`contact`,`email`) VALUES
(1,  1,  'BloodNet Mumbai Center',    'Dadar, Mumbai',            '9800000001', 'mumbai@bloodnet.in'),
(2,  2,  'BloodNet Pune Center',      'Shivajinagar, Pune',       '9800000002', 'pune@bloodnet.in'),
(3,  3,  'BloodNet Nagpur Center',    'Sitabuldi, Nagpur',        '9800000003', 'nagpur@bloodnet.in'),
(4,  4,  'BloodNet Delhi Center',     'Connaught Place, Delhi',   '9800000004', 'delhi@bloodnet.in'),
(5,  5,  'BloodNet Bangalore Center', 'MG Road, Bangalore',       '9800000005', 'bangalore@bloodnet.in'),
(6,  6,  'BloodNet Hyderabad Center', 'Banjara Hills, Hyd',       '9800000006', 'hyderabad@bloodnet.in'),
(7,  7,  'BloodNet Chennai Center',   'Anna Nagar, Chennai',      '9800000007', 'chennai@bloodnet.in'),
(8,  8,  'BloodNet Kolkata Center',   'Park Street, Kolkata',     '9800000008', 'kolkata@bloodnet.in'),
(9,  9,  'BloodNet Ahmedabad Center', 'CG Road, Ahmedabad',       '9800000009', 'ahmedabad@bloodnet.in'),
(10, 10, 'BloodNet Jaipur Center',    'MI Road, Jaipur',          '9800000010', 'jaipur@bloodnet.in'),
(11, 11, 'BloodNet Lucknow Center',   'Hazratganj, Lucknow',      '9800000011', 'lucknow@bloodnet.in'),
(12, 12, 'BloodNet Bhopal Center',    'MP Nagar, Bhopal',         '9800000012', 'bhopal@bloodnet.in');

-- ============================================
-- TABLE: blood_stock
-- ============================================
CREATE TABLE `blood_stock` (
  `id`               INT(11) NOT NULL AUTO_INCREMENT,
  `bank_id`          INT(11) NOT NULL,
  `blood_group`      ENUM('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `units_available`  INT(11) NOT NULL DEFAULT 0,
  `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `bank_blood` (`bank_id`,`blood_group`),
  FOREIGN KEY (`bank_id`) REFERENCES `blood_banks`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `blood_stock` (`bank_id`,`blood_group`,`units_available`) VALUES
-- Mumbai
(1,'A+',18),(1,'A-',6),(1,'B+',15),(1,'B-',8),(1,'O+',21),(1,'O-',2),(1,'AB+',14),(1,'AB-',5),
-- Pune
(2,'A+',18),(2,'A-',4),(2,'B+',18),(2,'B-',3),(2,'O+',28),(2,'O-',2),(2,'AB+',14),(2,'AB-',2),
-- Nagpur
(3,'A+',14),(3,'A-',10),(3,'B+',15),(3,'B-',10),(3,'O+',22),(3,'O-',2),(3,'AB+',7),(3,'AB-',1),
-- Delhi
(4,'A+',17),(4,'A-',6),(4,'B+',16),(4,'B-',4),(4,'O+',10),(4,'O-',3),(4,'AB+',13),(4,'AB-',1),
-- Bangalore
(5,'A+',9),(5,'A-',7),(5,'B+',12),(5,'B-',5),(5,'O+',23),(5,'O-',3),(5,'AB+',9),(5,'AB-',5),
-- Hyderabad
(6,'A+',21),(6,'A-',8),(6,'B+',11),(6,'B-',6),(6,'O+',24),(6,'O-',5),(6,'AB+',11),(6,'AB-',4),
-- Chennai
(7,'A+',21),(7,'A-',5),(7,'B+',10),(7,'B-',7),(7,'O+',26),(7,'O-',2),(7,'AB+',5),(7,'AB-',2),
-- Kolkata
(8,'A+',21),(8,'A-',9),(8,'B+',14),(8,'B-',6),(8,'O+',22),(8,'O-',3),(8,'AB+',6),(8,'AB-',3),
-- Ahmedabad
(9,'A+',16),(9,'A-',7),(9,'B+',20),(9,'B-',4),(9,'O+',29),(9,'O-',3),(9,'AB+',12),(9,'AB-',5),
-- Jaipur
(10,'A+',13),(10,'A-',4),(10,'B+',17),(10,'B-',7),(10,'O+',12),(10,'O-',2),(10,'AB+',11),(10,'AB-',1),
-- Lucknow
(11,'A+',13),(11,'A-',3),(11,'B+',8),(11,'B-',5),(11,'O+',14),(11,'O-',4),(11,'AB+',14),(11,'AB-',5),
-- Bhopal
(12,'A+',9),(12,'A-',5),(12,'B+',8),(12,'B-',8),(12,'O+',25),(12,'O-',3),(12,'AB+',8),(12,'AB-',3);

-- ============================================
-- TABLE: users
-- ============================================
CREATE TABLE `users` (
  `id`         INT(11) NOT NULL AUTO_INCREMENT,
  `username`   VARCHAR(50)  NOT NULL UNIQUE,
  `email`      VARCHAR(100) NOT NULL UNIQUE,
  `password`   VARCHAR(255) NOT NULL,
  `phone`      VARCHAR(15)  NOT NULL UNIQUE,
  `full_name`  VARCHAR(150) NOT NULL,
  `role`       ENUM('admin','donor','seeker') NOT NULL DEFAULT 'seeker',
  `city_id`    INT(11) DEFAULT NULL,
  `is_active`  TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`city_id`) REFERENCES `cities`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Passwords are md5 hashed
-- admin123   → 0192023a7bbd73250516f069df18b500
-- donor123   → 0f19b4d89b3d09fac1f1a33c5831531b
-- seeker123  → 9a618248b64db62d15b300a07b00580b

INSERT INTO `users` (`id`,`username`,`email`,`password`,`phone`,`full_name`,`role`,`city_id`) VALUES
-- Admin
(1,  'admin',       'admin@bloodnet.in',      '0192023a7bbd73250516f069df18b500', '9000000000', 'BloodNet Admin',     'admin',  1),
-- Donors
(2,  'rahul_d',     'rahul@example.com',      '0f19b4d89b3d09fac1f1a33c5831531b', '9111111101', 'Rahul Sharma',       'donor',  1),
(3,  'priya_d',     'priya@example.com',      '0f19b4d89b3d09fac1f1a33c5831531b', '9111111102', 'Priya Patel',        'donor',  2),
(4,  'amit_d',      'amit@example.com',       '0f19b4d89b3d09fac1f1a33c5831531b', '9111111103', 'Amit Singh',         'donor',  4),
(5,  'sneha_d',     'sneha@example.com',      '0f19b4d89b3d09fac1f1a33c5831531b', '9111111104', 'Sneha Reddy',        'donor',  5),
(6,  'vikram_d',    'vikram@example.com',     '0f19b4d89b3d09fac1f1a33c5831531b', '9111111105', 'Vikram Nair',        'donor',  6),
(7,  'ananya_d',    'ananya@example.com',     '0f19b4d89b3d09fac1f1a33c5831531b', '9111111106', 'Ananya Iyer',        'donor',  7),
(8,  'rohit_d',     'rohit@example.com',      '0f19b4d89b3d09fac1f1a33c5831531b', '9111111107', 'Rohit Banerjee',     'donor',  8),
(9,  'kavya_d',     'kavya@example.com',      '0f19b4d89b3d09fac1f1a33c5831531b', '9111111108', 'Kavya Mehta',        'donor',  9),
(10, 'arjun_d',     'arjun@example.com',      '0f19b4d89b3d09fac1f1a33c5831531b', '9111111109', 'Arjun Verma',        'donor',  3),
(11, 'divya_d',     'divya@example.com',      '0f19b4d89b3d09fac1f1a33c5831531b', '9111111110', 'Divya Joshi',        'donor',  10),
-- Seekers
(12, 'mohan_s',     'mohan@example.com',      '9a618248b64db62d15b300a07b00580b', '9222222201', 'Mohan Kumar',        'seeker', 1),
(13, 'sara_s',      'sara@example.com',       '9a618248b64db62d15b300a07b00580b', '9222222202', 'Sara Thomas',        'seeker', 2),
(14, 'ravi_s',      'ravi@example.com',       '9a618248b64db62d15b300a07b00580b', '9222222203', 'Ravi Tiwari',        'seeker', 4),
(15, 'meera_s',     'meera@example.com',      '9a618248b64db62d15b300a07b00580b', '9222222204', 'Meera Pillai',       'seeker', 5);

-- ============================================
-- TABLE: donor_profiles
-- ============================================
CREATE TABLE `donor_profiles` (
  `id`                  INT(11) NOT NULL AUTO_INCREMENT,
  `user_id`             INT(11) NOT NULL UNIQUE,
  `blood_group`         ENUM('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `date_of_birth`       DATE NOT NULL,
  `gender`              ENUM('Male','Female','Other') NOT NULL,
  `weight_kg`           DECIMAL(5,2) NOT NULL,
  `hemoglobin_level`    DECIMAL(4,1) DEFAULT NULL,
  `blood_pressure`      VARCHAR(10)  DEFAULT NULL,
  `total_credits`       INT(11) NOT NULL DEFAULT 0,
  `is_available`        TINYINT(1) NOT NULL DEFAULT 1,
  `last_donation_date`  DATE DEFAULT NULL,
  `unavailable_until`   DATE DEFAULT NULL,
  `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `donor_profiles`
(`user_id`,`blood_group`,`date_of_birth`,`gender`,`weight_kg`,`hemoglobin_level`,`blood_pressure`,`total_credits`,`is_available`,`last_donation_date`,`unavailable_until`) VALUES
(2,  'B+',  '1995-03-12', 'Male',   72.0, 14.2, '120/80', 30, 1, '2025-12-01', '2026-01-26'),
(3,  'A+',  '1998-07-25', 'Female', 58.5, 13.1, '118/76', 20, 1, '2025-11-15', '2026-01-10'),
(4,  'O+',  '1992-01-08', 'Male',   80.0, 15.0, '122/82', 50, 1, '2025-10-20', '2025-12-15'),
(5,  'AB+', '1996-05-19', 'Female', 62.0, 12.8, '116/74', 10, 1, '2026-01-05', '2026-03-02'),
(6,  'B-',  '1990-09-30', 'Male',   75.5, 14.8, '124/80', 70, 1, '2025-09-10', '2025-11-05'),
(7,  'A-',  '1993-12-14', 'Female', 55.0, 13.5, '114/72', 40, 1, '2025-08-22', '2025-10-17'),
(8,  'O-',  '1988-04-03', 'Male',   90.0, 16.1, '130/84', 90, 0, '2026-02-14', '2026-04-11'),
(9,  'AB-', '1997-08-17', 'Female', 60.0, 12.5, '112/70', 20, 1, '2025-12-25', '2026-02-19'),
(10, 'A+',  '1994-11-22', 'Male',   68.0, 13.9, '120/78', 60, 1, '2025-07-30', '2025-09-24'),
(11, 'O+',  '1999-02-28', 'Female', 54.0, 12.9, '110/70', 10, 1, '2026-01-18', '2026-03-15');

-- ============================================
-- TABLE: health_checks
-- ============================================
CREATE TABLE `health_checks` (
  `id`                  INT(11) NOT NULL AUTO_INCREMENT,
  `user_id`             INT(11) NOT NULL UNIQUE,
  `has_diabetes`        TINYINT(1) NOT NULL DEFAULT 0,
  `has_hiv_hepatitis`   TINYINT(1) NOT NULL DEFAULT 0,
  `on_medication`       TINYINT(1) NOT NULL DEFAULT 0,
  `recent_surgery`      TINYINT(1) NOT NULL DEFAULT 0,
  `surgery_details`     TEXT DEFAULT NULL,
  `medication_details`  TEXT DEFAULT NULL,
  `is_eligible`         TINYINT(1) NOT NULL DEFAULT 1,
  `checked_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `health_checks`
(`user_id`,`has_diabetes`,`has_hiv_hepatitis`,`on_medication`,`recent_surgery`,`is_eligible`) VALUES
(2,  0, 0, 0, 0, 1),
(3,  0, 0, 0, 0, 1),
(4,  0, 0, 0, 0, 1),
(5,  0, 0, 0, 0, 1),
(6,  0, 0, 0, 0, 1),
(7,  0, 0, 0, 0, 1),
(8,  0, 0, 0, 0, 1),
(9,  0, 0, 0, 0, 1),
(10, 0, 0, 0, 0, 1),
(11, 0, 0, 0, 0, 1);

-- ============================================
-- TABLE: blood_requests
-- ============================================
CREATE TABLE `blood_requests` (
  `id`                INT(11) NOT NULL AUTO_INCREMENT,
  `tracking_id`       VARCHAR(20) NOT NULL UNIQUE,
  `seeker_id`         INT(11) NOT NULL,
  `blood_group`       ENUM('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `units_needed`      INT(11) NOT NULL DEFAULT 1,
  `hospital_name`     VARCHAR(200) NOT NULL,
  `city_id`           INT(11) NOT NULL,
  `contact`           VARCHAR(15) NOT NULL,
  `is_emergency`      TINYINT(1) NOT NULL DEFAULT 0,
  `incident_type`     VARCHAR(50) DEFAULT NULL,
  `incident_desc`     TEXT DEFAULT NULL,
  `severity`          ENUM('Low','Medium','High','Critical') NOT NULL DEFAULT 'Medium',
  `priority_score`    INT(11) NOT NULL DEFAULT 0,
  `status`            ENUM('Pending','Processing','Approved','Fulfilled','Rejected') NOT NULL DEFAULT 'Pending',
  `assigned_bank_id`  INT(11) DEFAULT NULL,
  `patient_name`      VARCHAR(150) DEFAULT NULL,
  `requested_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seeker_id`)        REFERENCES `users`(`id`)       ON DELETE CASCADE,
  FOREIGN KEY (`city_id`)          REFERENCES `cities`(`id`)      ON DELETE CASCADE,
  FOREIGN KEY (`assigned_bank_id`) REFERENCES `blood_banks`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `blood_requests`
(`tracking_id`,`seeker_id`,`blood_group`,`units_needed`,`hospital_name`,`city_id`,`contact`,`is_emergency`,`incident_type`,`severity`,`priority_score`,`status`,`assigned_bank_id`,`patient_name`) VALUES
('BNAB1234CD', 12, 'B+',  2, 'KEM Hospital Mumbai',          1, '9222222201', 0, NULL,       'Medium',   40,  'Fulfilled',  1, 'Ramesh Kumar'),
('BNCD5678EF', 13, 'A+',  1, 'Ruby Hall Clinic Pune',        2, '9222222202', 0, NULL,       'Low',      20,  'Approved',   2, 'Sunita Desai'),
('BNEF9012GH', 14, 'O-',  3, 'AIIMS Delhi',                  4, '9222222203', 1, 'Accident', 'Critical', 180, 'Processing', 4, 'Arun Tiwari'),
('BNGH3456IJ', 15, 'AB+', 1, 'Apollo Hospital Bangalore',    5, '9222222204', 0, NULL,       'High',     60,  'Pending',    5, 'Lakshmi Pillai'),
('BNIJ7890KL', 12, 'O+',  2, 'Breach Candy Hospital Mumbai', 1, '9222222201', 1, 'Surgery',  'Critical', 180, 'Pending',    1, 'Vijay Shah'),
('BNKL1234MN', 13, 'A-',  1, 'Sahyadri Hospital Pune',       2, '9222222202', 0, NULL,       'Medium',   40,  'Rejected',   2, 'Pooja Kulkarni'),
('BNMN5678OP', 14, 'B-',  2, 'Fortis Hospital Delhi',        4, '9222222203', 0, NULL,       'High',     60,  'Fulfilled',  4, 'Suresh Yadav'),
('BNOP9012QR', 15, 'AB-', 1, 'Manipal Hospital Bangalore',   5, '9222222204', 1, 'Cancer',   'Critical', 180, 'Approved',   5, 'Kavitha Menon');

-- ============================================
-- TABLE: request_tracking
-- ============================================
CREATE TABLE `request_tracking` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `request_id`  INT(11) NOT NULL,
  `status`      ENUM('Pending','Processing','Approved','Fulfilled','Rejected') NOT NULL,
  `notes`       TEXT DEFAULT NULL,
  `updated_by`  INT(11) DEFAULT NULL,
  `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`request_id`) REFERENCES `blood_requests`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`updated_by`)  REFERENCES `users`(`id`)          ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `request_tracking` (`request_id`,`status`,`notes`,`updated_by`) VALUES
(1, 'Pending',    'Request submitted successfully',           NULL),
(1, 'Processing', 'Verified with KEM Hospital',               1),
(1, 'Approved',   'Stock allocated from Mumbai center',        1),
(1, 'Fulfilled',  'Blood delivered successfully',              1),
(2, 'Pending',    'Request submitted successfully',           NULL),
(2, 'Approved',   'Stock confirmed at Pune center',            1),
(3, 'Pending',    'Emergency request submitted',              NULL),
(3, 'Processing', 'Emergency flagged — contacting Delhi bank', 1),
(4, 'Pending',    'Request submitted successfully',           NULL),
(5, 'Pending',    'Emergency request submitted',              NULL),
(6, 'Pending',    'Request submitted successfully',           NULL),
(6, 'Rejected',   'Blood group not available in sufficient units', 1),
(7, 'Pending',    'Request submitted successfully',           NULL),
(7, 'Processing', 'Verifying with Fortis Delhi',               1),
(7, 'Fulfilled',  'Request fulfilled successfully',            1),
(8, 'Pending',    'Emergency cancer patient request',         NULL),
(8, 'Approved',   'Priority approved — Manipal Bangalore',     1);

-- ============================================
-- TABLE: donations
-- ============================================
CREATE TABLE `donations` (
  `id`             INT(11) NOT NULL AUTO_INCREMENT,
  `donor_id`       INT(11) NOT NULL,
  `bank_id`        INT(11) NOT NULL,
  `blood_group`    ENUM('A+','A-','B+','B-','O+','O-','AB+','AB-') NOT NULL,
  `units_donated`  INT(11) NOT NULL DEFAULT 1,
  `credits_earned` INT(11) NOT NULL DEFAULT 10,
  `donation_date`  DATE NOT NULL,
  `verified_by`    INT(11) DEFAULT NULL,
  `notes`          TEXT DEFAULT NULL,
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`donor_id`)   REFERENCES `users`(`id`)       ON DELETE CASCADE,
  FOREIGN KEY (`bank_id`)    REFERENCES `blood_banks`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`verified_by`) REFERENCES `users`(`id`)      ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `donations`
(`donor_id`,`bank_id`,`blood_group`,`units_donated`,`credits_earned`,`donation_date`,`verified_by`,`notes`) VALUES
(2,  1, 'B+',  1, 10, '2025-06-10', 1, 'First donation — healthy'),
(2,  1, 'B+',  1, 10, '2025-08-20', 1, 'Second donation'),
(2,  1, 'B+',  1, 10, '2025-12-01', 1, 'Third donation'),
(3,  2, 'A+',  1, 10, '2025-05-15', 1, 'First donation'),
(3,  2, 'A+',  1, 10, '2025-11-15', 1, 'Second donation'),
(4,  4, 'O+',  1, 10, '2025-04-20', 1, 'Walk-in donor'),
(4,  4, 'O+',  1, 10, '2025-06-25', 1, 'Repeat donor'),
(4,  4, 'O+',  1, 10, '2025-08-30', 1, 'Third donation'),
(4,  4, 'O+',  1, 10, '2025-10-20', 1, 'Fourth donation'),
(4,  4, 'O+',  1, 10, '2025-12-01', 1, 'Fifth donation'),
(5,  5, 'AB+', 1, 10, '2026-01-05', 1, 'First donation'),
(6,  6, 'B-',  1, 10, '2025-03-10', 1, 'First donation'),
(6,  6, 'B-',  1, 10, '2025-05-15', 1, 'Second donation'),
(6,  6, 'B-',  1, 10, '2025-07-20', 1, 'Third donation'),
(6,  6, 'B-',  1, 10, '2025-09-10', 1, 'Fourth donation — brave donor'),
(6,  6, 'B-',  1, 10, '2025-11-20', 1, 'Fifth donation'),
(6,  6, 'B-',  1, 10, '2025-12-25', 1, 'Sixth donation — 70 credits!'),
(7,  7, 'A-',  1, 10, '2025-02-14', 1, 'First donation'),
(7,  7, 'A-',  1, 10, '2025-04-20', 1, 'Second donation'),
(7,  7, 'A-',  1, 10, '2025-06-25', 1, 'Third donation'),
(7,  7, 'A-',  1, 10, '2025-08-22', 1, 'Fourth donation'),
(8,  8, 'O-',  1, 10, '2025-05-01', 1, 'Universal donor'),
(8,  8, 'O-',  1, 10, '2025-07-07', 1, 'Second donation'),
(8,  8, 'O-',  1, 10, '2025-09-12', 1, 'Third donation'),
(8,  8, 'O-',  1, 10, '2025-11-18', 1, 'Fourth donation'),
(8,  8, 'O-',  1, 10, '2026-01-23', 1, 'Fifth donation'),
(8,  8, 'O-',  1, 10, '2026-02-14', 1, 'Sixth donation'),
(8,  8, 'O-',  1, 10, '2026-03-01', 1, 'Seventh donation — 90 credits! Almost hero!'),
(9,  9, 'AB-', 1, 10, '2025-06-20', 1, 'First donation'),
(9,  9, 'AB-', 1, 10, '2025-12-25', 1, 'Second donation'),
(10, 3, 'A+',  1, 10, '2025-01-30', 1, 'First donation'),
(10, 3, 'A+',  1, 10, '2025-03-25', 1, 'Second donation'),
(10, 3, 'A+',  1, 10, '2025-05-30', 1, 'Third donation'),
(10, 3, 'A+',  1, 10, '2025-07-30', 1, 'Fourth donation'),
(10, 3, 'A+',  1, 10, '2025-09-15', 1, 'Fifth donation'),
(10, 3, 'A+',  1, 10, '2025-11-20', 1, 'Sixth donation — 60 credits'),
(11, 10, 'O+', 1, 10, '2026-01-18', 1, 'First donation');

-- ============================================
-- TABLE: notifications
-- ============================================
CREATE TABLE `notifications` (
  `id`       INT(11) NOT NULL AUTO_INCREMENT,
  `user_id`  INT(11) NOT NULL,
  `type`     ENUM('email','sms','in-app') NOT NULL DEFAULT 'in-app',
  `subject`  VARCHAR(200) NOT NULL,
  `message`  TEXT NOT NULL,
  `is_read`  TINYINT(1) NOT NULL DEFAULT 0,
  `sent_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `notifications` (`user_id`,`type`,`subject`,`message`,`is_read`) VALUES
(2,  'in-app', '🩸 Donation Recorded!',          'Thank you for donating on 2025-12-01! You earned +10 credits.',                    1),
(2,  'in-app', '🚨 Urgent Blood Needed!',         'There is an urgent need for B+ blood in Mumbai. Please consider donating.',         0),
(3,  'in-app', '🩸 Donation Recorded!',           'Thank you for donating on 2025-11-15! You earned +10 credits.',                    1),
(4,  'in-app', '🏆 Congratulations! New Badge!',  'You earned the "BloodNet Hero Level 1" badge! Your gift is on the way!',           1),
(4,  'in-app', '🩸 Donation Recorded!',           'Thank you for donating on 2025-12-01! You have 50 credits total.',                 1),
(5,  'in-app', '🩸 Welcome to BloodNet!',         'Thank you for registering as a donor. You are now visible to seekers.',            1),
(6,  'in-app', '🏆 Congratulations! New Badge!',  'You earned the "BloodNet Hero Level 1" badge for reaching 70 credits!',           0),
(7,  'in-app', '🩸 Donation Recorded!',           'Thank you for donating on 2025-08-22! You earned +10 credits. Total: 40.',        1),
(8,  'in-app', '🩸 Donation Recorded!',           'Thank you for donating on 2026-02-14! You earned +10 credits. Total: 90.',        0),
(8,  'in-app', '🚨 Urgent Blood Needed!',         'Urgent need for O- blood in Kolkata. You are a universal donor — please help!',   0),
(9,  'in-app', '🩸 Donation Recorded!',           'Thank you for donating on 2025-12-25! You earned +10 credits.',                   1),
(10, 'in-app', '🩸 Donation Recorded!',           'Thank you for your 6th donation! You have 60 credits. Only 40 more to Hero!',     0),
(11, 'in-app', '🩸 Welcome to BloodNet!',         'Thank you for your first donation! You earned +10 credits.',                      0),
(12, 'in-app', '✅ Request Approved!',            'Your blood request BNAB1234CD has been approved. Contact KEM Hospital.',          1),
(13, 'in-app', '✅ Request Approved!',            'Your blood request BNCD5678EF has been approved. Contact Ruby Hall Clinic.',      1),
(14, 'in-app', '🚨 Emergency Processing!',        'Your emergency request BNEF9012GH is being processed with highest priority.',     1),
(15, 'in-app', '⏳ Request Pending',              'Your request BNGH3456IJ is pending review. We will notify you shortly.',          0);

-- ============================================
-- TABLE: rewards
-- ============================================
CREATE TABLE `rewards` (
  `id`          INT(11) NOT NULL AUTO_INCREMENT,
  `user_id`     INT(11) NOT NULL,
  `badge_name`  VARCHAR(100) NOT NULL,
  `credits_at`  INT(11) NOT NULL,
  `earned_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `rewards` (`user_id`,`badge_name`,`credits_at`) VALUES
(4,  'BloodNet Hero Level 1', 100),
(6,  'BloodNet Hero Level 1', 100);

COMMIT;