BEGIN;
SET LOCAL search_path TO dbi202_live;

SELECT handover_package((SELECT MIN(package_id) FROM package WHERE order_id=1),'DEMO-TRACK-1',1000) AS giao_kien_dau;
SELECT product_id,physical_qty,reserved_qty FROM inventory WHERE warehouse_id=1 ORDER BY product_id;
-- Sau kiện đầu: sách7/giữ2, ly1/giữ0; đơn vẫn PACKED.
SELECT handover_package((SELECT MIN(package_id) FROM package WHERE order_id=1),'DEMO-TRACK-1',1000) AS goi_lap; -- FALSE
SELECT handover_package((SELECT MAX(package_id) FROM package WHERE order_id=1),'DEMO-TRACK-2',1000) AS giao_kien_sau;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM inventory WHERE warehouse_id=1 AND product_id=1 AND physical_qty=5 AND reserved_qty=0)
 OR NOT EXISTS(SELECT 1 FROM inventory WHERE warehouse_id=1 AND product_id=2 AND physical_qty=1 AND reserved_qty=0)
 OR (SELECT order_status FROM customer_order WHERE order_id=1)<>'SHIPPED'
 THEN RAISE EXCEPTION 'Ket qua ban giao khong dung'; END IF;
END $$;
SELECT product_id,physical_qty,reserved_qty FROM inventory WHERE warehouse_id=1 ORDER BY product_id;
SELECT order_id,order_status FROM customer_order WHERE order_id=1;
SELECT package_id,shipment_status,tracking_number FROM shipment ORDER BY package_id;

COMMIT;
