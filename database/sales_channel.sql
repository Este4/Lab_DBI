-- Module: 01 - Sales Channels and Orders
-- Description: External e-commerce platforms and channels (e.g., Shopee, Lazada, TikTok Shop).
-- Ref: Lab4_Topic3.docx (Section 4.4.01)

CREATE TABLE sales_channel (
    channel_id SERIAL PRIMARY KEY,
    channel_name VARCHAR(80) NOT NULL,
    channel_code VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_sales_channel_name UNIQUE (channel_name),
    CONSTRAINT uq_sales_channel_code UNIQUE (channel_code),
    CONSTRAINT ck_sales_channel_name_nonblank CHECK (LENGTH(TRIM(channel_name)) > 0),
    CONSTRAINT ck_sales_channel_code_nonblank CHECK (LENGTH(TRIM(channel_code)) > 0)
);
