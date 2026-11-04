-- Module: 02 - Warehouses and Inventory
-- Description: Warehouse facilities storing physical inventory and fulfilling customer orders.
-- Ref: Lab4_Topic3.docx (Section 4.4.05)

CREATE TABLE warehouse (
    warehouse_id SERIAL PRIMARY KEY,
    warehouse_name VARCHAR(150) NOT NULL,
    warehouse_address VARCHAR(255) NOT NULL,

    CONSTRAINT ck_warehouse_name_nonblank CHECK (LENGTH(TRIM(warehouse_name)) > 0),
    CONSTRAINT ck_warehouse_address_nonblank CHECK (LENGTH(TRIM(warehouse_address)) > 0)
);
