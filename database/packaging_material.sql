-- Module: 03 - Packaging and Shipping
-- Description: Packaging materials inventory (bubble wrap, air pillows, packing tape, fragile stickers).
-- Referenced by: package_material (material_id).

CREATE TABLE packaging_material (
    material_id SERIAL PRIMARY KEY,
    material_code VARCHAR(80) NOT NULL,
    material_name VARCHAR(150) NOT NULL,
    measure_unit VARCHAR(30) NOT NULL,
    unit_cost DECIMAL(14,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT uq_packaging_material_code UNIQUE (material_code),
    CONSTRAINT ck_packaging_material_code_nonblank CHECK (LENGTH(TRIM(material_code)) > 0),
    CONSTRAINT ck_packaging_material_name_nonblank CHECK (LENGTH(TRIM(material_name)) > 0),
    CONSTRAINT ck_packaging_material_unit_nonblank CHECK (LENGTH(TRIM(measure_unit)) > 0),
    CONSTRAINT ck_packaging_material_unit_cost CHECK (unit_cost >= 0 AND unit_cost <> 'NaN'::NUMERIC)
);
