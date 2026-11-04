-- Prerequisites: customer_order.sql and the existing shared product.sql.
-- MVP assumption: repeated source lines for one product are combined before import.
-- unit_price is the source unit price in the project's single agreed currency.
-- Changing lines after reservation requires the service to release/re-reserve stock atomically.
CREATE TABLE order_line (
    order_line_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_order_line_order FOREIGN KEY (order_id)
        REFERENCES customer_order (order_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_order_line_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT uq_order_line_order_product UNIQUE (order_id, product_id),
    CONSTRAINT ck_order_line_quantity CHECK (quantity > 0),
    CONSTRAINT ck_order_line_unit_price CHECK (unit_price >= 0 AND unit_price <> 'NaN'::NUMERIC)
);
