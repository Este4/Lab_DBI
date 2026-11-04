# DBI202 - Topic 3

Relational Database Design and Implementation for Topic 3.

## Database Modules (`database/`)

### 1. Sales Channels and Orders
- `sales_channel.sql`: External sales channel integrations.
- `customer_order.sql`: Customer orders imported from sales channels.
- `order_line.sql`: Itemized lines within each order.

### 2. Warehouses and Inventory
- `warehouse.sql`: Warehouse facilities and locations.
- `product.sql`: Product catalog and dimensions/fragility specs.
- `inventory.sql`: Stock tracking per warehouse and product (physical and reserved quantities).
- `inventory_transaction.sql`: Stock movement ledger (receipt, shipment, adjustment).

### 3. Packaging and Shipping
- `staff.sql`: Personnel responsible for order assignment and packaging approval.
- `shipping_carrier.sql`: Logistics and shipping carriers (GHTK, Viettel Post, VNPost, SPX).
- `box_template.sql`: Standard packaging box templates with dimensions and max capacity.
- `packaging_material.sql`: Consumable packaging materials (bubble wrap, packing tape, air pillows).
- `package.sql`: Physical packages created for orders with box and approval tracking.
- `package_line.sql`: M:N allocation of order line quantities into specific packages.
- `package_material.sql`: M:N consumption tracking of packaging materials per package.
- `shipment.sql`: Carrier shipment tracking, tracking numbers, and delivery lifecycle.
- `alter_order_carrier_staff.sql`: Optional schema extension linking orders to carriers and staff.
- `packaging_and_shipping_sample.sql`: Sample data and verification queries.
