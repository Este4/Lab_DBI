-- Module: 01 - Sales Channels and Orders
-- Description: Individual integrated merchant stores belonging to a sales channel.
-- A single channel (e.g. Shopee) may host multiple merchant accounts.
-- Ref: Lab4_Topic3.docx (Section 4.4.02)

CREATE TABLE sales_account (
    sales_account_id SERIAL PRIMARY KEY,
    channel_id INT NOT NULL,
    external_shop_id VARCHAR(100) NOT NULL,
    shop_display_name VARCHAR(150) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_sales_account_channel FOREIGN KEY (channel_id)
        REFERENCES sales_channel (channel_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_sales_account_channel_shop UNIQUE (channel_id, external_shop_id),
    CONSTRAINT ck_sales_account_shop_id_nonblank CHECK (LENGTH(TRIM(external_shop_id)) > 0),
    CONSTRAINT ck_sales_account_name_nonblank CHECK (LENGTH(TRIM(shop_display_name)) > 0)
);

