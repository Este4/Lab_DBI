-- Module: 01 - Sales Channels and Orders
-- Description: Individual itemized product lines within an order.
-- Ref: Lab4_Topic3.docx (Section 4.4.10)
-- Prerequisites: customer_order.sql, product.sql.

CREATE TABLE order_line (
    order_line_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    line_no INT NOT NULL,
    product_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    unit_price_at_order DECIMAL(14,2) NOT NULL,
    reserved_qty INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_order_line_order FOREIGN KEY (order_id)
        REFERENCES customer_order (order_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_order_line_product FOREIGN KEY (product_id)
        REFERENCES product (product_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_order_line_order_line_no UNIQUE (order_id, line_no),
    CONSTRAINT ck_order_line_no CHECK (line_no > 0),
    CONSTRAINT ck_order_line_quantity CHECK (quantity_ordered > 0),
    CONSTRAINT ck_order_line_unit_price CHECK (
        unit_price_at_order >= 0 AND unit_price_at_order <> 'NaN'::NUMERIC
    ),
    CONSTRAINT ck_order_line_reserved CHECK (
        reserved_qty >= 0 AND reserved_qty <= quantity_ordered
    )
);
