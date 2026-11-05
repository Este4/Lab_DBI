BEGIN;
SET LOCAL search_path TO dbi202_live;

-- Đơn 1 cần 5 sách và 2 ly, lấy từ kho 1.
SELECT reserve_order(1,1) AS giu_hang_lan_dau; -- TRUE
SELECT reserve_order(1,1) AS goi_lap;         -- FALSE: không giữ thêm
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM inventory WHERE warehouse_id=1 AND product_id=1 AND physical_qty=10 AND reserved_qty=5)
 OR NOT EXISTS(SELECT 1 FROM inventory WHERE warehouse_id=1 AND product_id=2 AND physical_qty=3 AND reserved_qty=2)
 THEN RAISE EXCEPTION 'Ket qua giu hang khong dung'; END IF;
END $$;
SELECT product_id,physical_qty,reserved_qty,physical_qty-reserved_qty AS available
FROM inventory WHERE warehouse_id=1 ORDER BY product_id;
SELECT order_id,order_status,assigned_warehouse_id FROM customer_order WHERE order_id=1;

COMMIT;
