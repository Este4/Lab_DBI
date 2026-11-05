-- ============================================================================
-- DBI202 - TOPIC 3: COMPLETE RELATIONAL SCHEMA DEFINITION
-- Description: Executes all 16 core relational tables in dependency order.
-- Ref: Lab4_Topic3.docx (Section 3.4 & Section 4.4)
-- ============================================================================

-- Drop tables in reverse dependency order if re-initializing
DROP TABLE IF EXISTS shipment CASCADE;
DROP TABLE IF EXISTS package_material CASCADE;
DROP TABLE IF EXISTS package_line CASCADE;
DROP TABLE IF EXISTS package CASCADE;
DROP TABLE IF EXISTS order_line CASCADE;
DROP TABLE IF EXISTS customer_order CASCADE;
DROP TABLE IF EXISTS inventory_transaction CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS sales_account CASCADE;
DROP TABLE IF EXISTS packaging_material CASCADE;
DROP TABLE IF EXISTS box_template CASCADE;
DROP TABLE IF EXISTS shipping_carrier CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS warehouse CASCADE;
DROP TABLE IF EXISTS sales_channel CASCADE;

-- 1. SALES_CHANNEL (4.4.01)
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

-- 2. WAREHOUSE (4.4.05)
CREATE TABLE warehouse (
    warehouse_id SERIAL PRIMARY KEY,
    warehouse_name VARCHAR(150) NOT NULL,
    warehouse_address VARCHAR(255) NOT NULL,

    CONSTRAINT ck_warehouse_name_nonblank CHECK (LENGTH(TRIM(warehouse_name)) > 0),
    CONSTRAINT ck_warehouse_address_nonblank CHECK (LENGTH(TRIM(warehouse_address)) > 0)
);

-- 3. PRODUCT (4.4.04)
CREATE TABLE product (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(80) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    unit_weight_gram DECIMAL(12,2) NOT NULL,
    length_cm DECIMAL(10,2) NOT NULL,
    width_cm DECIMAL(10,2) NOT NULL,
    height_cm DECIMAL(10,2) NOT NULL,
    is_fragile BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT uq_product_sku UNIQUE (sku),
    CONSTRAINT ck_product_sku_nonblank CHECK (LENGTH(TRIM(sku)) > 0),
    CONSTRAINT ck_product_name_nonblank CHECK (LENGTH(TRIM(product_name)) > 0),
    CONSTRAINT ck_product_weight CHECK (unit_weight_gram > 0 AND unit_weight_gram <> 'NaN'::NUMERIC),
    CONSTRAINT ck_product_dimensions CHECK (
        length_cm > 0 AND
        width_cm > 0 AND
        height_cm > 0
    )
);

-- 4. STAFF (4.4.07)
CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(180),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_staff_email UNIQUE (email),
    CONSTRAINT ck_staff_full_name_nonblank CHECK (LENGTH(TRIM(full_name)) > 0),
    CONSTRAINT ck_staff_email_format CHECK (
        email IS NULL OR (LENGTH(TRIM(email)) > 0 AND email LIKE '%@%.%')
    )
);

-- 5. SHIPPING_CARRIER (4.4.08)
CREATE TABLE shipping_carrier (
    carrier_id SERIAL PRIMARY KEY,
    carrier_name VARCHAR(150) NOT NULL,
    contact_phone VARCHAR(30),

    CONSTRAINT uq_shipping_carrier_name UNIQUE (carrier_name),
    CONSTRAINT ck_shipping_carrier_name_nonblank CHECK (LENGTH(TRIM(carrier_name)) > 0),
    CONSTRAINT ck_shipping_carrier_phone CHECK (
        contact_phone IS NULL OR LENGTH(TRIM(contact_phone)) >= 8
    )
);

-- 6. BOX_TEMPLATE (4.4.11)
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

-- 7. PACKAGING_MATERIAL (4.4.12)
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

-- 8. SALES_ACCOUNT (4.4.02)
CREATE TABLE sales_account (
    sales_account_id SERIAL PRIMARY KEY,
    channel_id INT NOT NULL,
    external_shop_id VARCHAR(100) NOT NULL,
    shop_display_name VARCHAR(150) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_sales_account_channel FOREIGN KEY (channel_id)
        REFERENCES sales_channel (channel_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_sales_account_channel_shop UNIQUE (channel_id, external_shop_id),
    CONSTRAINT ck_sales_account_shop_id_nonblank CHECK (LENGTH(TRIM(external_shop_id)) > 0),
    CONSTRAINT ck_sales_account_name_nonblank CHECK (LENGTH(TRIM(shop_display_name)) > 0)
);

-- 9. INVENTORY (4.4.06)
CREATE TABLE inventory (
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    physical_qty INT NOT NULL DEFAULT 0,
    reserved_qty INT NOT NULL DEFAULT 0,

    CONSTRAINT pk_inventory PRIMARY KEY (warehouse_id, product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES product (product_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_inventory_physical_qty CHECK (physical_qty >= 0),
    CONSTRAINT ck_inventory_reserved_qty CHECK (reserved_qty >= 0),
    CONSTRAINT ck_inventory_reserved_limit CHECK (
        reserved_qty <= physical_qty
    )
);

-- 10. CUSTOMER (4.4.03)
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    sales_account_id INT NOT NULL,
    external_customer_id VARCHAR(120),
    display_name VARCHAR(150) NOT NULL,
    contact_phone VARCHAR(30),

    CONSTRAINT fk_customer_sales_account FOREIGN KEY (sales_account_id)
        REFERENCES sales_account (sales_account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_customer_name_nonblank CHECK (LENGTH(TRIM(display_name)) > 0),
    CONSTRAINT ck_customer_phone CHECK (
        contact_phone IS NULL OR LENGTH(TRIM(contact_phone)) >= 8
    )
);

-- 11. CUSTOMER_ORDER (4.4.09)
CREATE TABLE customer_order (
    order_id SERIAL PRIMARY KEY,
    sales_account_id INT NOT NULL,
    external_order_id VARCHAR(100) NOT NULL,
    customer_id INT,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recipient_name VARCHAR(150) NOT NULL,
    recipient_phone VARCHAR(30),
    delivery_address VARCHAR(255) NOT NULL,
    priority VARCHAR(25) NOT NULL DEFAULT 'STANDARD',
    order_status VARCHAR(35) NOT NULL DEFAULT 'IMPORTED',
    assigned_warehouse_id INT,
    assigned_by_staff_id INT,
    assigned_at TIMESTAMP,
    carrier_id INT,

    CONSTRAINT fk_customer_order_sales_account FOREIGN KEY (sales_account_id)
        REFERENCES sales_account (sales_account_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_order_customer FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_order_warehouse FOREIGN KEY (assigned_warehouse_id)
        REFERENCES warehouse (warehouse_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_order_staff FOREIGN KEY (assigned_by_staff_id)
        REFERENCES staff (staff_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_customer_order_carrier FOREIGN KEY (carrier_id)
        REFERENCES shipping_carrier (carrier_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_customer_order_account_external UNIQUE (sales_account_id, external_order_id),
    CONSTRAINT ck_customer_order_external_nonblank CHECK (LENGTH(TRIM(external_order_id)) > 0),
    CONSTRAINT ck_customer_order_recipient_nonblank CHECK (LENGTH(TRIM(recipient_name)) > 0),
    CONSTRAINT ck_customer_order_address_nonblank CHECK (LENGTH(TRIM(delivery_address)) > 0),
    CONSTRAINT ck_customer_order_priority CHECK (
        priority IN ('STANDARD', 'HIGH', 'EXPRESS')
    ),
    CONSTRAINT ck_customer_order_status CHECK (
        order_status IN ('IMPORTED', 'ASSIGNED', 'PACKING', 'PACKED', 'SHIPPED', 'DELIVERED', 'CANCELLED')
    ),
    CONSTRAINT ck_customer_order_assignment CHECK (
        order_status NOT IN ('ASSIGNED', 'PACKING', 'PACKED', 'SHIPPED')
        OR assigned_warehouse_id IS NOT NULL
    )
);

-- 12. ORDER_LINE (4.4.10)
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

-- 13. PACKAGE (4.4.13)
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

-- 14. PACKAGE_LINE (4.4.14)
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

-- 15. PACKAGE_MATERIAL (4.4.15)
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

-- 16. SHIPMENT (4.4.16)
CREATE TABLE shipment (
    shipment_id SERIAL PRIMARY KEY,
    package_id INT NOT NULL,
    tracking_number VARCHAR(120),
    shipping_fee DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    shipment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    handed_over_at TIMESTAMP,
    status_updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_shipment_package UNIQUE (package_id),
    CONSTRAINT fk_shipment_package FOREIGN KEY (package_id)
        REFERENCES package (package_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_shipment_shipping_fee CHECK (
        shipping_fee >= 0 AND shipping_fee <> 'NaN'::NUMERIC
    ),
    CONSTRAINT ck_shipment_status CHECK (
        shipment_status IN ('PENDING', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED', 'FAILED', 'RETURNED')
    ),
    CONSTRAINT ck_shipment_tracking_nonblank CHECK (
        tracking_number IS NULL OR LENGTH(TRIM(tracking_number)) > 0
    ),
    CONSTRAINT ck_shipment_handover_consistency CHECK (
        (shipment_status = 'PENDING' AND handed_over_at IS NULL)
        OR (shipment_status <> 'PENDING' AND handed_over_at IS NOT NULL)
    )
);

-- All business writers must use these routines and the package routines.
-- Invoker rights; capture the installation search_path. No COMMIT inside functions.
CREATE FUNCTION reserve_order(p_order_id INT, p_warehouse_id INT) RETURNS BOOLEAN
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE o customer_order%ROWTYPE; d RECORD; affected INT;
BEGIN
    SELECT * INTO STRICT o FROM customer_order WHERE order_id=p_order_id FOR UPDATE;
    IF p_warehouse_id IS NULL THEN RAISE EXCEPTION 'Can chon kho'; END IF;
    IF o.order_status NOT IN ('IMPORTED','ASSIGNED','PACKING','PACKED') THEN
        RAISE EXCEPTION 'Trang thai don khong cho giu hang';
    END IF;
    PERFORM 1 FROM order_line WHERE order_id=p_order_id ORDER BY order_line_id FOR UPDATE;
    IF NOT EXISTS (SELECT 1 FROM order_line WHERE order_id=p_order_id) THEN
        RAISE EXCEPTION 'Don chua co san pham';
    END IF;
    IF o.assigned_warehouse_id=p_warehouse_id AND NOT EXISTS (
        SELECT 1 FROM order_line WHERE order_id=p_order_id AND reserved_qty<>quantity_ordered
    ) THEN RETURN FALSE; END IF; -- Already fully reserved: no second allocation.
    IF o.order_status NOT IN ('IMPORTED','ASSIGNED') OR EXISTS (
        SELECT 1 FROM order_line WHERE order_id=p_order_id AND reserved_qty<>0
    ) THEN RAISE EXCEPTION 'Don dang giu/da dong goi; khong duoc giu them'; END IF;
    PERFORM 1 FROM warehouse WHERE warehouse_id=p_warehouse_id FOR KEY SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Kho khong ton tai'; END IF;
    -- Stable product order prevents routine callers locking the same stocks in reverse order.
    PERFORM i.product_id FROM inventory i WHERE i.warehouse_id=p_warehouse_id
      AND i.product_id IN (SELECT product_id FROM order_line WHERE order_id=p_order_id)
      ORDER BY i.product_id FOR UPDATE;
    FOR d IN SELECT product_id, SUM(quantity_ordered)::INT AS needed
        FROM order_line WHERE order_id=p_order_id GROUP BY product_id ORDER BY product_id
    LOOP
        UPDATE inventory SET reserved_qty=reserved_qty+d.needed
        WHERE warehouse_id=p_warehouse_id AND product_id=d.product_id
          AND physical_qty-reserved_qty>=d.needed;
        GET DIAGNOSTICS affected=ROW_COUNT;
        IF affected<>1 THEN RAISE EXCEPTION 'Khong du hang san pham %', d.product_id; END IF;
    END LOOP;
    UPDATE order_line SET reserved_qty=quantity_ordered WHERE order_id=p_order_id;
    UPDATE customer_order SET assigned_warehouse_id=p_warehouse_id,
        assigned_at=CURRENT_TIMESTAMP,order_status='ASSIGNED' WHERE order_id=p_order_id;
    RETURN TRUE;
END $$;

CREATE FUNCTION cancel_order(p_order_id INT) RETURNS BOOLEAN
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE o customer_order%ROWTYPE; d RECORD; affected INT;
BEGIN
    SELECT * INTO STRICT o FROM customer_order WHERE order_id=p_order_id FOR UPDATE;
    IF o.order_status='CANCELLED' THEN RETURN FALSE; END IF;
    IF o.order_status IN ('SHIPPED','DELIVERED') OR EXISTS (
        SELECT 1 FROM shipment s JOIN package p USING(package_id)
        WHERE p.order_id=p_order_id AND s.handed_over_at IS NOT NULL
    ) THEN RAISE EXCEPTION 'Da ban giao, khong huy theo luong nay'; END IF;
    PERFORM 1 FROM order_line WHERE order_id=p_order_id ORDER BY order_line_id FOR UPDATE;
    PERFORM i.product_id FROM inventory i WHERE i.warehouse_id=o.assigned_warehouse_id
      AND i.product_id IN (SELECT product_id FROM order_line WHERE order_id=p_order_id)
      ORDER BY i.product_id FOR UPDATE;
    FOR d IN SELECT product_id,SUM(reserved_qty)::INT qty FROM order_line
        WHERE order_id=p_order_id GROUP BY product_id HAVING SUM(reserved_qty)>0 ORDER BY product_id
    LOOP
        UPDATE inventory SET reserved_qty=reserved_qty-d.qty
        WHERE warehouse_id=o.assigned_warehouse_id AND product_id=d.product_id AND reserved_qty>=d.qty;
        GET DIAGNOSTICS affected=ROW_COUNT;
        IF affected<>1 THEN RAISE EXCEPTION 'Du lieu giu hang khong khop'; END IF;
    END LOOP;
    UPDATE order_line SET reserved_qty=0 WHERE order_id=p_order_id;
    UPDATE package SET packing_status='CANCELLED' WHERE order_id=p_order_id;
    UPDATE customer_order SET order_status='CANCELLED' WHERE order_id=p_order_id;
    RETURN TRUE;
END $$;

CREATE FUNCTION change_order_warehouse(p_order_id INT,p_new_warehouse_id INT) RETURNS BOOLEAN
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE o customer_order%ROWTYPE; active_packages INT[];
BEGIN
    SELECT * INTO STRICT o FROM customer_order WHERE order_id=p_order_id FOR UPDATE;
    IF o.assigned_warehouse_id=p_new_warehouse_id THEN
        RETURN reserve_order(p_order_id,p_new_warehouse_id);
    END IF;
    IF o.order_status NOT IN ('IMPORTED','ASSIGNED') OR EXISTS (
        SELECT 1 FROM package_line pl JOIN package p USING(package_id) WHERE p.order_id=p_order_id
    ) THEN RAISE EXCEPTION 'Chi doi kho truoc khi dong goi'; END IF;
    PERFORM 1 FROM order_line WHERE order_id=p_order_id ORDER BY order_line_id FOR UPDATE;
    PERFORM i.product_id FROM inventory i
      WHERE i.warehouse_id IN (o.assigned_warehouse_id,p_new_warehouse_id)
        AND i.product_id IN (SELECT product_id FROM order_line WHERE order_id=p_order_id)
      ORDER BY i.warehouse_id,i.product_id FOR UPDATE;
    SELECT ARRAY_AGG(package_id) INTO active_packages FROM package
      WHERE order_id=p_order_id AND packing_status<>'CANCELLED';
    -- Reuse release logic; an error in re-reservation rolls the WHOLE function back.
    PERFORM cancel_order(p_order_id);
    UPDATE customer_order SET order_status='IMPORTED',assigned_warehouse_id=NULL WHERE order_id=p_order_id;
    UPDATE package SET packing_status='PACKING' WHERE package_id=ANY(active_packages);
    RETURN reserve_order(p_order_id,p_new_warehouse_id);
END $$;

CREATE FUNCTION stock_movement(p_warehouse_id INT,p_product_id INT,p_type VARCHAR,
    p_delta INT,p_event_code VARCHAR) RETURNS BOOLEAN
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE prior inventory_transaction%ROWTYPE; affected INT; event_ref VARCHAR(100);
BEGIN
    IF p_type IS NULL OR p_type NOT IN ('RECEIPT','ADJUSTMENT') OR p_delta IS NULL
       OR p_delta=0 OR (p_type='RECEIPT' AND p_delta<0) THEN
        RAISE EXCEPTION 'Loai/so luong bien dong khong hop le';
    END IF;
    IF p_event_code IS NULL OR LENGTH(TRIM(p_event_code))=0 OR LENGTH(p_event_code)>80 THEN
        RAISE EXCEPTION 'Can ma su kien khong rong, toi da 80 ky tu';
    END IF;
    event_ref:='stock:'||p_event_code;
    INSERT INTO inventory(warehouse_id,product_id) VALUES(p_warehouse_id,p_product_id)
        ON CONFLICT (warehouse_id,product_id) DO NOTHING;
    PERFORM 1 FROM inventory WHERE warehouse_id=p_warehouse_id AND product_id=p_product_id FOR UPDATE;
    SELECT * INTO prior FROM inventory_transaction WHERE warehouse_id=p_warehouse_id
        AND product_id=p_product_id AND reference_code=event_ref;
    IF FOUND THEN
        IF prior.transaction_type=p_type AND prior.quantity_change=p_delta THEN RETURN FALSE; END IF;
        RAISE EXCEPTION 'Ma su kien da dung voi noi dung khac';
    END IF;
    UPDATE inventory SET physical_qty=physical_qty+p_delta
        WHERE warehouse_id=p_warehouse_id AND product_id=p_product_id
          AND physical_qty::BIGINT+p_delta>=reserved_qty;
    GET DIAGNOSTICS affected=ROW_COUNT;
    IF affected<>1 THEN RAISE EXCEPTION 'Khong the giam ton xuong duoi luong giu'; END IF;
    INSERT INTO inventory_transaction(warehouse_id,product_id,transaction_type,quantity_change,reference_code)
        VALUES(p_warehouse_id,p_product_id,p_type,p_delta,event_ref);
    RETURN TRUE;
END $$;

