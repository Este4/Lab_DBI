-- Module: 02 - Warehouses and Inventory
-- Description: Product master catalog with dimensional and fragility attributes.
-- Ref: Lab4_Topic3.docx (Section 4.4.04)

CREATE TABLE product (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(80) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    unit_weight_gram DECIMAL(12,2) NOT NULL,
    length_cm DECIMAL(10,2) NOT NULL,
    width_cm DECIMAL(10,2) NOT NULL,
    height_cm DECIMAL(10,2) NOT NULL,
    is_fragile BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT uq_product_sku UNIQUE (sku),
    CONSTRAINT ck_product_sku_nonblank CHECK (LENGTH(TRIM(sku)) > 0),
    CONSTRAINT ck_product_name_nonblank CHECK (LENGTH(TRIM(product_name)) > 0),
    CONSTRAINT ck_product_weight CHECK (unit_weight_gram > 0 AND unit_weight_gram <> 'NaN'::NUMERIC),
    CONSTRAINT ck_product_dimensions CHECK (
        length_cm > 0 AND
        width_cm > 0 AND
        height_cm > 0
    )
);
