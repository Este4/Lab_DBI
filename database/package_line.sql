-- Prerequisites: package.sql, order_line.sql.
-- Module: 03 - Packaging and Shipping
-- Description: M:N associative entity mapping order lines into packages.
-- Allows splitting large order quantities across multiple packages or combining lines into one package.

CREATE TABLE package_line (
    package_id INT NOT NULL,
    order_line_id INT NOT NULL,
    quantity_in_package INT NOT NULL,

    CONSTRAINT pk_package_line PRIMARY KEY (package_id, order_line_id),
    CONSTRAINT fk_package_line_package FOREIGN KEY (package_id)
        REFERENCES package (package_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_package_line_order_line FOREIGN KEY (order_line_id)
        REFERENCES order_line (order_line_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_package_line_quantity CHECK (quantity_in_package > 0)
);

-- Note:
-- The package and order line must belong to the SAME order (package.order_id = order_line.order_id).
-- The total SUM(quantity_in_package) across packages for an order line must not exceed order_line.quantity.
-- These cross-row/cross-table rules are enforced by application transactions or database triggers.
