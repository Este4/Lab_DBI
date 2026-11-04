-- Module: 03 - Packaging and Shipping
-- Description: Shipping carrier table recording logistics partners (e.g., VNPost, ViettelPost, GHTK, SPX).
-- Referenced by: customer_order (carrier_id).

CREATE TABLE shipping_carrier (
    carrier_id SERIAL PRIMARY KEY,
    carrier_name VARCHAR(150) NOT NULL,
    contact_phone VARCHAR(30),

    CONSTRAINT uq_shipping_carrier_name UNIQUE (carrier_name),
    CONSTRAINT ck_shipping_carrier_name_nonblank CHECK (LENGTH(TRIM(carrier_name)) > 0),
    CONSTRAINT ck_shipping_carrier_phone CHECK (
        contact_phone IS NULL OR LENGTH(TRIM(contact_phone)) >= 8
    )
);
