BEGIN;
SET LOCAL search_path TO dbi202_live;

SELECT deliver_package((SELECT MIN(package_id) FROM package WHERE order_id=1));
SELECT order_status FROM customer_order WHERE order_id=1; -- còn SHIPPED
SELECT deliver_package((SELECT MAX(package_id) FROM package WHERE order_id=1));
SELECT deliver_package((SELECT MAX(package_id) FROM package WHERE order_id=1)) AS goi_lap; -- FALSE
DO $$ BEGIN
 IF (SELECT order_status FROM customer_order WHERE order_id=1)<>'DELIVERED' THEN
   RAISE EXCEPTION 'Don chua giao xong';
 END IF;
END $$;
SELECT order_id,external_order_id,order_status FROM customer_order WHERE order_id=1;
SELECT package_id,shipment_status FROM shipment ORDER BY package_id;

COMMIT;
