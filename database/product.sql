CREATE TABLE product (
	product_id SERIAL PRIMARY KEY,
	sku VARCHAR(80) not null unique,
	product_name VARCHAR(200) NOT NULL,
	unit_weight DECIMAL(12,2) NOT NULL,
	length_cm DECIMAL(12,2) NOT NULL,
	width_cm DECIMAL(12,2) NOT NULL,
	height_cm DECIMAL(12,2) NOT NULL,
	is_fragile BOOLEAN NOT NULL, 
	
	CONSTRAINT ck_product_weight check(unit_weight > 0),
	CONSTRAINT ck_product CHECK(
		length_cm > 0 AND
		width_cm > 0 AND
		height_cm > 0)
);