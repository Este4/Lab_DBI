-- Chỉ chạy một lần trong database học tập. Tạo schema riêng; không xóa bảng cũ.
BEGIN;
CREATE SCHEMA dbi202_live;
SET LOCAL search_path TO dbi202_live;

-- SOURCE: sales_channel.sql
-- Module: 01 - Sales Channels and Orders
-- Description: External e-commerce platforms and channels (e.g., Shopee, Lazada, TikTok Shop).
-- Ref: Lab4_Topic3.docx (Section 4.4.01)

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

-- SOURCE: warehouse.sql
-- Module: 02 - Warehouses and Inventory
-- Description: Warehouse facilities storing physical inventory and fulfilling customer orders.
-- Ref: Lab4_Topic3.docx (Section 4.4.05)

CREATE TABLE warehouse (
    warehouse_id SERIAL PRIMARY KEY,
    warehouse_name VARCHAR(150) NOT NULL,
    warehouse_address VARCHAR(255) NOT NULL,

    CONSTRAINT ck_warehouse_name_nonblank CHECK (LENGTH(TRIM(warehouse_name)) > 0),
    CONSTRAINT ck_warehouse_address_nonblank CHECK (LENGTH(TRIM(warehouse_address)) > 0)
);

-- SOURCE: product.sql
-- Module: 02 - Warehouses and Inventory
-- Description: Product master catalog with dimensional and fragility attributes.
-- Ref: Lab4_Topic3.docx (Section 4.4.04)

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

-- SOURCE: staff.sql
-- Module: 03 - Packaging and Shipping
-- Description: Staff table to record personnel who pack, inspect, and approve packages or assign orders.
-- Referenced by: package (approved_by_staff_id), customer_order (assigned_by_staff_id).

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


-- SOURCE: shipping_carrier.sql
-- Module: 03 - Packaging and Shipping
-- Description: Shipping carrier table recording logistics partners (e.g., VNPost, ViettelPost, GHTK, SPX).
-- Referenced by: customer_order (carrier_id).

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


-- SOURCE: box_template.sql
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


-- SOURCE: packaging_material.sql
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


-- SOURCE: sales_account.sql
-- Module: 01 - Sales Channels and Orders
-- Description: Individual integrated merchant stores belonging to a sales channel.
-- A single channel (e.g. Shopee) may host multiple merchant accounts.
-- Ref: Lab4_Topic3.docx (Section 4.4.02)

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


-- SOURCE: inventory.sql
-- Module: 02 - Warehouses and Inventory
-- Description: Stock balances per warehouse and product (physical and reserved).
-- Ref: Lab4_Topic3.docx (Section 4.4.06)
-- Prerequisites: warehouse.sql, product.sql.

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

-- SOURCE: customer.sql
-- Module: 01 - Sales Channels and Orders
-- Description: Customer profile associated with a specific merchant sales account.
-- Ref: Lab4_Topic3.docx (Section 4.4.03)

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


-- SOURCE: customer_order.sql
-- Module: 01 - Sales Channels and Orders
-- Description: Customer orders placed via sales accounts, assigned to warehouses and carriers.
-- Ref: Lab4_Topic3.docx (Section 4.4.09)
-- Prerequisites: sales_account.sql, customer.sql, warehouse.sql, staff.sql, shipping_carrier.sql.

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

-- SOURCE: order_line.sql
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

-- SOURCE: package.sql
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


-- SOURCE: package_line.sql
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


-- SOURCE: package_material.sql
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


-- SOURCE: shipment.sql
-- Prerequisites: package.sql.
-- Module: 03 - Packaging and Shipping
-- Description: Shipment tracking entity for packages dispatched to logistics carriers.
-- Each shipment corresponds to exactly one approved package (1:1).

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

-- Note:
-- Handover to carrier reduces both physical_quantity and reserved_quantity in inventory
-- and records a 'SHIPMENT' transaction in inventory_transaction within the same database transaction.


-- SOURCE: inventory_transaction.sql
-- Requires: inventory.sql.
-- Records PHYSICAL stock changes only; reservations do not create ledger rows.
-- MVP assumption: quantity_change is a signed delta in whole product units.
CREATE TABLE inventory_transaction (
    inventory_transaction_id SERIAL PRIMARY KEY,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    quantity_change INT NOT NULL,
    occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_code VARCHAR(100),
    notes VARCHAR(500),

    CONSTRAINT fk_inventory_transaction_inventory
        FOREIGN KEY (warehouse_id, product_id)
        REFERENCES inventory (warehouse_id, product_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_inventory_transaction_type CHECK (
        transaction_type IN ('RECEIPT', 'SHIPMENT', 'ADJUSTMENT')
    ),
    CONSTRAINT ck_inventory_transaction_nonzero CHECK (quantity_change <> 0),
    CONSTRAINT ck_inventory_transaction_direction CHECK (
        (transaction_type = 'RECEIPT' AND quantity_change > 0)
        OR (transaction_type = 'SHIPMENT' AND quantity_change < 0)
        OR transaction_type = 'ADJUSTMENT'
    ),
    CONSTRAINT ck_inventory_transaction_reference CHECK (
        reference_code IS NULL OR LENGTH(TRIM(reference_code)) > 0
    )
);

-- reference_code can identify an upstream receipt, shipment, or adjustment.
-- It is descriptive, not a foreign key to Packaging/Shipping or CUSTOMER_ORDER.
-- The service must change inventory and insert its ledger row in ONE transaction.
-- CHECK/FK constraints cannot ensure ledger completeness or derive the stock balance.

-- BUSINESS REVIEW: 01_additional_constraints.sql
-- REVIEW ONLY. Requires all 17 tables from main commit 2f5a6ab.
-- Additive migration; deliberately fails on incompatible/invalid existing data.
-- Do not run this against the old feature/warehouse schema.
ALTER TABLE product ADD CONSTRAINT ck_product_dimensions_finite CHECK (
    length_cm <> 'NaN'::NUMERIC AND width_cm <> 'NaN'::NUMERIC AND height_cm <> 'NaN'::NUMERIC
);
ALTER TABLE box_template ADD CONSTRAINT ck_box_measurements_finite CHECK (
    inner_length_cm <> 'NaN'::NUMERIC AND inner_width_cm <> 'NaN'::NUMERIC
    AND inner_height_cm <> 'NaN'::NUMERIC AND max_weight_gram <> 'NaN'::NUMERIC
);
ALTER TABLE customer_order ADD CONSTRAINT ck_delivered_order_warehouse CHECK (
    order_status <> 'DELIVERED' OR assigned_warehouse_id IS NOT NULL
);
-- This pair is required as the target of a composite FK, not a duplicate PK index.
ALTER TABLE customer ADD CONSTRAINT uq_customer_id_account UNIQUE (customer_id, sales_account_id);
ALTER TABLE customer_order ADD CONSTRAINT fk_order_customer_same_account
    FOREIGN KEY (customer_id, sales_account_id)
    REFERENCES customer (customer_id, sales_account_id) ON UPDATE RESTRICT ON DELETE RESTRICT;
-- A non-null event reference identifies one movement per stock pair.
ALTER TABLE inventory_transaction ADD CONSTRAINT uq_inventory_event
    UNIQUE (warehouse_id, product_id, reference_code);

-- BUSINESS REVIEW: 02_stock_and_orders.sql
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

-- BUSINESS REVIEW: 03_packages_and_shipping.sql
-- Order is always locked before its packages/lines/stocks.
CREATE FUNCTION _lock_package_order(p_package_id INT) RETURNS INT
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE oid INT; actual_oid INT;
BEGIN
    SELECT order_id INTO STRICT oid FROM package WHERE package_id=p_package_id;
    PERFORM 1 FROM customer_order WHERE order_id=oid FOR UPDATE;
    SELECT order_id INTO STRICT actual_oid FROM package WHERE package_id=p_package_id FOR UPDATE;
    IF actual_oid<>oid THEN RAISE EXCEPTION 'Kien da doi don trong luc xu ly'; END IF;
    RETURN oid;
END $$;

CREATE FUNCTION create_package(p_order_id INT,p_box_id INT) RETURNS INT
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE o customer_order%ROWTYPE; pid INT;
BEGIN
    SELECT * INTO STRICT o FROM customer_order WHERE order_id=p_order_id FOR UPDATE;
    IF o.order_status NOT IN ('ASSIGNED','PACKING') OR NOT EXISTS (
        SELECT 1 FROM order_line WHERE order_id=p_order_id
    ) OR EXISTS (SELECT 1 FROM order_line WHERE order_id=p_order_id AND reserved_qty<>quantity_ordered)
    THEN RAISE EXCEPTION 'Can giu du hang truoc khi tao kien'; END IF;
    INSERT INTO package(order_id,box_template_id) VALUES(p_order_id,p_box_id) RETURNING package_id INTO pid;
    UPDATE customer_order SET order_status='PACKING' WHERE order_id=p_order_id;
    RETURN pid;
END $$;

CREATE FUNCTION set_package_line(p_package_id INT,p_order_line_id INT,p_quantity INT) RETURNS VOID
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE oid INT; p package%ROWTYPE; l order_line%ROWTYPE; other_qty BIGINT;
BEGIN
    oid:=_lock_package_order(p_package_id);
    SELECT * INTO STRICT p FROM package WHERE package_id=p_package_id;
    SELECT * INTO STRICT l FROM order_line WHERE order_line_id=p_order_line_id FOR UPDATE;
    IF l.order_id<>oid THEN RAISE EXCEPTION 'Dong hang khong thuoc don cua kien'; END IF;
    IF p.packing_status<>'PACKING' OR (SELECT order_status FROM customer_order WHERE order_id=oid)
        NOT IN ('ASSIGNED','PACKING') THEN RAISE EXCEPTION 'Kien/don khong con cho sua'; END IF;
    IF p_quantity IS NULL OR p_quantity<=0 THEN RAISE EXCEPTION 'So luong phai duong'; END IF;
    SELECT COALESCE(SUM(pl.quantity_in_package),0) INTO other_qty
    FROM package_line pl JOIN package other USING(package_id)
    WHERE pl.order_line_id=p_order_line_id AND pl.package_id<>p_package_id AND other.packing_status<>'CANCELLED';
    IF other_qty+p_quantity>l.quantity_ordered OR other_qty+p_quantity>l.reserved_qty THEN
        RAISE EXCEPTION 'Dong goi vuot luong dat/da giu';
    END IF;
    INSERT INTO package_line(package_id,order_line_id,quantity_in_package)
        VALUES(p_package_id,p_order_line_id,p_quantity)
        ON CONFLICT (package_id,order_line_id) DO UPDATE SET quantity_in_package=EXCLUDED.quantity_in_package;
    UPDATE customer_order SET order_status='PACKING' WHERE order_id=oid;
END $$;

CREATE FUNCTION approve_package(p_package_id INT,p_staff_id INT,p_weight DECIMAL) RETURNS BOOLEAN
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE oid INT; p package%ROWTYPE; limit_weight DECIMAL; goods_weight DECIMAL;
BEGIN
    p_weight:=ROUND(p_weight,2);
    oid:=_lock_package_order(p_package_id);
    SELECT * INTO STRICT p FROM package WHERE package_id=p_package_id;
    IF p.packing_status='APPROVED' THEN
        IF p.approved_by_staff_id=p_staff_id AND p.packed_weight_gram=p_weight THEN RETURN FALSE; END IF;
        RAISE EXCEPTION 'Kien da duyet voi noi dung khac';
    END IF;
    IF p.packing_status NOT IN ('PACKING','PACKED') OR (SELECT order_status FROM customer_order WHERE order_id=oid)
       NOT IN ('ASSIGNED','PACKING','PACKED') THEN RAISE EXCEPTION 'Khong the duyet kien nay'; END IF;
    PERFORM 1 FROM staff WHERE staff_id=p_staff_id AND is_active FOR SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Nhan vien khong hoat dong/khong ton tai'; END IF;
    SELECT max_weight_gram INTO STRICT limit_weight FROM box_template WHERE box_template_id=p.box_template_id FOR SHARE;
    IF p_weight IS NULL OR p_weight<=0 OR p_weight='NaN'::NUMERIC OR p_weight>limit_weight THEN
        RAISE EXCEPTION 'Khoi luong kien khong hop le/qua gioi han hop';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM package_line WHERE package_id=p_package_id) THEN RAISE EXCEPTION 'Kien rong'; END IF;
    IF EXISTS (SELECT 1 FROM package_line pl JOIN order_line l USING(order_line_id)
        WHERE pl.package_id=p_package_id AND l.order_id<>oid) THEN RAISE EXCEPTION 'Kien chua hang sai don'; END IF;
    IF EXISTS (SELECT 1 FROM order_line l WHERE l.order_id=oid AND (
        SELECT COALESCE(SUM(pl.quantity_in_package),0) FROM package_line pl JOIN package pk USING(package_id)
        WHERE pl.order_line_id=l.order_line_id AND pk.packing_status<>'CANCELLED'
    )>LEAST(l.quantity_ordered,l.reserved_qty)) THEN RAISE EXCEPTION 'So luong dong goi/giu khong khop'; END IF;
    SELECT SUM(pr.unit_weight_gram*pl.quantity_in_package) INTO goods_weight
        FROM package_line pl JOIN order_line l USING(order_line_id) JOIN product pr USING(product_id)
        WHERE pl.package_id=p_package_id;
    IF p_weight<goods_weight THEN RAISE EXCEPTION 'Can kien nhe hon tong hang ben trong'; END IF;
    UPDATE package SET packing_status='APPROVED',approved_by_staff_id=p_staff_id,
        approved_at=CURRENT_TIMESTAMP,packed_weight_gram=p_weight WHERE package_id=p_package_id;
    IF NOT EXISTS (SELECT 1 FROM package WHERE order_id=oid AND packing_status NOT IN ('APPROVED','CANCELLED'))
       AND NOT EXISTS (SELECT 1 FROM order_line l WHERE l.order_id=oid AND l.quantity_ordered<>(
          SELECT COALESCE(SUM(pl.quantity_in_package),0) FROM package_line pl JOIN package pk USING(package_id)
          WHERE pl.order_line_id=l.order_line_id AND pk.packing_status<>'CANCELLED'))
    THEN UPDATE customer_order SET order_status='PACKED' WHERE order_id=oid;
    ELSE UPDATE customer_order SET order_status='PACKING' WHERE order_id=oid; END IF;
    RETURN TRUE;
END $$;

CREATE FUNCTION handover_package(p_package_id INT,p_tracking VARCHAR,p_fee DECIMAL DEFAULT 0) RETURNS BOOLEAN
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE oid INT; o customer_order%ROWTYPE; p package%ROWTYPE; s shipment%ROWTYPE; d RECORD; affected INT;
BEGIN
    p_fee:=ROUND(p_fee,2);
    oid:=_lock_package_order(p_package_id);
    SELECT * INTO STRICT o FROM customer_order WHERE order_id=oid;
    SELECT * INTO STRICT p FROM package WHERE package_id=p_package_id;
    SELECT * INTO s FROM shipment WHERE package_id=p_package_id FOR UPDATE;
    IF FOUND AND s.handed_over_at IS NOT NULL THEN
        IF s.tracking_number=p_tracking AND s.shipping_fee=p_fee THEN RETURN FALSE; END IF;
        RAISE EXCEPTION 'Kien da ban giao voi noi dung khac';
    END IF;
    IF p_tracking IS NULL OR LENGTH(TRIM(p_tracking))=0 OR p_fee IS NULL OR p_fee<0 OR p_fee='NaN'::NUMERIC THEN
        RAISE EXCEPTION 'Ma van don/phi khong hop le';
    END IF;
    IF p.packing_status<>'APPROVED' OR o.order_status<>'PACKED' OR o.assigned_warehouse_id IS NULL
       OR o.carrier_id IS NULL THEN RAISE EXCEPTION 'Can dong goi du, duyet kien, chon kho va hang van chuyen'; END IF;
    IF NOT EXISTS (SELECT 1 FROM package_line WHERE package_id=p_package_id) OR EXISTS (
        SELECT 1 FROM package_line pl JOIN order_line l USING(order_line_id)
        WHERE pl.package_id=p_package_id AND (l.order_id<>oid OR l.reserved_qty<pl.quantity_in_package)
    ) THEN RAISE EXCEPTION 'Phan bo kien/giu hang khong hop le'; END IF;
    PERFORM 1 FROM order_line WHERE order_id=oid ORDER BY order_line_id FOR UPDATE;
    PERFORM i.product_id FROM inventory i WHERE i.warehouse_id=o.assigned_warehouse_id
        AND i.product_id IN (SELECT l.product_id FROM package_line pl JOIN order_line l USING(order_line_id) WHERE pl.package_id=p_package_id)
        ORDER BY i.product_id FOR UPDATE;
    FOR d IN SELECT l.product_id,SUM(pl.quantity_in_package)::INT qty
        FROM package_line pl JOIN order_line l USING(order_line_id) WHERE pl.package_id=p_package_id
        GROUP BY l.product_id ORDER BY l.product_id
    LOOP
        UPDATE inventory SET physical_qty=physical_qty-d.qty,reserved_qty=reserved_qty-d.qty
        WHERE warehouse_id=o.assigned_warehouse_id AND product_id=d.product_id AND reserved_qty>=d.qty;
        GET DIAGNOSTICS affected=ROW_COUNT;
        IF affected<>1 THEN RAISE EXCEPTION 'Ton/giu khong du cho kien'; END IF;
        INSERT INTO inventory_transaction(warehouse_id,product_id,transaction_type,quantity_change,reference_code)
            VALUES(o.assigned_warehouse_id,d.product_id,'SHIPMENT',-d.qty,'package:'||p_package_id);
    END LOOP;
    UPDATE order_line l SET reserved_qty=l.reserved_qty-pl.quantity_in_package
        FROM package_line pl WHERE pl.package_id=p_package_id AND pl.order_line_id=l.order_line_id;
    INSERT INTO shipment(package_id,tracking_number,shipping_fee,shipment_status,handed_over_at,status_updated_at)
        VALUES(p_package_id,p_tracking,p_fee,'PICKED_UP',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)
        ON CONFLICT (package_id) DO UPDATE SET tracking_number=EXCLUDED.tracking_number,
        shipping_fee=EXCLUDED.shipping_fee,shipment_status='PICKED_UP',
        handed_over_at=EXCLUDED.handed_over_at,status_updated_at=EXCLUDED.status_updated_at;
    IF NOT EXISTS (SELECT 1 FROM package pk WHERE pk.order_id=oid AND pk.packing_status<>'CANCELLED'
        AND NOT EXISTS (SELECT 1 FROM shipment sh WHERE sh.package_id=pk.package_id AND sh.handed_over_at IS NOT NULL))
    THEN UPDATE customer_order SET order_status='SHIPPED' WHERE order_id=oid; END IF;
    RETURN TRUE;
END $$;

CREATE FUNCTION deliver_package(p_package_id INT) RETURNS BOOLEAN
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE oid INT; s shipment%ROWTYPE;
BEGIN
    oid:=_lock_package_order(p_package_id);
    SELECT * INTO STRICT s FROM shipment WHERE package_id=p_package_id FOR UPDATE;
    IF s.shipment_status='DELIVERED' THEN RETURN FALSE; END IF;
    IF s.handed_over_at IS NULL OR s.shipment_status NOT IN ('PICKED_UP','IN_TRANSIT') THEN
        RAISE EXCEPTION 'Kien chua ban giao/khong cho chuyen da giao';
    END IF;
    UPDATE shipment SET shipment_status='DELIVERED',status_updated_at=CURRENT_TIMESTAMP WHERE package_id=p_package_id;
    IF NOT EXISTS (SELECT 1 FROM package pk WHERE pk.order_id=oid AND pk.packing_status<>'CANCELLED'
        AND NOT EXISTS (SELECT 1 FROM shipment sh WHERE sh.package_id=pk.package_id AND sh.shipment_status='DELIVERED'))
    THEN UPDATE customer_order SET order_status='DELIVERED' WHERE order_id=oid; END IF;
    RETURN TRUE;
END $$;

COMMIT;
SET search_path TO dbi202_live;
SELECT current_database() AS database_dang_dung, current_schema() AS schema_demo;
