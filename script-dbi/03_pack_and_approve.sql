BEGIN;
SET LOCAL search_path TO dbi202_live;

-- Chạy sau 02, một lần. Không tạo lại các kiện nếu vô tình chạy lại file.
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM package WHERE order_id=1) THEN
   RAISE EXCEPTION 'Don 1 da co kien. Khong chay lai buoc tao kien.';
 END IF;
END $$;
SELECT create_package(1,1) AS kien_dau;
SELECT create_package(1,1) AS kien_sau;
-- Tìm ID theo đơn thay vì giả định sequence luôn ra 1 và 2.
SELECT set_package_line((SELECT MIN(package_id) FROM package WHERE order_id=1),1,3);
SELECT set_package_line((SELECT MIN(package_id) FROM package WHERE order_id=1),2,2);
SELECT set_package_line((SELECT MAX(package_id) FROM package WHERE order_id=1),1,2);
INSERT INTO package_material(package_id,material_id,quantity_used)
 SELECT MIN(package_id),1,2 FROM package WHERE order_id=1;
INSERT INTO package_material(package_id,material_id,quantity_used)
 SELECT MAX(package_id),1,0.5 FROM package WHERE order_id=1;
-- Hàng kiện đầu nặng 800g; cân cả kiện 900g. Kiện sau hàng200g, cân300g.
SELECT approve_package((SELECT MIN(package_id) FROM package WHERE order_id=1),1,900);
SELECT approve_package((SELECT MAX(package_id) FROM package WHERE order_id=1),1,300);
DO $$ BEGIN
 IF (SELECT order_status FROM customer_order WHERE order_id=1)<>'PACKED' THEN
   RAISE EXCEPTION 'Don chua dong goi du';
 END IF;
END $$;
SELECT package_id,packing_status,packed_weight_gram,approved_by_staff_id FROM package WHERE order_id=1 ORDER BY package_id;
SELECT * FROM package_line ORDER BY package_id,order_line_id;

COMMIT;
