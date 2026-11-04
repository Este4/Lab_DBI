-- Prerequisites: sales_channel.sql and warehouse.sql.
-- MVP assumptions: orders are imported from a channel; one order uses at most one warehouse.
-- Source provenance and status transitions must be controlled by the integration/service.
-- A RESERVED/SHIPPED status alone does not prove stock was reserved or shipped.
-- Reserve/ship must update this order and inventory in the same multi-table transaction.
CREATE TABLE customer_order (
    order_id SERIAL PRIMARY KEY,
    channel_id INT NOT NULL,
    external_order_id VARCHAR(100) NOT NULL,
    ordered_at TIMESTAMP NOT NULL,
    imported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    warehouse_id INT,
    order_status VARCHAR(20) NOT NULL DEFAULT 'IMPORTED',
    recipient_name VARCHAR(200) NOT NULL,
    delivery_address VARCHAR(500) NOT NULL,

    CONSTRAINT fk_customer_order_channel FOREIGN KEY (channel_id)
        REFERENCES sales_channel (channel_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_customer_order_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT uq_customer_order_channel_external UNIQUE (channel_id, external_order_id),
    CONSTRAINT ck_customer_order_external_nonblank CHECK (LENGTH(TRIM(external_order_id)) > 0),
    CONSTRAINT ck_customer_order_status CHECK (
        order_status IN ('IMPORTED', 'RESERVED', 'SHIPPED', 'CANCELLED')
    ),
    CONSTRAINT ck_customer_order_assigned_warehouse CHECK (
        order_status NOT IN ('RESERVED', 'SHIPPED') OR warehouse_id IS NOT NULL
    ),
    CONSTRAINT ck_customer_order_recipient_nonblank CHECK (LENGTH(TRIM(recipient_name)) > 0),
    CONSTRAINT ck_customer_order_address_nonblank CHECK (LENGTH(TRIM(delivery_address)) > 0)
);
