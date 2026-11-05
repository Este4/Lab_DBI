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
