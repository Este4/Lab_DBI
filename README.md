# DBI202 - Topic 3: Relational Database Design

Relational Database Design & Implementation for **Topic 3** (Introduction to Databases - DBI202).

## Architecture & Scope

This project implements the **16 core relations** documented in the group report `Lab4_Topic3.docx`:

### Module 01: Sales Channels and Orders
1. `sales_channel.sql`: External sales platforms (Shopee, Lazada, TikTok Shop).
2. `sales_account.sql`: Integrated merchant stores/accounts belonging to channels.
3. `customer.sql`: Customer profiles associated with sales accounts.
4. `customer_order.sql`: Customer order headers assigned to warehouses and carriers.
5. `order_line.sql`: Itemized product lines with quantity, unit price, and reservation.

### Module 02: Warehouses and Inventory
6. `warehouse.sql`: Warehouse facilities and physical storage locations.
7. `product.sql`: Product catalog with weight, dimensions, and fragility flags.
8. `inventory.sql`: Stock ledger per warehouse & product (physical & reserved quantities).
9. *(Optional)* `inventory_transaction.sql`: Movement ledger (receipt, shipment, adjustment).

### Module 03: Packaging and Shipping
10. `staff.sql`: Personnel handling order assignment and packaging approval.
11. `shipping_carrier.sql`: Logistics partners (GHTK, Viettel Post, VNPost, SPX).
12. `box_template.sql`: Standard packing box dimensions, weight limits, and unit costs.
13. `packaging_material.sql`: Consumable packaging materials (bubble wrap, packing tape, air pillows).
14. `package.sql`: Physical parcels prepared for orders, linked to box templates and approving staff.
15. `package_line.sql`: M:N allocation mapping order lines into specific packages.
16. `package_material.sql`: M:N consumption tracking of packaging materials per package.
17. `shipment.sql`: Carrier shipment tracking, handover timestamps, and delivery lifecycle.

---

## Quick Start / Execution Order

To initialize the complete database in PostgreSQL, execute the all-in-one script in topological dependency order:

```bash
psql -U <username> -d <database_name> -f database/init_schema.sql
```

Or execute individual files in the following dependency sequence:
1. `sales_channel.sql`
2. `warehouse.sql`
3. `product.sql`
4. `staff.sql`
5. `shipping_carrier.sql`
6. `box_template.sql`
7. `packaging_material.sql`
8. `sales_account.sql`
9. `inventory.sql`
10. `customer.sql`
11. `customer_order.sql`
12. `order_line.sql`
13. `package.sql`
14. `package_line.sql`
15. `package_material.sql`
16. `shipment.sql`

To load sample data for testing:
```bash
psql -U <username> -d <database_name> -f database/packaging_and_shipping_sample.sql
```
