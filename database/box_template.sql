-- Module: 03 - Packaging and Shipping
-- Description: Standard carton box templates used for packing goods.
-- Provides inner dimensions (length x width x height) and maximum weight capacity.
-- Referenced by: package (box_template_id).

CREATE TABLE box_template (
    box_template_id SERIAL PRIMARY KEY,
    box_code VARCHAR(80) NOT NULL,
    inner_length_cm DECIMAL(10,2) NOT NULL,
    inner_width_cm DECIMAL(10,2) NOT NULL,
    inner_height_cm DECIMAL(10,2) NOT NULL,
    max_weight_gram DECIMAL(12,2) NOT NULL,
    unit_cost DECIMAL(14,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT uq_box_template_code UNIQUE (box_code),
    CONSTRAINT ck_box_template_code_nonblank CHECK (LENGTH(TRIM(box_code)) > 0),
    CONSTRAINT ck_box_template_dimensions CHECK (
        inner_length_cm > 0 AND
        inner_width_cm > 0 AND
        inner_height_cm > 0
    ),
    CONSTRAINT ck_box_template_max_weight CHECK (max_weight_gram > 0),
    CONSTRAINT ck_box_template_unit_cost CHECK (unit_cost >= 0 AND unit_cost <> 'NaN'::NUMERIC)
);

