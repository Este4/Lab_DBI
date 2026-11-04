-- Module: 03 - Packaging and Shipping integration
-- Description: Optional migration to link customer_order with staff (assigner) and shipping_carrier
-- as documented in the Lab 4 Topic 3 Relational Schema (Section 4.4.09).

ALTER TABLE customer_order
    ADD COLUMN IF NOT EXISTS assigned_by_staff_id INT,
    ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS carrier_id INT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_customer_order_staff'
    ) THEN
        ALTER TABLE customer_order
            ADD CONSTRAINT fk_customer_order_staff FOREIGN KEY (assigned_by_staff_id)
                REFERENCES staff (staff_id) ON DELETE RESTRICT ON UPDATE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_customer_order_carrier'
    ) THEN
        ALTER TABLE customer_order
            ADD CONSTRAINT fk_customer_order_carrier FOREIGN KEY (carrier_id)
                REFERENCES shipping_carrier (carrier_id) ON DELETE RESTRICT ON UPDATE RESTRICT;
    END IF;
END $$;

