-- Module: 03 - Packaging and Shipping
-- Description: Staff table to record personnel who pack, inspect, and approve packages or assign orders.
-- Referenced by: package (approved_by_staff_id), customer_order (assigned_by_staff_id).

CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(180),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_staff_email UNIQUE (email),
    CONSTRAINT ck_staff_full_name_nonblank CHECK (LENGTH(TRIM(full_name)) > 0),
    CONSTRAINT ck_staff_email_format CHECK (
        email IS NULL OR (LENGTH(TRIM(email)) > 0 AND email LIKE '%@%.%')
    )
);

