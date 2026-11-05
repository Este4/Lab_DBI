-- Prerequisites: customer_order.sql, box_template.sql, staff.sql.
-- Module: 03 - Packaging and Shipping
-- Description: Records a physical parcel prepared for an order.
-- One customer order may be packed into 1..N packages.
-- Each package is assigned a specific box template and can be approved by a staff member.

CREATE TABLE package (
    package_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    box_template_id INT NOT NULL,
    packed_weight_gram DECIMAL(12,2),
    packing_status VARCHAR(30) NOT NULL DEFAULT 'PACKING',
    approved_by_staff_id INT,
    approved_at TIMESTAMP,

    CONSTRAINT fk_package_order FOREIGN KEY (order_id)
        REFERENCES customer_order (order_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_package_box_template FOREIGN KEY (box_template_id)
        REFERENCES box_template (box_template_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_package_staff FOREIGN KEY (approved_by_staff_id)
        REFERENCES staff (staff_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_package_packed_weight CHECK (
        packed_weight_gram IS NULL OR (packed_weight_gram > 0 AND packed_weight_gram <> 'NaN'::NUMERIC)
    ),
    CONSTRAINT ck_package_packing_status CHECK (
        packing_status IN ('PACKING', 'PACKED', 'APPROVED', 'CANCELLED')
    ),
    CONSTRAINT ck_package_approval_consistency CHECK (
        (packing_status = 'APPROVED' AND approved_by_staff_id IS NOT NULL AND approved_at IS NOT NULL)
        OR (packing_status <> 'APPROVED')
    )
);

-- Note:
-- Packed weight should typically not exceed box_template.max_weight_gram;
-- this cross-table validation is enforced via application/service logic or triggers.

