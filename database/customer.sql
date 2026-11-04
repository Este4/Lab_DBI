-- Module: 01 - Sales Channels and Orders
-- Description: Customer profile associated with a specific merchant sales account.
-- Ref: Lab4_Topic3.docx (Section 4.4.03)

CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    sales_account_id INT NOT NULL,
    external_customer_id VARCHAR(120),
    display_name VARCHAR(150) NOT NULL,
    contact_phone VARCHAR(30),

    CONSTRAINT fk_customer_sales_account FOREIGN KEY (sales_account_id)
        REFERENCES sales_account (sales_account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_customer_name_nonblank CHECK (LENGTH(TRIM(display_name)) > 0),
    CONSTRAINT ck_customer_phone CHECK (
        contact_phone IS NULL OR LENGTH(TRIM(contact_phone)) >= 8
    )
);

