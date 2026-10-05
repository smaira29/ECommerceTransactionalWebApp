USE ECommerceDB;
GO
-- Set-based: inserted contains ALL rows changed by the statement.
-- Handles INSERT, zero inventory, restocking and attempted status edits.
CREATE OR ALTER TRIGGER dbo.trg_Product_InventoryStatus
ON dbo.Product
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;
    UPDATE p
    SET status = CASE WHEN p.quantity = 0 THEN 'OUT_OF_STOCK' ELSE 'IN_STOCK' END
    FROM dbo.Product AS p
    INNER JOIN inserted AS i ON i.product_id = p.product_id
    WHERE p.status <> CASE WHEN p.quantity = 0 THEN 'OUT_OF_STOCK' ELSE 'IN_STOCK' END;
    -- Recursive execution stops naturally: a corrected row no longer differs.
END;
GO
