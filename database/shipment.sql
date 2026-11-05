-- Prerequisites: package.sql.
-- Module: 03 - Packaging and Shipping
-- Description: Shipment tracking entity for packages dispatched to logistics carriers.
-- Each shipment corresponds to exactly one approved package (1:1).

CREATE TABLE shipment (
    shipment_id SERIAL PRIMARY KEY,
    package_id INT NOT NULL,
    tracking_number VARCHAR(120),
    shipping_fee DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    shipment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    handed_over_at TIMESTAMP,
    status_updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_shipment_package UNIQUE (package_id),
    CONSTRAINT fk_shipment_package FOREIGN KEY (package_id)
        REFERENCES package (package_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_shipment_shipping_fee CHECK (
        shipping_fee >= 0 AND shipping_fee <> 'NaN'::NUMERIC
    ),
    CONSTRAINT ck_shipment_status CHECK (
        shipment_status IN ('PENDING', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED', 'FAILED', 'RETURNED')
    ),
    CONSTRAINT ck_shipment_tracking_nonblank CHECK (
        tracking_number IS NULL OR LENGTH(TRIM(tracking_number)) > 0
    ),
    CONSTRAINT ck_shipment_handover_consistency CHECK (
        (shipment_status = 'PENDING' AND handed_over_at IS NULL)
        OR (shipment_status <> 'PENDING' AND handed_over_at IS NOT NULL)
    )
);

-- Note:
-- Handover to carrier reduces both physical_quantity and reserved_quantity in inventory
-- and records a 'SHIPMENT' transaction in inventory_transaction within the same database transaction.

