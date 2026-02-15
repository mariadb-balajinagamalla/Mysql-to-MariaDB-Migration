-- SQLines Data 3.7.11 x86_64 Linux - Database Migration and Validation Tool.
-- Copyright (c) 2026 SQLines. All Rights Reserved.

-- All DDL SQL statements executed for the target database

-- Current timestamp: 2026:02:15 18:01:05.360

DROP TABLE IF EXISTS sakila.actor;

-- Ok (8 ms)

DROP TABLE IF EXISTS sakila.address;

-- Ok (4 ms)

DROP TABLE IF EXISTS sakila.category;

-- Ok (4 ms)

CREATE TABLE sakila.actor
(
   `actor_id` SMALLINT NOT NULL AUTO_INCREMENT,
   `first_name` VARCHAR(45) NOT NULL,
   `last_name` VARCHAR(45) NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL,
   PRIMARY KEY (`actor_id`)
);

-- Ok (3 ms)

CREATE TABLE sakila.address
(
   `address_id` SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `address` VARCHAR(50) NOT NULL,
   `address2` VARCHAR(50),
   `district` VARCHAR(20) NOT NULL,
   `city_id` SMALLINT NOT NULL,
   `postal_code` VARCHAR(10),
   `phone` VARCHAR(20) NOT NULL,
   `location` GEOMETRY NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (4 ms)

DROP TABLE IF EXISTS sakila.country;

-- Ok (5 ms)

DROP TABLE IF EXISTS sakila.city;

-- Ok (7 ms)

CREATE TABLE sakila.category
(
   `category_id` TINYINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `name` VARCHAR(25) NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (3 ms)

DROP TABLE IF EXISTS sakila.customer;

-- Ok (5 ms)

CREATE TABLE sakila.country
(
   `country_id` SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `country` VARCHAR(50) NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (2 ms)

CREATE TABLE sakila.city
(
   `city_id` SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `city` VARCHAR(50) NOT NULL,
   `country_id` SMALLINT NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (2 ms)

CREATE TABLE sakila.customer
(
   `customer_id` SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `store_id` TINYINT NOT NULL,
   `first_name` VARCHAR(45) NOT NULL,
   `last_name` VARCHAR(45) NOT NULL,
   `email` VARCHAR(50),
   `address_id` SMALLINT NOT NULL,
   `active` TINYINT DEFAULT 1 NOT NULL,
   `create_date` DATETIME NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP
);

-- Ok (3 ms)

DROP TABLE IF EXISTS sakila.film;

-- Ok (7 ms)

DROP TABLE IF EXISTS sakila.film_category;

-- Ok (5 ms)

CREATE TABLE sakila.film
(
   `film_id` SMALLINT NOT NULL AUTO_INCREMENT,
   `title` VARCHAR(128) NOT NULL,
   `description` LONGTEXT,
   `release_year` YEAR,
   `language_id` TINYINT NOT NULL,
   `original_language_id` TINYINT,
   `rental_duration` TINYINT DEFAULT 3 NOT NULL,
   `rental_rate` DECIMAL(4,2) DEFAULT 4.99 NOT NULL,
   `length` SMALLINT,
   `replacement_cost` DECIMAL(5,2) DEFAULT 19.99 NOT NULL,
   `rating` CHAR(20),
   `special_features` CHAR(216),
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL,
   PRIMARY KEY (`film_id`)
);

-- Ok (5 ms)

CREATE TABLE sakila.film_category
(
   `film_id` SMALLINT NOT NULL,
   `category_id` TINYINT NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (2 ms)

DROP TABLE IF EXISTS sakila.film_text;

-- Ok (5 ms)

DROP TABLE IF EXISTS sakila.film_actor;

-- Ok (5 ms)

DROP TABLE IF EXISTS sakila.inventory;

-- Ok (5 ms)

CREATE TABLE sakila.film_actor
(
   `actor_id` SMALLINT NOT NULL,
   `film_id` SMALLINT NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (3 ms)

CREATE TABLE sakila.inventory
(
   `inventory_id` MEDIUMINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `film_id` SMALLINT NOT NULL,
   `store_id` TINYINT NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (2 ms)

DROP TABLE IF EXISTS sakila.language;

-- Ok (4 ms)

CREATE TABLE sakila.film_text
(
   `film_id` SMALLINT NOT NULL,
   `title` VARCHAR(255) NOT NULL,
   `description` LONGTEXT
);

-- Ok (2 ms)

CREATE TABLE sakila.language
(
   `language_id` TINYINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `name` CHAR(80) NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (2 ms)

DROP TABLE IF EXISTS sakila.rental;

-- Ok (6 ms)

ALTER TABLE sakila.film_actor ADD PRIMARY KEY (`actor_id`, `film_id`);

-- Ok (9 ms)

DROP TABLE IF EXISTS sakila.payment;

-- Ok (4 ms)

DROP TABLE IF EXISTS sakila.staff;

-- Ok (4 ms)

ALTER TABLE sakila.film_category ADD PRIMARY KEY (`film_id`, `category_id`);

-- Ok (6 ms)

CREATE TABLE sakila.rental
(
   `rental_id` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `rental_date` DATETIME NOT NULL,
   `inventory_id` MEDIUMINT NOT NULL,
   `customer_id` SMALLINT NOT NULL,
   `return_date` DATETIME,
   `staff_id` TINYINT NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (3 ms)

ALTER TABLE sakila.film_text ADD PRIMARY KEY (`film_id`);

-- Ok (7 ms)

CREATE TABLE sakila.payment
(
   `payment_id` SMALLINT NOT NULL AUTO_INCREMENT,
   `customer_id` SMALLINT NOT NULL,
   `staff_id` TINYINT NOT NULL,
   `rental_id` INTEGER,
   `amount` DECIMAL(5,2) NOT NULL,
   `payment_date` DATETIME NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`payment_id`)
);

-- Ok (3 ms)

CREATE TABLE sakila.staff
(
   `staff_id` TINYINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `first_name` VARCHAR(45) NOT NULL,
   `last_name` VARCHAR(45) NOT NULL,
   `address_id` SMALLINT NOT NULL,
   `picture` LONGBLOB,
   `email` VARCHAR(50),
   `store_id` TINYINT NOT NULL,
   `active` TINYINT DEFAULT 1 NOT NULL,
   `username` VARCHAR(16) NOT NULL,
   `password` VARCHAR(40),
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (3 ms)

DROP TABLE IF EXISTS sakila.store;

-- Ok (4 ms)

ALTER TABLE sakila.address ADD CONSTRAINT fk_address_city FOREIGN KEY (`city_id`) REFERENCES sakila.city (`city_id`);

-- Ok (4 ms)

ALTER TABLE sakila.city ADD CONSTRAINT fk_city_country FOREIGN KEY (`country_id`) REFERENCES sakila.country (`country_id`);

-- Ok (5 ms)

CREATE TABLE sakila.store
(
   `store_id` TINYINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   `manager_staff_id` TINYINT NOT NULL,
   `address_id` SMALLINT NOT NULL,
   `last_update` DATETIME(0) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Ok (3 ms)

ALTER TABLE sakila.customer ADD CONSTRAINT fk_customer_address FOREIGN KEY (`address_id`) REFERENCES sakila.address (`address_id`);

-- Ok (6 ms)

ALTER TABLE sakila.customer ADD CONSTRAINT fk_customer_store FOREIGN KEY (`store_id`) REFERENCES sakila.store (`store_id`);

-- Ok (4 ms)

ALTER TABLE sakila.film_actor ADD CONSTRAINT fk_film_actor_actor FOREIGN KEY (`actor_id`) REFERENCES sakila.actor (`actor_id`);

-- Ok (5 ms)

ALTER TABLE sakila.film_actor ADD CONSTRAINT fk_film_actor_film FOREIGN KEY (`film_id`) REFERENCES sakila.film (`film_id`);

-- Ok (7 ms)

ALTER TABLE sakila.film_category ADD CONSTRAINT fk_film_category_category FOREIGN KEY (`category_id`) REFERENCES sakila.category (`category_id`);

-- Ok (4 ms)

ALTER TABLE sakila.film_category ADD CONSTRAINT fk_film_category_film FOREIGN KEY (`film_id`) REFERENCES sakila.film (`film_id`);

-- Ok (3 ms)

ALTER TABLE sakila.film ADD CONSTRAINT fk_film_language FOREIGN KEY (`language_id`) REFERENCES sakila.language (`language_id`);

-- Ok (5 ms)

ALTER TABLE sakila.film ADD CONSTRAINT fk_film_language_original FOREIGN KEY (`original_language_id`) REFERENCES sakila.language (`language_id`);

-- Ok (4 ms)

ALTER TABLE sakila.inventory ADD CONSTRAINT fk_inventory_film FOREIGN KEY (`film_id`) REFERENCES sakila.film (`film_id`);

-- Ok (8 ms)

ALTER TABLE sakila.inventory ADD CONSTRAINT fk_inventory_store FOREIGN KEY (`store_id`) REFERENCES sakila.store (`store_id`);

-- Ok (7 ms)

ALTER TABLE sakila.payment ADD CONSTRAINT fk_payment_customer FOREIGN KEY (`customer_id`) REFERENCES sakila.customer (`customer_id`);

-- Ok (8 ms)

ALTER TABLE sakila.payment ADD CONSTRAINT fk_payment_rental FOREIGN KEY (`rental_id`) REFERENCES sakila.rental (`rental_id`);

-- Ok (9 ms)

ALTER TABLE sakila.payment ADD CONSTRAINT fk_payment_staff FOREIGN KEY (`staff_id`) REFERENCES sakila.staff (`staff_id`);

-- Ok (8 ms)

ALTER TABLE sakila.rental ADD CONSTRAINT fk_rental_customer FOREIGN KEY (`customer_id`) REFERENCES sakila.customer (`customer_id`);

-- Ok (10 ms)

ALTER TABLE sakila.rental ADD CONSTRAINT fk_rental_inventory FOREIGN KEY (`inventory_id`) REFERENCES sakila.inventory (`inventory_id`);

-- Ok (10 ms)

ALTER TABLE sakila.rental ADD CONSTRAINT fk_rental_staff FOREIGN KEY (`staff_id`) REFERENCES sakila.staff (`staff_id`);

-- Ok (10 ms)

ALTER TABLE sakila.staff ADD CONSTRAINT fk_staff_address FOREIGN KEY (`address_id`) REFERENCES sakila.address (`address_id`);

-- Ok (5 ms)

ALTER TABLE sakila.staff ADD CONSTRAINT fk_staff_store FOREIGN KEY (`store_id`) REFERENCES sakila.store (`store_id`);

-- Ok (4 ms)

ALTER TABLE sakila.store ADD CONSTRAINT fk_store_address FOREIGN KEY (`address_id`) REFERENCES sakila.address (`address_id`);

-- Ok (4 ms)

ALTER TABLE sakila.store ADD CONSTRAINT fk_store_staff FOREIGN KEY (`manager_staff_id`) REFERENCES sakila.staff (`staff_id`);

-- Ok (4 ms)

CREATE INDEX idx_actor_last_name ON sakila.actor (`last_name` ASC);

-- Ok (4 ms)

CREATE INDEX idx_fk_city_id ON sakila.address (`city_id` ASC);

-- Ok (4 ms)

CREATE INDEX idx_location ON sakila.address (`location` ASC);

-- Ok (5 ms)

CREATE INDEX idx_fk_country_id ON sakila.city (`country_id` ASC);

-- Ok (5 ms)

CREATE INDEX idx_fk_address_id ON sakila.customer (`address_id` ASC);

-- Ok (4 ms)

CREATE INDEX idx_fk_store_id ON sakila.customer (`store_id` ASC);

-- Ok (5 ms)

CREATE INDEX idx_last_name ON sakila.customer (`last_name` ASC);

-- Ok (5 ms)

CREATE INDEX idx_fk_language_id ON sakila.film (`language_id` ASC);

-- Ok (5 ms)

CREATE INDEX idx_fk_original_language_id ON sakila.film (`original_language_id` ASC);

-- Ok (4 ms)

CREATE INDEX idx_title ON sakila.film (`title` ASC);

-- Ok (6 ms)

CREATE INDEX idx_fk_film_id ON sakila.film_actor (`film_id` ASC);

-- Ok (8 ms)

CREATE INDEX fk_film_category_category ON sakila.film_category (`category_id` ASC);

-- Ok (7 ms)

CREATE INDEX idx_title_description ON sakila.film_text (`title` ASC, `description` ASC);

-- Failed (3 ms)
-- Specified key was too long; max key length is 3072 bytes

CREATE INDEX idx_fk_film_id ON sakila.inventory (`film_id` ASC);

-- Ok (6 ms)

CREATE INDEX idx_store_id_film_id ON sakila.inventory (`store_id` ASC, `film_id` ASC);

-- Ok (5 ms)

CREATE INDEX fk_payment_rental ON sakila.payment (`rental_id` ASC);

-- Ok (9 ms)

CREATE INDEX idx_fk_customer_id ON sakila.payment (`customer_id` ASC);

-- Ok (8 ms)

CREATE INDEX idx_fk_staff_id ON sakila.payment (`staff_id` ASC);

-- Ok (9 ms)

CREATE INDEX idx_fk_customer_id ON sakila.rental (`customer_id` ASC);

-- Ok (9 ms)

CREATE INDEX idx_fk_inventory_id ON sakila.rental (`inventory_id` ASC);

-- Ok (10 ms)

CREATE INDEX idx_fk_staff_id ON sakila.rental (`staff_id` ASC);

-- Ok (8 ms)

CREATE INDEX idx_fk_address_id ON sakila.staff (`address_id` ASC);

-- Ok (4 ms)

CREATE INDEX idx_fk_store_id ON sakila.staff (`store_id` ASC);

-- Ok (4 ms)

CREATE INDEX idx_fk_address_id ON sakila.store (`address_id` ASC);

-- Ok (5 ms)

ALTER TABLE sakila.rental ADD CONSTRAINT rental_date UNIQUE (`rental_date`, `inventory_id`, `customer_id`);

-- Ok (9 ms)

ALTER TABLE sakila.store ADD CONSTRAINT idx_unique_manager UNIQUE (`manager_staff_id`);

-- Ok (4 ms)