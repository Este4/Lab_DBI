-- Prerequisites: package.sql, packaging_material.sql.
-- Module: 03 - Packaging and Shipping
-- Description: M:N associative entity recording packaging materials consumed by each package.
-- Supports accurate packaging cost calculation and consumable inventory deduction.

CREATE TABLE package_material (
    package_id INT NOT NULL,
    material_id INT NOT NULL,
    quantity_used DECIMAL(12,3) NOT NULL,

    CONSTRAINT pk_package_material PRIMARY KEY (package_id, material_id),
    CONSTRAINT fk_package_material_package FOREIGN KEY (package_id)
        REFERENCES package (package_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_package_material_material FOREIGN KEY (material_id)
        REFERENCES packaging_material (material_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_package_material_quantity CHECK (
        quantity_used > 0 AND quantity_used <> 'NaN'::NUMERIC
    )
);

