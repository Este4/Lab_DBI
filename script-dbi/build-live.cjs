const fs=require('fs'),path=require('path');
const root=__dirname,base=path.resolve(root,'../demo_data');
const write=(f,s)=>fs.writeFileSync(path.join(root,f),s.trim()+'\n');
const adapt=s=>s.replaceAll('dbi202_demo','dbi202_live');
for(const f of ['00_setup_demo.sql','02_reserve.sql','03_pack_and_approve.sql','04_handover.sql','05_deliver.sql'])write(f,adapt(fs.readFileSync(path.join(base,f),'utf8')));
const seed=fs.readFileSync(path.join(base,'01_seed_data.sql'),'utf8');
const insert=t=>{const m=seed.match(new RegExp('INSERT INTO '+t+'\\([\\s\\S]*?;'));if(!m)throw Error(t);return m[0];};
let s='BEGIN;\nSET LOCAL search_path TO dbi202_live;\n\n';
s+='-- A. Bảng độc lập: chọn và chạy lần lượt từng INSERT để giải thích.\n';
for(const t of ['sales_channel','warehouse','product','staff','shipping_carrier','box_template','packaging_material'])s+=insert(t)+'\n\n';
s+='-- B. Shop phụ thuộc kênh; khách phụ thuộc shop.\n'+insert('sales_account')+'\n\n'+insert('customer')+'\n\n';
s+='-- C. Function tạo/cập nhật INVENTORY rồi ghi INVENTORY_TRANSACTION.\n'+seed.match(/SELECT stock_movement\([^;]+;/g).join('\n')+'\n\n';
s+='-- D. Đơn sau shop/khách/hãng; dòng đơn sau đơn và sản phẩm.\n'+insert('customer_order')+'\n\n'+insert('order_line')+'\n\n';
s+='-- E. Sau ID tường minh, đồng bộ sequence cho lần thêm tự động tiếp theo.\n'+seed.match(/SELECT setval\([^;]+;/g).join('\n')+'\nCOMMIT;\n';
s+='SET search_path TO dbi202_live;\nSELECT order_id,external_order_id,order_status FROM customer_order ORDER BY order_id;\n';
write('01_insert_theo_tang.sql',s);
const queries={
 Q1:`SELECT o.external_order_id,ch.channel_name,a.shop_display_name,
       p.product_name,l.quantity_ordered,l.unit_price_at_order,
       l.quantity_ordered*l.unit_price_at_order AS line_total
FROM customer_order o
JOIN sales_account a ON a.sales_account_id=o.sales_account_id
JOIN sales_channel ch ON ch.channel_id=a.channel_id
JOIN order_line l ON l.order_id=o.order_id
JOIN product p ON p.product_id=l.product_id
WHERE o.order_id=1 ORDER BY l.line_no;`,
 Q2:`SELECT o.order_id,o.external_order_id,
       COUNT(l.order_line_id) AS line_count,
       SUM(l.quantity_ordered*l.unit_price_at_order) AS goods_total
FROM customer_order o JOIN order_line l ON l.order_id=o.order_id
GROUP BY o.order_id,o.external_order_id ORDER BY o.order_id;`,
 Q3:`SELECT ch.channel_name,COUNT(DISTINCT o.order_id) AS order_count
FROM sales_channel ch
LEFT JOIN sales_account a ON a.channel_id=ch.channel_id
LEFT JOIN customer_order o ON o.sales_account_id=a.sales_account_id
GROUP BY ch.channel_id,ch.channel_name ORDER BY ch.channel_id;`,
 Q4:`SELECT w.warehouse_name,p.product_name,i.physical_qty,i.reserved_qty,
       i.physical_qty-i.reserved_qty AS available_qty
FROM inventory i JOIN warehouse w ON w.warehouse_id=i.warehouse_id
JOIN product p ON p.product_id=i.product_id
ORDER BY i.warehouse_id,i.product_id;`,
 Q5:`SELECT p.package_id,b.unit_cost AS box_cost,
       COALESCE(SUM(pm.quantity_used*m.unit_cost),0) AS material_cost,
       b.unit_cost+COALESCE(SUM(pm.quantity_used*m.unit_cost),0) AS packaging_cost
FROM package p JOIN box_template b ON b.box_template_id=p.box_template_id
LEFT JOIN package_material pm ON pm.package_id=p.package_id
LEFT JOIN packaging_material m ON m.material_id=pm.material_id
WHERE p.order_id=1 GROUP BY p.package_id,b.unit_cost ORDER BY p.package_id;`,
 Q6:`SELECT i.warehouse_id,i.product_id,i.physical_qty,
       COALESCE(SUM(t.quantity_change),0) AS ledger_balance,
       i.physical_qty=COALESCE(SUM(t.quantity_change),0) AS balanced
FROM inventory i LEFT JOIN inventory_transaction t
  ON t.warehouse_id=i.warehouse_id AND t.product_id=i.product_id
GROUP BY i.warehouse_id,i.product_id,i.physical_qty
ORDER BY i.warehouse_id,i.product_id;`,
 Q7:`SELECT COUNT(*) AS delivered_order_count,COALESCE(SUM(s.goods_total),0) AS delivered_goods_value
FROM (
 SELECT o.order_id,SUM(l.quantity_ordered*l.unit_price_at_order) AS goods_total
 FROM customer_order o JOIN order_line l ON l.order_id=o.order_id
 WHERE o.order_status='DELIVERED' GROUP BY o.order_id
) s;`,
 META:`SELECT current_database(),current_schema();
SELECT COUNT(*) AS user_trigger_count
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
WHERE c.relnamespace='dbi202_live'::regnamespace AND NOT t.tgisinternal;`
};
write('06_queries.sql','SET search_path TO dbi202_live;\n\n'+Object.entries(queries).map(([k,v])=>'-- '+k+'\n'+v).join('\n\n'));
const bad=[
 {id:'E1',name:'Trùng PK ghép',code:'23505',constraint:'pk_inventory',sql:'INSERT INTO inventory(warehouse_id,product_id,physical_qty,reserved_qty) VALUES(1,1,1,0);'},
 {id:'E2',name:'FK sản phẩm không tồn tại',code:'23503',constraint:'fk_order_line_product',sql:'INSERT INTO order_line(order_line_id,order_id,line_no,product_id,quantity_ordered,unit_price_at_order) VALUES(900,1,3,999,1,1000);'},
 {id:'E3',name:'Reserve vượt physical',code:'23514',constraint:'ck_inventory_reserved_limit',sql:'UPDATE inventory SET reserved_qty=11 WHERE warehouse_id=1 AND product_id=1;'},
 {id:'E4',name:'Trùng mã đơn trong shop',code:'23505',constraint:'uq_customer_order_account_external',sql:"INSERT INTO customer_order(order_id,sales_account_id,external_order_id,recipient_name,delivery_address) VALUES(900,1,'DEMO-SUCCESS','Khach demo','Dia chi demo');"},
 {id:'E5',name:'Thiếu tên sản phẩm',code:'23502',column:'product_name',sql:'UPDATE product SET product_name=NULL WHERE product_id=1;'},
 {id:'E6',name:'Function từ chối thiếu hàng',code:'P0001',sql:'SELECT reserve_order(2,1);'}
];
write('07_constraints_live.sql','-- KHÔNG chạy toàn file. Mỗi ca có 3 khối cần chọn/chạy riêng.\n'+
 bad.map(x=>`\n-- ${x.id}: ${x.name}; mong đợi SQLSTATE ${x.code}.\n-- Khối 1: mở transaction.\nBEGIN;\nSET LOCAL search_path TO dbi202_live;\n\n-- Khối 2: chọn RIÊNG câu dưới, chạy để hiện lỗi đỏ.\n${x.sql}\n\n-- Khối 3: sau lỗi, chọn RIÊNG ROLLBACK và chạy.\nROLLBACK;\n`).join('\n'));
const triggerSetup=`BEGIN;
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
FOR EACH ROW EXECUTE FUNCTION demo_check_same_order();`;
const triggerBad=`INSERT INTO package_line(package_id,order_line_id,quantity_in_package)
SELECT MIN(package_id),3,1 FROM package WHERE order_id=1;`;
write('08_trigger_minh_hoa.sql',`-- CHỈ chạy sau 03_pack_and_approve.sql.
-- Bước A: chọn và chạy toàn bộ từ BEGIN tới hết CREATE TRIGGER.
${triggerSetup}

-- Bước B: chọn RIÊNG INSERT bên dưới và chạy; mong đợi lỗi đỏ SQLSTATE23514.
-- Kiện thuộc đơn1 nhưng dòng3 thuộc đơn2; không gọi set_package_line ở đây.
${triggerBad}

-- Bước C: sau lỗi, chọn RIÊNG ROLLBACK và chạy.
-- Rollback cả INSERT lỗi lẫn CREATE TRIGGER/FUNCTION minh họa, không lưu thay đổi.
ROLLBACK;

-- Bước D: query lại; kết quả phải là0 user trigger.
SELECT COUNT(*) AS user_trigger_count
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
WHERE c.relnamespace='dbi202_live'::regnamespace AND NOT t.tgisinternal;`);
const manifest={schema:'dbi202_live',baseCommit:'2f5a6ab7a53037b01276838c7434d6097480f7a6',queries,bad,triggerSetup,triggerBad};
write('live-manifest.json',JSON.stringify(manifest,null,2));
console.log('Wrote live SQL and manifest');
