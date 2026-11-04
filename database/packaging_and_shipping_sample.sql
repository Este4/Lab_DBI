-- ============================================================================
-- Sample Data & Verification for Module 03: Packaging and Shipping
-- Course: DBI202 - Topic 3 Relational Database Design
-- ============================================================================

-- 1. Insert Staff Members
INSERT INTO staff (full_name, email, is_active) VALUES
    ('Nguyen Van An', 'an.nguyen@warehouse.com', TRUE),
    ('Tran Thi Bich', 'bich.tran@warehouse.com', TRUE),
    ('Le Hoang Nam', 'nam.le@warehouse.com', TRUE);

-- 2. Insert Shipping Carriers
INSERT INTO shipping_carrier (carrier_name, contact_phone) VALUES
    ('Giao Hang Tiet Kiem (GHTK)', '19006092'),
    ('Viettel Post', '19008095'),
    ('Vietnam Post (VNPost)', '1900545481'),
    ('Shopee Express (SPX)', '19001221');

-- 3. Insert Box Templates
INSERT INTO box_template (box_code, inner_length_cm, inner_width_cm, inner_height_cm, max_weight_gram, unit_cost) VALUES
    ('BOX-SMALL-01', 15.00, 10.00, 10.00, 1500.00, 2500.00),
    ('BOX-MEDIUM-02', 25.00, 20.00, 15.00, 5000.00, 5000.00),
    ('BOX-LARGE-03', 40.00, 30.00, 25.00, 15000.00, 12000.00),
    ('BOX-FLAT-04', 35.00, 25.00, 5.00, 2000.00, 4000.00);

-- 4. Insert Packaging Materials
INSERT INTO packaging_material (material_code, material_name, measure_unit, unit_cost) VALUES
    ('MAT-BUBBLE-50', 'Xop no chong soc (Bubble wrap 50cm)', 'METER', 1200.00),
    ('MAT-TAPE-CLEAR', 'Bang keo dong hang trong suot 5cm', 'ROLL', 15000.00),
    ('MAT-TAPE-FRAGILE', 'Bang keo canh bao hang de vo', 'ROLL', 18000.00),
    ('MAT-AIR-PILLOW', 'Tui khi chong va dap', 'PIECE', 500.00);

-- 5. Demonstration / Verification Queries
-- Query A: Total packaging cost per package (Box cost + Sum of Material costs)
-- SELECT 
--     p.package_id,
--     p.order_id,
--     b.box_code,
--     b.unit_cost AS box_cost,
--     COALESCE(SUM(pm.quantity_used * m.unit_cost), 0) AS total_material_cost,
--     b.unit_cost + COALESCE(SUM(pm.quantity_used * m.unit_cost), 0) AS total_packaging_cost
-- FROM package p
-- JOIN box_template b ON p.box_template_id = b.box_template_id
-- LEFT JOIN package_material pm ON p.package_id = pm.package_id
-- LEFT JOIN packaging_material m ON pm.material_id = m.material_id
-- GROUP BY p.package_id, p.order_id, b.box_code, b.unit_cost;

-- Query B: Package line items details with product info
-- SELECT 
--     p.package_id,
--     p.order_id,
--     p.packing_status,
--     ol.product_id,
--     pl.quantity_in_package
-- FROM package p
-- JOIN package_line pl ON p.package_id = pl.package_id
-- JOIN order_line ol ON pl.order_line_id = ol.order_line_id;

-- Query C: Shipment tracking summary
-- SELECT 
--     s.shipment_id,
--     s.tracking_number,
--     s.shipment_status,
--     s.shipping_fee,
--     s.handed_over_at,
--     p.package_id,
--     p.order_id
-- FROM shipment s
-- JOIN package p ON s.package_id = p.package_id;
