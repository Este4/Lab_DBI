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