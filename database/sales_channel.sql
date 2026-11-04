-- MVP assumption: channel_code identifies one external sales integration.
CREATE TABLE sales_channel (
    channel_id SERIAL PRIMARY KEY,
    channel_code VARCHAR(50) NOT NULL,
    channel_name VARCHAR(150) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_sales_channel_code UNIQUE (channel_code),
    CONSTRAINT ck_sales_channel_code_nonblank CHECK (LENGTH(TRIM(channel_code)) > 0),
    CONSTRAINT ck_sales_channel_name_nonblank CHECK (LENGTH(TRIM(channel_name)) > 0)
);
