SET search_path TO dbi202_live;

-- Q1
SELECT o.external_order_id,ch.channel_name,a.shop_display_name,
       p.product_name,l.quantity_ordered,l.unit_price_at_order,
       l.quantity_ordered*l.unit_price_at_order AS line_total
FROM customer_order o
JOIN sales_account a ON a.sales_account_id=o.sales_account_id
JOIN sales_channel ch ON ch.channel_id=a.channel_id
JOIN order_line l ON l.order_id=o.order_id
JOIN product p ON p.product_id=l.product_id
WHERE o.order_id=1 ORDER BY l.line_no;

-- Q2
SELECT o.order_id,o.external_order_id,
       COUNT(l.order_line_id) AS line_count,
       SUM(l.quantity_ordered*l.unit_price_at_order) AS goods_total
FROM customer_order o JOIN order_line l ON l.order_id=o.order_id
GROUP BY o.order_id,o.external_order_id ORDER BY o.order_id;

-- Q3
SELECT ch.channel_name,COUNT(DISTINCT o.order_id) AS order_count
FROM sales_channel ch
LEFT JOIN sales_account a ON a.channel_id=ch.channel_id
LEFT JOIN customer_order o ON o.sales_account_id=a.sales_account_id
GROUP BY ch.channel_id,ch.channel_name ORDER BY ch.channel_id;

-- Q4
SELECT w.warehouse_name,p.product_name,i.physical_qty,i.reserved_qty,
       i.physical_qty-i.reserved_qty AS available_qty
FROM inventory i JOIN warehouse w ON w.warehouse_id=i.warehouse_id
JOIN product p ON p.product_id=i.product_id
ORDER BY i.warehouse_id,i.product_id;

-- Q5
SELECT p.package_id,b.unit_cost AS box_cost,
       COALESCE(SUM(pm.quantity_used*m.unit_cost),0) AS material_cost,
       b.unit_cost+COALESCE(SUM(pm.quantity_used*m.unit_cost),0) AS packaging_cost
FROM package p JOIN box_template b ON b.box_template_id=p.box_template_id
LEFT JOIN package_material pm ON pm.package_id=p.package_id
LEFT JOIN packaging_material m ON m.material_id=pm.material_id
WHERE p.order_id=1 GROUP BY p.package_id,b.unit_cost ORDER BY p.package_id;

-- Q6
SELECT i.warehouse_id,i.product_id,i.physical_qty,
       COALESCE(SUM(t.quantity_change),0) AS ledger_balance,
       i.physical_qty=COALESCE(SUM(t.quantity_change),0) AS balanced
FROM inventory i LEFT JOIN inventory_transaction t
  ON t.warehouse_id=i.warehouse_id AND t.product_id=i.product_id
GROUP BY i.warehouse_id,i.product_id,i.physical_qty
ORDER BY i.warehouse_id,i.product_id;

-- Q7
SELECT COUNT(*) AS delivered_order_count,COALESCE(SUM(s.goods_total),0) AS delivered_goods_value
FROM (
 SELECT o.order_id,SUM(l.quantity_ordered*l.unit_price_at_order) AS goods_total
 FROM customer_order o JOIN order_line l ON l.order_id=o.order_id
 WHERE o.order_status='DELIVERED' GROUP BY o.order_id
) s;

-- META
SELECT current_database(),current_schema();
SELECT COUNT(*) AS user_trigger_count
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
WHERE c.relnamespace='dbi202_live'::regnamespace AND NOT t.tgisinternal;
