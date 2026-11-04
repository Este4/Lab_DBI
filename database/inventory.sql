-- Requires: warehouse.sql, product.sql.
-- One row records one product's stock at one warehouse.
CREATE TABLE inventory (
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    physical_quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,

    CONSTRAINT pk_inventory PRIMARY KEY (warehouse_id, product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES product (product_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_inventory_physical_quantity CHECK (physical_quantity >= 0),
    CONSTRAINT ck_inventory_reserved_quantity CHECK (reserved_quantity >= 0),
    CONSTRAINT ck_inventory_reserved_limit CHECK (
        reserved_quantity <= physical_quantity
    )
);

-- Available stock = physical_quantity - reserved_quantity.
-- Reserving changes reserved_quantity only; it does not remove physical stock.
-- Handover reduces both quantities atomically, recording a SHIPMENT in the ledger.
-- These cross-table operations require a transaction in the application/service.
