-- CHỈ chạy sau 03_pack_and_approve.sql.
-- Bước A: chọn và chạy toàn bộ từ BEGIN tới hết CREATE TRIGGER.
BEGIN;
SET LOCAL search_path TO dbi202_live;
-- Trigger minh họa CHỈ dùng trong buổi demo, không có sẵn trong core.
CREATE FUNCTION demo_check_same_order() RETURNS TRIGGER
LANGUAGE plpgsql SET search_path FROM CURRENT AS $$
DECLARE package_order INT; line_order INT;
BEGIN
 SELECT order_id INTO package_order FROM package WHERE package_id=NEW.package_id;
 SELECT order_id INTO line_order FROM order_line WHERE order_line_id=NEW.order_line_id;
 IF package_order IS NOT NULL AND line_order IS NOT NULL AND package_order<>line_order THEN
   RAISE EXCEPTION USING ERRCODE='23514',MESSAGE='TRIGGER DEMO: dong hang khong thuoc don cua kien';
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER demo_same_order
BEFORE INSERT OR UPDATE OF package_id,order_line_id ON package_line
FOR EACH ROW EXECUTE FUNCTION demo_check_same_order();

-- Bước B: chọn RIÊNG INSERT bên dưới và chạy; mong đợi lỗi đỏ SQLSTATE23514.
-- Kiện thuộc đơn1 nhưng dòng3 thuộc đơn2; không gọi set_package_line ở đây.
INSERT INTO package_line(package_id,order_line_id,quantity_in_package)
SELECT MIN(package_id),3,1 FROM package WHERE order_id=1;

-- Bước C: sau lỗi, chọn RIÊNG ROLLBACK và chạy.
-- Rollback cả INSERT lỗi lẫn CREATE TRIGGER/FUNCTION minh họa, không lưu thay đổi.
ROLLBACK;

-- Bước D: query lại; kết quả phải là0 user trigger.
SELECT COUNT(*) AS user_trigger_count
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
WHERE c.relnamespace='dbi202_live'::regnamespace AND NOT t.tgisinternal;
