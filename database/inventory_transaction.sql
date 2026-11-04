-- Requires: inventory.sql.
-- Records PHYSICAL stock changes only; reservations do not create ledger rows.
-- MVP assumption: quantity_change is a signed delta in whole product units.
CREATE TABLE inventory_transaction (
    inventory_transaction_id SERIAL PRIMARY KEY,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    quantity_change INT NOT NULL,
    occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_code VARCHAR(100),
    notes VARCHAR(500),

    CONSTRAINT fk_inventory_transaction_inventory
        FOREIGN KEY (warehouse_id, product_id)
        REFERENCES inventory (warehouse_id, product_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_inventory_transaction_type CHECK (
        transaction_type IN ('RECEIPT', 'SHIPMENT', 'ADJUSTMENT')
    ),
    CONSTRAINT ck_inventory_transaction_nonzero CHECK (quantity_change <> 0),
    CONSTRAINT ck_inventory_transaction_direction CHECK (
        (transaction_type = 'RECEIPT' AND quantity_change > 0)
        OR (transaction_type = 'SHIPMENT' AND quantity_change < 0)
        OR transaction_type = 'ADJUSTMENT'
    ),
    CONSTRAINT ck_inventory_transaction_reference CHECK (
        reference_code IS NULL OR LENGTH(TRIM(reference_code)) > 0
    )
);

-- reference_code can identify an upstream receipt, shipment, or adjustment.
-- It is descriptive, not a foreign key to Packaging/Shipping or CUSTOMER_ORDER.
-- The service must change inventory and insert its ledger row in ONE transaction.
-- CHECK/FK constraints cannot ensure ledger completeness or derive the stock balance.
