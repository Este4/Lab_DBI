-- KHÔNG chạy toàn file. Mỗi ca có 3 khối cần chọn/chạy riêng.

-- E1: Trùng PK ghép; mong đợi SQLSTATE 23505.
-- Khối 1: mở transaction.
BEGIN;
SET LOCAL search_path TO dbi202_live;

-- Khối 2: chọn RIÊNG câu dưới, chạy để hiện lỗi đỏ.
INSERT INTO inventory(warehouse_id,product_id,physical_qty,reserved_qty) VALUES(1,1,1,0);

-- Khối 3: sau lỗi, chọn RIÊNG ROLLBACK và chạy.
ROLLBACK;


-- E2: FK sản phẩm không tồn tại; mong đợi SQLSTATE 23503.
-- Khối 1: mở transaction.
BEGIN;
SET LOCAL search_path TO dbi202_live;

-- Khối 2: chọn RIÊNG câu dưới, chạy để hiện lỗi đỏ.
INSERT INTO order_line(order_line_id,order_id,line_no,product_id,quantity_ordered,unit_price_at_order) VALUES(900,1,3,999,1,1000);

-- Khối 3: sau lỗi, chọn RIÊNG ROLLBACK và chạy.
ROLLBACK;


-- E3: Reserve vượt physical; mong đợi SQLSTATE 23514.
-- Khối 1: mở transaction.
BEGIN;
SET LOCAL search_path TO dbi202_live;

-- Khối 2: chọn RIÊNG câu dưới, chạy để hiện lỗi đỏ.
UPDATE inventory SET reserved_qty=11 WHERE warehouse_id=1 AND product_id=1;

-- Khối 3: sau lỗi, chọn RIÊNG ROLLBACK và chạy.
ROLLBACK;


-- E4: Trùng mã đơn trong shop; mong đợi SQLSTATE 23505.
-- Khối 1: mở transaction.
BEGIN;
SET LOCAL search_path TO dbi202_live;

-- Khối 2: chọn RIÊNG câu dưới, chạy để hiện lỗi đỏ.
INSERT INTO customer_order(order_id,sales_account_id,external_order_id,recipient_name,delivery_address) VALUES(900,1,'DEMO-SUCCESS','Khach demo','Dia chi demo');

-- Khối 3: sau lỗi, chọn RIÊNG ROLLBACK và chạy.
ROLLBACK;


-- E5: Thiếu tên sản phẩm; mong đợi SQLSTATE 23502.
-- Khối 1: mở transaction.
BEGIN;
SET LOCAL search_path TO dbi202_live;

-- Khối 2: chọn RIÊNG câu dưới, chạy để hiện lỗi đỏ.
UPDATE product SET product_name=NULL WHERE product_id=1;

-- Khối 3: sau lỗi, chọn RIÊNG ROLLBACK và chạy.
ROLLBACK;


-- E6: Function từ chối thiếu hàng; mong đợi SQLSTATE P0001.
-- Khối 1: mở transaction.
BEGIN;
SET LOCAL search_path TO dbi202_live;

-- Khối 2: chọn RIÊNG câu dưới, chạy để hiện lỗi đỏ.
SELECT reserve_order(2,1);

-- Khối 3: sau lỗi, chọn RIÊNG ROLLBACK và chạy.
ROLLBACK;
