-- ============================================================================
-- DBI202 - TOPIC 3: FULL DATABASE SETUP SCRIPT FOR MICROSOFT SQL SERVER (T-SQL)
-- Tuong thich hoan toan voi: SQL Server Management Studio (SSMS), Azure SQL, MS SQL 2017+
-- Giu nguyen 100% cau truc 16 bang chuan + bang so cai inventory_transaction
-- ============================================================================

-- 0. Chuan bi Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbi202_live')
BEGIN
    EXEC('CREATE SCHEMA dbi202_live');
END
GO

-- Xoa bang cu neu da ton tai (thu tu nguoc lai cua khoa ngoai)
IF OBJECT_ID('dbi202_live.shipment', 'U') IS NOT NULL DROP TABLE dbi202_live.shipment;
IF OBJECT_ID('dbi202_live.package_material', 'U') IS NOT NULL DROP TABLE dbi202_live.package_material;
IF OBJECT_ID('dbi202_live.package_line', 'U') IS NOT NULL DROP TABLE dbi202_live.package_line;
IF OBJECT_ID('dbi202_live.package', 'U') IS NOT NULL DROP TABLE dbi202_live.package;
IF OBJECT_ID('dbi202_live.order_line', 'U') IS NOT NULL DROP TABLE dbi202_live.order_line;
IF OBJECT_ID('dbi202_live.customer_order', 'U') IS NOT NULL DROP TABLE dbi202_live.customer_order;
IF OBJECT_ID('dbi202_live.inventory_transaction', 'U') IS NOT NULL DROP TABLE dbi202_live.inventory_transaction;
IF OBJECT_ID('dbi202_live.customer', 'U') IS NOT NULL DROP TABLE dbi202_live.customer;
IF OBJECT_ID('dbi202_live.inventory', 'U') IS NOT NULL DROP TABLE dbi202_live.inventory;
IF OBJECT_ID('dbi202_live.sales_account', 'U') IS NOT NULL DROP TABLE dbi202_live.sales_account;
IF OBJECT_ID('dbi202_live.packaging_material', 'U') IS NOT NULL DROP TABLE dbi202_live.packaging_material;
IF OBJECT_ID('dbi202_live.box_template', 'U') IS NOT NULL DROP TABLE dbi202_live.box_template;
IF OBJECT_ID('dbi202_live.shipping_carrier', 'U') IS NOT NULL DROP TABLE dbi202_live.shipping_carrier;
IF OBJECT_ID('dbi202_live.staff', 'U') IS NOT NULL DROP TABLE dbi202_live.staff;
IF OBJECT_ID('dbi202_live.product', 'U') IS NOT NULL DROP TABLE dbi202_live.product;
IF OBJECT_ID('dbi202_live.warehouse', 'U') IS NOT NULL DROP TABLE dbi202_live.warehouse;
IF OBJECT_ID('dbi202_live.sales_channel', 'U') IS NOT NULL DROP TABLE dbi202_live.sales_channel;
GO

-- 1. SALES_CHANNEL (4.4.01)
CREATE TABLE dbi202_live.sales_channel (
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
CREATE TABLE dbi202_live.warehouse (
    warehouse_id INT IDENTITY(1,1) PRIMARY KEY,
    warehouse_name VARCHAR(150) NOT NULL,
    warehouse_address VARCHAR(255) NOT NULL,

    CONSTRAINT ck_warehouse_name_nonblank CHECK (LEN(LTRIM(RTRIM(warehouse_name))) > 0),
    CONSTRAINT ck_warehouse_address_nonblank CHECK (LEN(LTRIM(RTRIM(warehouse_address))) > 0)
);
GO

-- 3. PRODUCT (4.4.04)
CREATE TABLE dbi202_live.product (
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
CREATE TABLE dbi202_live.staff (
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
CREATE TABLE dbi202_live.shipping_carrier (
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
CREATE TABLE dbi202_live.box_template (
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
CREATE TABLE dbi202_live.packaging_material (
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
CREATE TABLE dbi202_live.sales_account (
    sales_account_id INT IDENTITY(1,1) PRIMARY KEY,
    channel_id INT NOT NULL,
    external_shop_id VARCHAR(100) NOT NULL,
    shop_display_name VARCHAR(150) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,

    CONSTRAINT fk_sales_account_channel FOREIGN KEY (channel_id)
        REFERENCES dbi202_live.sales_channel (channel_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_sales_account_channel_shop UNIQUE (channel_id, external_shop_id),
    CONSTRAINT ck_sales_account_shop_id_nonblank CHECK (LEN(LTRIM(RTRIM(external_shop_id))) > 0),
    CONSTRAINT ck_sales_account_name_nonblank CHECK (LEN(LTRIM(RTRIM(shop_display_name))) > 0)
);
GO

-- 9. INVENTORY (4.4.06)
CREATE TABLE dbi202_live.inventory (
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    physical_qty INT NOT NULL DEFAULT 0,
    reserved_qty INT NOT NULL DEFAULT 0,

    CONSTRAINT pk_inventory PRIMARY KEY (warehouse_id, product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES dbi202_live.warehouse (warehouse_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES dbi202_live.product (product_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT ck_inventory_physical_qty CHECK (physical_qty >= 0),
    CONSTRAINT ck_inventory_reserved_qty CHECK (reserved_qty >= 0),
    CONSTRAINT ck_inventory_reserved_limit CHECK (reserved_qty <= physical_qty)
);
GO

-- 10. CUSTOMER (4.4.03)
CREATE TABLE dbi202_live.customer (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    sales_account_id INT NOT NULL,
    external_customer_id VARCHAR(120),
    display_name VARCHAR(150) NOT NULL,
    contact_phone VARCHAR(30),

    CONSTRAINT fk_customer_sales_account FOREIGN KEY (sales_account_id)
        REFERENCES dbi202_live.sales_account (sales_account_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_customer_id_account UNIQUE (customer_id, sales_account_id),
    CONSTRAINT ck_customer_name_nonblank CHECK (LEN(LTRIM(RTRIM(display_name))) > 0),
    CONSTRAINT ck_customer_phone CHECK (
        contact_phone IS NULL OR LEN(LTRIM(RTRIM(contact_phone))) >= 8
    )
);
GO

-- 11. CUSTOMER_ORDER (4.4.09)
CREATE TABLE dbi202_live.customer_order (
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
        REFERENCES dbi202_live.sales_account (sales_account_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_customer_order_customer FOREIGN KEY (customer_id)
        REFERENCES dbi202_live.customer (customer_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_order_customer_same_account FOREIGN KEY (customer_id, sales_account_id)
        REFERENCES dbi202_live.customer (customer_id, sales_account_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_customer_order_warehouse FOREIGN KEY (assigned_warehouse_id)
        REFERENCES dbi202_live.warehouse (warehouse_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_customer_order_staff FOREIGN KEY (assigned_by_staff_id)
        REFERENCES dbi202_live.staff (staff_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_customer_order_carrier FOREIGN KEY (carrier_id)
        REFERENCES dbi202_live.shipping_carrier (carrier_id)
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
    ),
    CONSTRAINT ck_delivered_order_warehouse CHECK (
        order_status <> 'DELIVERED' OR assigned_warehouse_id IS NOT NULL
    )
);
GO

-- 12. ORDER_LINE (4.4.10)
CREATE TABLE dbi202_live.order_line (
    order_line_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    line_no INT NOT NULL,
    product_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    unit_price_at_order DECIMAL(14,2) NOT NULL,
    reserved_qty INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_order_line_order FOREIGN KEY (order_id)
        REFERENCES dbi202_live.customer_order (order_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_order_line_product FOREIGN KEY (product_id)
        REFERENCES dbi202_live.product (product_id)
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
CREATE TABLE dbi202_live.package (
    package_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    box_template_id INT NOT NULL,
    packed_weight_gram DECIMAL(12,2),
    packing_status VARCHAR(30) NOT NULL DEFAULT 'PACKING',
    approved_by_staff_id INT,
    approved_at DATETIME2(0),

    CONSTRAINT fk_package_order FOREIGN KEY (order_id)
        REFERENCES dbi202_live.customer_order (order_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_package_box_template FOREIGN KEY (box_template_id)
        REFERENCES dbi202_live.box_template (box_template_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_package_staff FOREIGN KEY (approved_by_staff_id)
        REFERENCES dbi202_live.staff (staff_id)
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
CREATE TABLE dbi202_live.package_line (
    package_id INT NOT NULL,
    order_line_id INT NOT NULL,
    quantity_in_package INT NOT NULL,

    CONSTRAINT pk_package_line PRIMARY KEY (package_id, order_line_id),
    CONSTRAINT fk_package_line_package FOREIGN KEY (package_id)
        REFERENCES dbi202_live.package (package_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_package_line_order_line FOREIGN KEY (order_line_id)
        REFERENCES dbi202_live.order_line (order_line_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT ck_package_line_quantity CHECK (quantity_in_package > 0)
);
GO

-- 15. PACKAGE_MATERIAL (4.4.15)
CREATE TABLE dbi202_live.package_material (
    package_id INT NOT NULL,
    material_id INT NOT NULL,
    quantity_used DECIMAL(12,3) NOT NULL,

    CONSTRAINT pk_package_material PRIMARY KEY (package_id, material_id),
    CONSTRAINT fk_package_material_package FOREIGN KEY (package_id)
        REFERENCES dbi202_live.package (package_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_package_material_material FOREIGN KEY (material_id)
        REFERENCES dbi202_live.packaging_material (material_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT ck_package_material_quantity CHECK (quantity_used > 0)
);
GO

-- 16. SHIPMENT (4.4.16)
CREATE TABLE dbi202_live.shipment (
    shipment_id INT IDENTITY(1,1) PRIMARY KEY,
    package_id INT NOT NULL,
    tracking_number VARCHAR(120),
    shipping_fee DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    shipment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    handed_over_at DATETIME2(0),
    status_updated_at DATETIME2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_shipment_package UNIQUE (package_id),
    CONSTRAINT fk_shipment_package FOREIGN KEY (package_id)
        REFERENCES dbi202_live.package (package_id)
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

-- 17. INVENTORY_TRANSACTION (So cai ton kho vat ly)
CREATE TABLE dbi202_live.inventory_transaction (
    inventory_transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    quantity_change INT NOT NULL,
    occurred_at DATETIME2(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_code VARCHAR(100),
    notes VARCHAR(500),

    CONSTRAINT fk_inventory_transaction_inventory
        FOREIGN KEY (warehouse_id, product_id)
        REFERENCES dbi202_live.inventory (warehouse_id, product_id)
        ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT uq_inventory_event UNIQUE (warehouse_id, product_id, reference_code),
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
        reference_code IS NULL OR LEN(LTRIM(RTRIM(reference_code))) > 0
    )
);
GO

-- ============================================================================
-- STORED PROCEDURES XU LY GIAO DICH NGHIEP VU TRONG SQL SERVER (T-SQL)
-- ============================================================================

-- 1. Thu tuc giu hang don hang (Reserve Order)
CREATE OR ALTER PROCEDURE dbi202_live.sp_reserve_order
    @p_order_id INT,
    @p_warehouse_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @p_warehouse_id IS NULL THROW 50001, 'Can chon kho', 1;

        DECLARE @order_status VARCHAR(35), @assigned_warehouse_id INT;
        SELECT @order_status = order_status, @assigned_warehouse_id = assigned_warehouse_id
        FROM dbi202_live.customer_order WITH (UPDLOCK, ROWLOCK)
        WHERE order_id = @p_order_id;

        IF @order_status IS NULL THROW 50002, 'Don hang khong ton tai', 1;
        IF @order_status NOT IN ('IMPORTED', 'ASSIGNED', 'PACKING', 'PACKED')
            THROW 50003, 'Trang thai don khong cho giu hang', 1;

        IF NOT EXISTS (SELECT 1 FROM dbi202_live.order_line WHERE order_id = @p_order_id)
            THROW 50004, 'Don chua co san pham', 1;

        IF @assigned_warehouse_id = @p_warehouse_id AND NOT EXISTS (
            SELECT 1 FROM dbi202_live.order_line WHERE order_id = @p_order_id AND reserved_qty <> quantity_ordered
        )
        BEGIN
            COMMIT TRANSACTION;
            RETURN 0;
        END

        IF @order_status NOT IN ('IMPORTED', 'ASSIGNED') OR EXISTS (
            SELECT 1 FROM dbi202_live.order_line WHERE order_id = @p_order_id AND reserved_qty <> 0
        )
            THROW 50005, 'Don dang giu/da dong goi; khong duoc giu them', 1;

        -- Tru ton kho giu cho
        DECLARE @p_id INT, @needed INT;
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT product_id, SUM(quantity_ordered)
            FROM dbi202_live.order_line
            WHERE order_id = @p_order_id
            GROUP BY product_id
            ORDER BY product_id;

        OPEN cur;
        FETCH NEXT FROM cur INTO @p_id, @needed;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE dbi202_live.inventory WITH (UPDLOCK, ROWLOCK)
            SET reserved_qty = reserved_qty + @needed
            WHERE warehouse_id = @p_warehouse_id AND product_id = @p_id
              AND physical_qty - reserved_qty >= @needed;

            IF @@ROWCOUNT <> 1
            BEGIN
                CLOSE cur; DEALLOCATE cur;
                THROW 50006, 'Khong du hang san pham trong kho', 1;
            END

            FETCH NEXT FROM cur INTO @p_id, @needed;
        END
        CLOSE cur; DEALLOCATE cur;

        UPDATE dbi202_live.order_line
        SET reserved_qty = quantity_ordered
        WHERE order_id = @p_order_id;

        UPDATE dbi202_live.customer_order
        SET assigned_warehouse_id = @p_warehouse_id,
            assigned_at = CURRENT_TIMESTAMP,
            order_status = 'ASSIGNED'
        WHERE order_id = @p_order_id;

        COMMIT TRANSACTION;
        RETURN 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 2. Thu tuc huy don hang va hoan tra giu ton kho (Cancel Order)
CREATE OR ALTER PROCEDURE dbi202_live.sp_cancel_order
    @p_order_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @order_status VARCHAR(35), @assigned_warehouse_id INT;
        SELECT @order_status = order_status, @assigned_warehouse_id = assigned_warehouse_id
        FROM dbi202_live.customer_order WITH (UPDLOCK, ROWLOCK)
        WHERE order_id = @p_order_id;

        IF @order_status IS NULL THROW 50007, 'Don hang khong ton tai', 1;
        IF @order_status = 'CANCELLED'
        BEGIN
            COMMIT TRANSACTION;
            RETURN 0;
        END

        IF @order_status IN ('SHIPPED', 'DELIVERED') OR EXISTS (
            SELECT 1 FROM dbi202_live.shipment s
            JOIN dbi202_live.package p ON s.package_id = p.package_id
            WHERE p.order_id = @p_order_id AND s.handed_over_at IS NOT NULL
        )
            THROW 50008, 'Da ban giao, khong huy theo luong nay', 1;

        -- Hoan tra reserved_qty ve kho
        IF @assigned_warehouse_id IS NOT NULL
        BEGIN
            DECLARE @p_id INT, @qty INT;
            DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
                SELECT product_id, SUM(reserved_qty)
                FROM dbi202_live.order_line
                WHERE order_id = @p_order_id
                GROUP BY product_id
                HAVING SUM(reserved_qty) > 0;

            OPEN cur;
            FETCH NEXT FROM cur INTO @p_id, @qty;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                UPDATE dbi202_live.inventory WITH (UPDLOCK, ROWLOCK)
                SET reserved_qty = reserved_qty - @qty
                WHERE warehouse_id = @assigned_warehouse_id AND product_id = @p_id AND reserved_qty >= @qty;

                FETCH NEXT FROM cur INTO @p_id, @qty;
            END
            CLOSE cur; DEALLOCATE cur;
        END

        UPDATE dbi202_live.order_line SET reserved_qty = 0 WHERE order_id = @p_order_id;
        UPDATE dbi202_live.package SET packing_status = 'CANCELLED' WHERE order_id = @p_order_id;
        UPDATE dbi202_live.customer_order SET order_status = 'CANCELLED' WHERE order_id = @p_order_id;

        COMMIT TRANSACTION;
        RETURN 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 3. Thu tuc tao kien hang (Create Package)
CREATE OR ALTER PROCEDURE dbi202_live.sp_create_package
    @p_order_id INT,
    @p_box_id INT,
    @p_new_package_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @order_status VARCHAR(35);
        SELECT @order_status = order_status
        FROM dbi202_live.customer_order WITH (UPDLOCK, ROWLOCK)
        WHERE order_id = @p_order_id;

        IF @order_status NOT IN ('ASSIGNED', 'PACKING')
            THROW 50009, 'Don phai o trang thai ASSIGNED hoac PACKING', 1;

        IF EXISTS (SELECT 1 FROM dbi202_live.order_line WHERE order_id = @p_order_id AND reserved_qty <> quantity_ordered)
            THROW 50010, 'Can giu du hang truoc khi tao kien', 1;

        INSERT INTO dbi202_live.package (order_id, box_template_id)
        VALUES (@p_order_id, @p_box_id);

        SET @p_new_package_id = SCOPE_IDENTITY();

        UPDATE dbi202_live.customer_order
        SET order_status = 'PACKING'
        WHERE order_id = @p_order_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 4. Thu tuc xep dong hang vao kien (Set Package Line)
CREATE OR ALTER PROCEDURE dbi202_live.sp_set_package_line
    @p_package_id INT,
    @p_order_line_id INT,
    @p_quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @order_id INT, @packing_status VARCHAR(30);
        SELECT @order_id = order_id, @packing_status = packing_status
        FROM dbi202_live.package WITH (UPDLOCK, ROWLOCK)
        WHERE package_id = @p_package_id;

        IF @order_id IS NULL THROW 50011, 'Kien hang khong ton tai', 1;
        IF @packing_status <> 'PACKING' THROW 50012, 'Kien hang khong con cho phep sua', 1;
        IF @p_quantity <= 0 THROW 50013, 'So luong phai duong', 1;

        DECLARE @line_order_id INT, @qty_ordered INT, @reserved_qty INT;
        SELECT @line_order_id = order_id, @qty_ordered = quantity_ordered, @reserved_qty = reserved_qty
        FROM dbi202_live.order_line WITH (UPDLOCK, ROWLOCK)
        WHERE order_line_id = @p_order_line_id;

        IF @line_order_id <> @order_id THROW 50014, 'Dong hang khong thuoc ve don cua kien', 1;

        DECLARE @other_qty INT = 0;
        SELECT @other_qty = COALESCE(SUM(pl.quantity_in_package), 0)
        FROM dbi202_live.package_line pl
        JOIN dbi202_live.package p ON pl.package_id = p.package_id
        WHERE pl.order_line_id = @p_order_line_id AND pl.package_id <> @p_package_id AND p.packing_status <> 'CANCELLED';

        IF @other_qty + @p_quantity > @qty_ordered OR @other_qty + @p_quantity > @reserved_qty
            THROW 50015, 'Dong goi vuot qua so luong dat/giu', 1;

        -- Upsert package_line
        IF EXISTS (SELECT 1 FROM dbi202_live.package_line WHERE package_id = @p_package_id AND order_line_id = @p_order_line_id)
        BEGIN
            UPDATE dbi202_live.package_line
            SET quantity_in_package = @p_quantity
            WHERE package_id = @p_package_id AND order_line_id = @p_order_line_id;
        END
        ELSE
        BEGIN
            INSERT INTO dbi202_live.package_line (package_id, order_line_id, quantity_in_package)
            VALUES (@p_package_id, @p_order_line_id, @p_quantity);
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 5. Thu tuc phe duyet kien hang (Approve Package)
CREATE OR ALTER PROCEDURE dbi202_live.sp_approve_package
    @p_package_id INT,
    @p_staff_id INT,
    @p_weight DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @order_id INT, @box_template_id INT, @packing_status VARCHAR(30);
        SELECT @order_id = order_id, @box_template_id = box_template_id, @packing_status = packing_status
        FROM dbi202_live.package WITH (UPDLOCK, ROWLOCK)
        WHERE package_id = @p_package_id;

        IF @order_id IS NULL THROW 50016, 'Kien hang khong ton tai', 1;
        IF @packing_status NOT IN ('PACKING', 'PACKED') THROW 50017, 'Khong the duyet kien nay', 1;

        IF NOT EXISTS (SELECT 1 FROM dbi202_live.staff WHERE staff_id = @p_staff_id AND is_active = 1)
            THROW 50018, 'Nhan vien khong hoat dong hoac khong ton tai', 1;

        DECLARE @max_weight DECIMAL(12,2);
        SELECT @max_weight = max_weight_gram FROM dbi202_live.box_template WHERE box_template_id = @box_template_id;

        IF @p_weight <= 0 OR @p_weight > @max_weight
            THROW 50019, 'Trong luong kien khong hop le hoac vuot qua gioi han thung', 1;

        IF NOT EXISTS (SELECT 1 FROM dbi202_live.package_line WHERE package_id = @p_package_id)
            THROW 50020, 'Kien hang chua co san pham (kien rong)', 1;

        DECLARE @goods_weight DECIMAL(12,2) = 0;
        SELECT @goods_weight = SUM(pr.unit_weight_gram * pl.quantity_in_package)
        FROM dbi202_live.package_line pl
        JOIN dbi202_live.order_line l ON pl.order_line_id = l.order_line_id
        JOIN dbi202_live.product pr ON l.product_id = pr.product_id
        WHERE pl.package_id = @p_package_id;

        IF @p_weight < @goods_weight
            THROW 50021, 'Can kien hang nhe hon tong trong luong hang ben trong', 1;

        UPDATE dbi202_live.package
        SET packing_status = 'APPROVED',
            approved_by_staff_id = @p_staff_id,
            approved_at = CURRENT_TIMESTAMP,
            packed_weight_gram = @p_weight
        WHERE package_id = @p_package_id;

        -- Cap nhat trang thai don hang
        IF NOT EXISTS (
            SELECT 1 FROM dbi202_live.package
            WHERE order_id = @order_id AND packing_status NOT IN ('APPROVED', 'CANCELLED')
        )
        AND NOT EXISTS (
            SELECT 1 FROM dbi202_live.order_line l
            WHERE l.order_id = @order_id AND l.quantity_ordered <> (
                SELECT COALESCE(SUM(pl.quantity_in_package), 0)
                FROM dbi202_live.package_line pl
                JOIN dbi202_live.package pk ON pl.package_id = pk.package_id
                WHERE pl.order_line_id = l.order_line_id AND pk.packing_status <> 'CANCELLED'
            )
        )
        BEGIN
            UPDATE dbi202_live.customer_order SET order_status = 'PACKED' WHERE order_id = @order_id;
        END
        ELSE
        BEGIN
            UPDATE dbi202_live.customer_order SET order_status = 'PACKING' WHERE order_id = @order_id;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 6. Thu tuc ban giao van chuyen va xuat kho so cai (Handover Package)
CREATE OR ALTER PROCEDURE dbi202_live.sp_handover_package
    @p_package_id INT,
    @p_tracking VARCHAR(120),
    @p_fee DECIMAL(14,2) = 0.00
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @order_id INT, @packing_status VARCHAR(30);
        SELECT @order_id = order_id, @packing_status = packing_status
        FROM dbi202_live.package WITH (UPDLOCK, ROWLOCK)
        WHERE package_id = @p_package_id;

        IF @packing_status <> 'APPROVED' THROW 50022, 'Kien hang phai duoc APPROVED truoc khi ban giao', 1;
        IF @p_tracking IS NULL OR LEN(LTRIM(RTRIM(@p_tracking))) = 0 THROW 50023, 'Ma van don khong hop le', 1;

        DECLARE @order_status VARCHAR(35), @warehouse_id INT, @carrier_id INT;
        SELECT @order_status = order_status, @warehouse_id = assigned_warehouse_id, @carrier_id = carrier_id
        FROM dbi202_live.customer_order WITH (UPDLOCK, ROWLOCK)
        WHERE order_id = @order_id;

        IF @warehouse_id IS NULL OR @carrier_id IS NULL
            THROW 50024, 'Don hang chua duoc gan kho hoac hang van chuyen', 1;

        -- Tru kho vat ly va ghi so cai inventory_transaction
        DECLARE @p_id INT, @qty INT;
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT l.product_id, SUM(pl.quantity_in_package)
            FROM dbi202_live.package_line pl
            JOIN dbi202_live.order_line l ON pl.order_line_id = l.order_line_id
            WHERE pl.package_id = @p_package_id
            GROUP BY l.product_id;

        OPEN cur;
        FETCH NEXT FROM cur INTO @p_id, @qty;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE dbi202_live.inventory WITH (UPDLOCK, ROWLOCK)
            SET physical_qty = physical_qty - @qty,
                reserved_qty = reserved_qty - @qty
            WHERE warehouse_id = @warehouse_id AND product_id = @p_id AND reserved_qty >= @qty;

            DECLARE @ref_code VARCHAR(100) = 'package:' + CAST(@p_package_id AS VARCHAR(20));
            INSERT INTO dbi202_live.inventory_transaction
                (warehouse_id, product_id, transaction_type, quantity_change, reference_code)
            VALUES (@warehouse_id, @p_id, 'SHIPMENT', -@qty, @ref_code);

            FETCH NEXT FROM cur INTO @p_id, @qty;
        END
        CLOSE cur; DEALLOCATE cur;

        -- Giam reserved_qty o order_line
        UPDATE l
        SET l.reserved_qty = l.reserved_qty - pl.quantity_in_package
        FROM dbi202_live.order_line l
        JOIN dbi202_live.package_line pl ON l.order_line_id = pl.order_line_id
        WHERE pl.package_id = @p_package_id;

        -- Tao hoac cap nhat shipment
        IF EXISTS (SELECT 1 FROM dbi202_live.shipment WHERE package_id = @p_package_id)
        BEGIN
            UPDATE dbi202_live.shipment
            SET tracking_number = @p_tracking,
                shipping_fee = @p_fee,
                shipment_status = 'PICKED_UP',
                handed_over_at = CURRENT_TIMESTAMP,
                status_updated_at = CURRENT_TIMESTAMP
            WHERE package_id = @p_package_id;
        END
        ELSE
        BEGIN
            INSERT INTO dbi202_live.shipment
                (package_id, tracking_number, shipping_fee, shipment_status, handed_over_at, status_updated_at)
            VALUES (@p_package_id, @p_tracking, @p_fee, 'PICKED_UP', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        END

        -- Kiem tra tat ca kien da ban giao thi cap nhat SHIPPED
        IF NOT EXISTS (
            SELECT 1 FROM dbi202_live.package pk
            WHERE pk.order_id = @order_id AND pk.packing_status <> 'CANCELLED'
              AND NOT EXISTS (SELECT 1 FROM dbi202_live.shipment sh WHERE sh.package_id = pk.package_id AND sh.handed_over_at IS NOT NULL)
        )
        BEGIN
            UPDATE dbi202_live.customer_order SET order_status = 'SHIPPED' WHERE order_id = @order_id;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 7. Thu tuc giao hang thanh cong (Deliver Package)
CREATE OR ALTER PROCEDURE dbi202_live.sp_deliver_package
    @p_package_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @order_id INT;
        SELECT @order_id = order_id FROM dbi202_live.package WHERE package_id = @p_package_id;

        DECLARE @status VARCHAR(30), @handed_at DATETIME2(0);
        SELECT @status = shipment_status, @handed_at = handed_over_at
        FROM dbi202_live.shipment WITH (UPDLOCK, ROWLOCK)
        WHERE package_id = @p_package_id;

        IF @status IS NULL OR @handed_at IS NULL OR @status NOT IN ('PICKED_UP', 'IN_TRANSIT')
            THROW 50025, 'Kien hang chua duoc ban giao hoac khong hop le de giao', 1;

        UPDATE dbi202_live.shipment
        SET shipment_status = 'DELIVERED',
            status_updated_at = CURRENT_TIMESTAMP
        WHERE package_id = @p_package_id;

        IF NOT EXISTS (
            SELECT 1 FROM dbi202_live.package pk
            WHERE pk.order_id = @order_id AND pk.packing_status <> 'CANCELLED'
              AND NOT EXISTS (SELECT 1 FROM dbi202_live.shipment sh WHERE sh.package_id = pk.package_id AND sh.shipment_status = 'DELIVERED')
        )
        BEGIN
            UPDATE dbi202_live.customer_order SET order_status = 'DELIVERED' WHERE order_id = @order_id;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT '========================================================================';
PRINT 'KHOI TAO CSDL THUAN T-SQL CHO MICROSOFT SQL SERVER THANH CONG 100%!';
PRINT 'Schema: dbi202_live | Bao gom: 17 Bang chuan + 7 Thu tuc xu ly nghiep vu';
PRINT '========================================================================';

