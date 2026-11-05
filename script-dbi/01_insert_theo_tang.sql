BEGIN;
SET LOCAL search_path TO dbi202_live;

-- A. Bảng độc lập: chọn và chạy lần lượt từng INSERT để giải thích.
INSERT INTO sales_channel(channel_id,channel_name,channel_code) VALUES
 (1,'Shopee','DEMO-SHOPEE'),(2,'Website','DEMO-WEB');

INSERT INTO warehouse(warehouse_id,warehouse_name,warehouse_address) VALUES
 (1,'Kho Thủ Đức','Thủ Đức, TP. Hồ Chí Minh'),(2,'Kho Hà Nội','Cầu Giấy, Hà Nội');

INSERT INTO product(product_id,sku,product_name,unit_weight_gram,length_cm,width_cm,height_cm,is_fragile) VALUES
 (1,'DEMO-BOOK','Sách DBI202',100,5,5,5,FALSE),
 (2,'DEMO-GLASS','Ly thủy tinh',250,8,8,8,TRUE);

INSERT INTO staff(staff_id,full_name,email,is_active) VALUES(1,'Nhân viên demo','demo@dbi202.example',TRUE);

INSERT INTO shipping_carrier(carrier_id,carrier_name,contact_phone) VALUES(1,'SPX Demo','19001221');

INSERT INTO box_template(box_template_id,box_code,inner_length_cm,inner_width_cm,inner_height_cm,max_weight_gram,unit_cost)
 VALUES(1,'DEMO-BOX-1500',15,10,10,1500,2500);

INSERT INTO packaging_material(material_id,material_code,material_name,measure_unit,unit_cost) VALUES
 (1,'DEMO-BUBBLE','Xốp chống sốc','METER',1200),(2,'DEMO-TAPE','Băng keo','ROLL',15000);

-- B. Shop phụ thuộc kênh; khách phụ thuộc shop.
INSERT INTO sales_account(sales_account_id,channel_id,external_shop_id,shop_display_name) VALUES
 (1,1,'SHOP-DEMO-A','Shop sách và ly'),(2,2,'WEBSITE-DEMO','Website của nhóm');

INSERT INTO customer(customer_id,sales_account_id,external_customer_id,display_name,contact_phone) VALUES
 (1,1,'CUS-LAN','Nguyễn Lan','0901234567'),(2,2,'CUS-MINH','Trần Minh','0902345678');

-- C. Function tạo/cập nhật INVENTORY rồi ghi INVENTORY_TRANSACTION.
SELECT stock_movement(1,1,'RECEIPT',10,'INIT-W1-BOOK');
SELECT stock_movement(1,2,'RECEIPT',3,'INIT-W1-GLASS');
SELECT stock_movement(2,1,'RECEIPT',6,'INIT-W2-BOOK');
SELECT stock_movement(2,2,'RECEIPT',5,'INIT-W2-GLASS');

-- D. Đơn sau shop/khách/hãng; dòng đơn sau đơn và sản phẩm.
INSERT INTO customer_order(order_id,sales_account_id,external_order_id,customer_id,recipient_name,recipient_phone,delivery_address,carrier_id)
 VALUES
 (1,1,'DEMO-SUCCESS',1,'Nguyễn Lan','0901234567','Thủ Đức, TP. Hồ Chí Minh',1),
 (2,1,'DEMO-SHORT',1,'Nguyễn Lan','0901234567','Thủ Đức, TP. Hồ Chí Minh',1),
 (3,2,'DEMO-CANCEL',2,'Trần Minh','0902345678','Thủ Đức, TP. Hồ Chí Minh',1),
 (4,1,'DEMO-MOVE',1,'Nguyễn Lan','0901234567','Cầu Giấy, Hà Nội',1);

INSERT INTO order_line(order_line_id,order_id,line_no,product_id,quantity_ordered,unit_price_at_order) VALUES
 (1,1,1,1,5,10000),(2,1,2,2,2,20000),
 (3,2,1,1,99,10000),(4,3,1,1,2,10000),
 (5,4,1,1,2,10000),(6,4,2,2,1,20000);

-- E. Sau ID tường minh, đồng bộ sequence cho lần thêm tự động tiếp theo.
SELECT setval(pg_get_serial_sequence('sales_channel','channel_id'),2,TRUE);
SELECT setval(pg_get_serial_sequence('sales_account','sales_account_id'),2,TRUE);
SELECT setval(pg_get_serial_sequence('customer','customer_id'),2,TRUE);
SELECT setval(pg_get_serial_sequence('warehouse','warehouse_id'),2,TRUE);
SELECT setval(pg_get_serial_sequence('product','product_id'),2,TRUE);
SELECT setval(pg_get_serial_sequence('staff','staff_id'),1,TRUE);
SELECT setval(pg_get_serial_sequence('shipping_carrier','carrier_id'),1,TRUE);
SELECT setval(pg_get_serial_sequence('box_template','box_template_id'),1,TRUE);
SELECT setval(pg_get_serial_sequence('packaging_material','material_id'),2,TRUE);
SELECT setval(pg_get_serial_sequence('customer_order','order_id'),4,TRUE);
SELECT setval(pg_get_serial_sequence('order_line','order_line_id'),6,TRUE);
COMMIT;
SET search_path TO dbi202_live;
SELECT order_id,external_order_id,order_status FROM customer_order ORDER BY order_id;
