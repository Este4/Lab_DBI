-- ============================================================================
-- DBI202 - TOPIC 3: COMPLETE RELATIONAL SCHEMA DEFINITION FOR MICROSOFT SQL SERVER
-- T-SQL DDL Script (16 Core Relational Tables in Dependency Order)
-- Ref: Lab4_Topic3.docx (Section 3.4 & Section 4.4)
-- ============================================================================

-- Drop tables in reverse dependency order if re-initializing
IF OBJECT_ID('dbo.shipment', 'U') IS NOT NULL DROP TABLE dbo.shipment;
IF OBJECT_ID('dbo.package_material', 'U') IS NOT NULL DROP TABLE dbo.package_material;
IF OBJECT_ID('dbo.package_line', 'U') IS NOT NULL DROP TABLE dbo.package_line;
IF OBJECT_ID('dbo.package', 'U') IS NOT NULL DROP TABLE dbo.package;
IF OBJECT_ID('dbo.order_line', 'U') IS NOT NULL DROP TABLE dbo.order_line;
IF OBJECT_ID('dbo.customer_order', 'U') IS NOT NULL DROP TABLE dbo.customer_order;
IF OBJECT_ID('dbo.customer', 'U') IS NOT NULL DROP TABLE dbo.customer;
IF OBJECT_ID('dbo.inventory', 'U') IS NOT NULL DROP TABLE dbo.inventory;
IF OBJECT_ID('dbo.sales_account', 'U') IS NOT NULL DROP TABLE dbo.sales_account;
IF OBJECT_ID('dbo.packaging_material', 'U') IS NOT NULL DROP TABLE dbo.packaging_material;
IF OBJECT_ID('dbo.box_template', 'U') IS NOT NULL DROP TABLE dbo.box_template;
IF OBJECT_ID('dbo.shipping_carrier', 'U') IS NOT NULL DROP TABLE dbo.shipping_carrier;
IF OBJECT_ID('dbo.staff', 'U') IS NOT NULL DROP TABLE dbo.staff;
IF OBJECT_ID('dbo.product', 'U') IS NOT NULL DROP TABLE dbo.product;
IF OBJECT_ID('dbo.warehouse', 'U') IS NOT NULL DROP TABLE dbo.warehouse;
IF OBJECT_ID('dbo.sales_channel', 'U') IS NOT NULL DROP TABLE dbo.sales_channel;
GO

-- 1. SALES_CHANNEL (4.4.01)
CREATE TABLE dbo.sales_channel (
    channel_id INT IDENTITY(1,1) PRIMARY KEY,
    channel_name VARCHAR(80) NOT NULL,
    channel_code VARCHAR(50) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,

    CONSTRAINT uq_sales_channel_name UNIQUE (channel_name),
    CONSTRAINT uq_sales_channel_code UNIQUE (channel_code),
    CONSTRAINT ck_sales_channel_name_nonblank CHECK (LEN(LTRIM(RTRIM(channel_name))) > 0),
    CONSTRAINT ck_sales_channel_code_nonblank CHECK (LEN(LTRIM(RTRIM(channel_code))) > 0)
);
GO

-- 2. WAREHOUSE (4.4.05)
CREATE TABLE dbo.warehouse (
    warehouse_id INT IDENTITY(1,1) PRIMARY KEY,
    warehouse_name VARCHAR(150) NOT NULL,
    warehouse_address VARCHAR(255) NOT NULL,

    CONSTRAINT ck_warehouse_name_nonblank CHECK (LEN(LTRIM(RTRIM(warehouse_name))) > 0),
    CONSTRAINT ck_warehouse_address_nonblank CHECK (LEN(LTRIM(RTRIM(warehouse_address))) > 0)
);
GO

-- 3. PRODUCT (4.4.04)
CREATE TABLE dbo.product (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    sku VARCHAR(80) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    unit_weight_gram DECIMAL(12,2) NOT NULL,
    length_cm DECIMAL(10,2) NOT NULL,
    width_cm DECIMAL(10,2) NOT NULL,
    height_cm DECIMAL(10,2) NOT NULL,
    is_fragile BIT NOT NULL DEFAULT 0,

    CONSTRAINT uq_product_sku UNIQUE (sku),
    CONSTRAINT ck_product_sku_nonblank CHECK (LEN(LTRIM(RTRIM(sku))) > 0),
    CONSTRAINT ck_product_name_nonblank CHECK (LEN(LTRIM(RTRIM(product_name))) > 0),
    CONSTRAINT ck_product_weight CHECK (unit_weight_gram > 0),
    CONSTRAINT ck_product_dimensions CHECK (
        length_cm > 0 AND width_cm > 0 AND height_cm > 0
    )
);
GO

-- 4. STAFF (4.4.07)
CREATE TABLE dbo.staff (
    staff_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(180),
    is_active BIT NOT NULL DEFAULT 1,

    CONSTRAINT uq_staff_email UNIQUE (email),
    CONSTRAINT ck_staff_full_name_nonblank CHECK (LEN(LTRIM(RTRIM(full_name))) > 0),
    CONSTRAINT ck_staff_email_format CHECK (
        email IS NULL OR (LEN(LTRIM(RTRIM(email))) > 0 AND email LIKE '%@%.%')
    )
);
GO

-- 5. SHIPPING_CARRIER (4.4.08)
CREATE TABLE dbo.shipping_carrier (
    carrier_id INT IDENTITY(1,1) PRIMARY KEY,
    carrier_name VARCHAR(150) NOT NULL,
    contact_phone VARCHAR(30),

    CONSTRAINT uq_shipping_carrier_name UNIQUE (carrier_name),
    CONSTRAINT ck_shipping_carrier_name_nonblank CHECK (LEN(LTRIM(RTRIM(carrier_name))) > 0),
    CONSTRAINT ck_shipping_carrier_phone CHECK (
        contact_phone IS NULL OR LEN(LTRIM(RTRIM(contact_phone))) >= 8
    )
);
GO

-- 6. BOX_TEMPLATE (4.4.11)
CREATE TABLE dbo.box_template (
    box_template_id INT IDENTITY(1,1) PRIMARY KEY,
    box_code VARCHAR(80) NOT NULL,
    inner_length_cm DECIMAL(10,2) NOT NULL,
    inner_width_cm DECIMAL(10,2) NOT NULL,
    inner_height_cm DECIMAL(10,2) NOT NULL,
    max_weight_gram DECIMAL(12,2) NOT NULL,
    unit_cost DECIMAL(14,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT uq_box_template_code UNIQUE (box_code),
    CONSTRAINT ck_box_template_code_nonblank CHECK (LEN(LTRIM(RTRIM(box_code))) > 0),
    CONSTRAINT ck_box_template_dimensions CHECK (
        inner_length_cm > 0 AND inner_width_cm > 0 AND inner_height_cm > 0
    ),
    CONSTRAINT ck_box_template_max_weight CHECK (max_weight_gram > 0),
    CONSTRAINT ck_box_template_unit_cost CHECK (unit_cost >= 0)
);
GO

-- 7. PACKAGING_MATERIAL (4.4.12)
CREATE TABLE dbo.packaging_material (
    material_id INT IDENTITY(1,1) PRIMARY KEY,
    material_code VARCHAR(80) NOT NULL,
    material_name VARCHAR(150) NOT NULL,
    measure_unit VARCHAR(30) NOT NULL,
    unit_cost DECIMAL(14,2) NOT NULL DEFAULT 0.00,

    CONSTRAINT uq_packaging_material_code UNIQUE (material_code),
    CONSTRAINT ck_packaging_material_code_nonblank CHECK (LEN(LTRIM(RTRIM(material_code))) > 0),
    CONSTRAINT ck_packaging_material_name_nonblank CHECK (LEN(LTRIM(RTRIM(material_name))) > 0),
    CONSTRAINT ck_packaging_material_unit_nonblank CHECK (LEN(LTRIM(RTRIM(measure_unit))) > 0),
    CONSTRAINT ck_packaging_material_unit_cost CHECK (unit_cost >= 0)
);
GO

-- 8. SALES_ACCOUNT (4.4.02)
CREATE TABLE dbo.sales_account (
    sales_account_id INT IDENTITY(1,1) PRIMARY KEY,
    channel_id INT NOT NULL,
    external_shop_id VARCHAR(100) NOT NULL,
    shop_display_name VARCHAR(150) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,

    CONSTRAINT fk_sales_account_channel FOREIGN KEY (channel_id)
        REFERENCES dbo.sales_channel (channel_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_sales_account_channel_shop UNIQUE (channel_id, external_shop_id),
    CONSTRAINT ck_sales_account_shop_id_nonblank CHECK (LEN(LTRIM(RTRIM(external_shop_id))) > 0),
    CONSTRAINT ck_sales_account_name_nonblank CHECK (LEN(LTRIM(RTRIM(shop_display_name))) > 0)
);
GO

-- 9. INVENTORY (4.4.06)
CREATE TABLE dbo.inventory (
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    physical_qty INT NOT NULL DEFAULT 0,
    reserved_qty INT NOT NULL DEFAULT 0,

    CONSTRAINT pk_inventory PRIMARY KEY (warehouse_id, product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES dbo.warehouse (warehouse_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES dbo.product (product_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT ck_inventory_physical_qty CHECK (physical_qty >= 0),
    CONSTRAINT ck_inventory_reserved_qty CHECK (reserved_qty >= 0),
    CONSTRAINT ck_inventory_reserved_limit CHECK (reserved_qty <= physical_qty)
);
GO

-- 10. CUSTOMER (4.4.03)
CREATE TABLE dbo.customer (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    sales_account_id INT NOT NULL,
    external_customer_id VARCHAR(120),
    display_name VARCHAR(150) NOT NULL,
    contact_phone VARCHAR(30),

    CONSTRAINT fk_customer_sales_account FOREIGN KEY (sales_account_id)
        REFERENCES dbo.sales_account (sales_account_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_customer_id_account UNIQUE (customer_id, sales_account_id),
    CONSTRAINT ck_customer_name_nonblank CHECK (LEN(LTRIM(RTRIM(display_name))) > 0),
    CONSTRAINT ck_customer_phone CHECK (
        contact_phone IS NULL OR LEN(LTRIM(RTRIM(contact_phone))) >= 8
    )
);
GO

-- 11. CUSTOMER_ORDER (4.4.09)
CREATE TABLE dbo.customer_order (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    sales_account_id INT NOT NULL,
    external_order_id VARCHAR(100) NOT NULL,
    customer_id INT,
    order_date DATETIME2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recipient_name VARCHAR(150) NOT NULL,
    recipient_phone VARCHAR(30),
    delivery_address VARCHAR(255) NOT NULL,
    priority VARCHAR(25) NOT NULL DEFAULT 'STANDARD',
    order_status VARCHAR(35) NOT NULL DEFAULT 'IMPORTED',
    assigned_warehouse_id INT,
    assigned_by_staff_id INT,
    assigned_at DATETIME2(0),
    carrier_id INT,

    CONSTRAINT fk_customer_order_sales_account FOREIGN KEY (sales_account_id)
        REFERENCES dbo.sales_account (sales_account_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_customer_order_customer FOREIGN KEY (customer_id)
        REFERENCES dbo.customer (customer_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_order_customer_same_account FOREIGN KEY (customer_id, sales_account_id)
        REFERENCES dbo.customer (customer_id, sales_account_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_customer_order_warehouse FOREIGN KEY (assigned_warehouse_id)
        REFERENCES dbo.warehouse (warehouse_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_customer_order_staff FOREIGN KEY (assigned_by_staff_id)
        REFERENCES dbo.staff (staff_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_customer_order_carrier FOREIGN KEY (carrier_id)
        REFERENCES dbo.shipping_carrier (carrier_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_customer_order_account_external UNIQUE (sales_account_id, external_order_id),
    CONSTRAINT ck_customer_order_external_nonblank CHECK (LEN(LTRIM(RTRIM(external_order_id))) > 0),
    CONSTRAINT ck_customer_order_recipient_nonblank CHECK (LEN(LTRIM(RTRIM(recipient_name))) > 0),
    CONSTRAINT ck_customer_order_address_nonblank CHECK (LEN(LTRIM(RTRIM(delivery_address))) > 0),
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
GO

-- 12. ORDER_LINE (4.4.10)
CREATE TABLE dbo.order_line (
    order_line_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    line_no INT NOT NULL,
    product_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    unit_price_at_order DECIMAL(14,2) NOT NULL,
    reserved_qty INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_order_line_order FOREIGN KEY (order_id)
        REFERENCES dbo.customer_order (order_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_order_line_product FOREIGN KEY (product_id)
        REFERENCES dbo.product (product_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_order_line_order_line_no UNIQUE (order_id, line_no),
    CONSTRAINT ck_order_line_no CHECK (line_no > 0),
    CONSTRAINT ck_order_line_quantity CHECK (quantity_ordered > 0),
    CONSTRAINT ck_order_line_unit_price CHECK (unit_price_at_order >= 0),
    CONSTRAINT ck_order_line_reserved CHECK (
        reserved_qty >= 0 AND reserved_qty <= quantity_ordered
    )
);
GO

-- 13. PACKAGE (4.4.13)
CREATE TABLE dbo.package (
    package_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    box_template_id INT NOT NULL,
    packed_weight_gram DECIMAL(12,2),
    packing_status VARCHAR(30) NOT NULL DEFAULT 'PACKING',
    approved_by_staff_id INT,
    approved_at DATETIME2(0),

    CONSTRAINT fk_package_order FOREIGN KEY (order_id)
        REFERENCES dbo.customer_order (order_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_package_box_template FOREIGN KEY (box_template_id)
        REFERENCES dbo.box_template (box_template_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_package_staff FOREIGN KEY (approved_by_staff_id)
        REFERENCES dbo.staff (staff_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT ck_package_packed_weight CHECK (
        packed_weight_gram IS NULL OR packed_weight_gram > 0
    ),
    CONSTRAINT ck_package_packing_status CHECK (
        packing_status IN ('PACKING', 'PACKED', 'APPROVED', 'CANCELLED')
    ),
    CONSTRAINT ck_package_approval_consistency CHECK (
        (packing_status = 'APPROVED' AND approved_by_staff_id IS NOT NULL AND approved_at IS NOT NULL)
        OR (packing_status <> 'APPROVED')
    )
);
GO

-- 14. PACKAGE_LINE (4.4.14)
CREATE TABLE dbo.package_line (
    package_id INT NOT NULL,
    order_line_id INT NOT NULL,
    quantity_in_package INT NOT NULL,

    CONSTRAINT pk_package_line PRIMARY KEY (package_id, order_line_id),
    CONSTRAINT fk_package_line_package FOREIGN KEY (package_id)
        REFERENCES dbo.package (package_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_package_line_order_line FOREIGN KEY (order_line_id)
        REFERENCES dbo.order_line (order_line_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT ck_package_line_quantity CHECK (quantity_in_package > 0)
);
GO

-- 15. PACKAGE_MATERIAL (4.4.15)
CREATE TABLE dbo.package_material (
    package_id INT NOT NULL,
    material_id INT NOT NULL,
    quantity_used DECIMAL(12,3) NOT NULL,

    CONSTRAINT pk_package_material PRIMARY KEY (package_id, material_id),
    CONSTRAINT fk_package_material_package FOREIGN KEY (package_id)
        REFERENCES dbo.package (package_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_package_material_material FOREIGN KEY (material_id)
        REFERENCES dbo.packaging_material (material_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT ck_package_material_quantity CHECK (quantity_used > 0)
);
GO

-- 16. SHIPMENT (4.4.16)
CREATE TABLE dbo.shipment (
    shipment_id INT IDENTITY(1,1) PRIMARY KEY,
    package_id INT NOT NULL,
    tracking_number VARCHAR(120),
    shipping_fee DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    shipment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    handed_over_at DATETIME2(0),
    status_updated_at DATETIME2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_shipment_package UNIQUE (package_id),
    CONSTRAINT fk_shipment_package FOREIGN KEY (package_id)
        REFERENCES dbo.package (package_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT ck_shipment_shipping_fee CHECK (shipping_fee >= 0),
    CONSTRAINT ck_shipment_status CHECK (
        shipment_status IN ('PENDING', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED', 'FAILED', 'RETURNED')
    ),
    CONSTRAINT ck_shipment_tracking_nonblank CHECK (
        tracking_number IS NULL OR LEN(LTRIM(RTRIM(tracking_number))) > 0
    ),
    CONSTRAINT ck_shipment_handover_consistency CHECK (
        (shipment_status = 'PENDING' AND handed_over_at IS NULL)
        OR (shipment_status <> 'PENDING' AND handed_over_at IS NOT NULL)
    )
);
GO

