-- Assertions and rollback demonstration. Run after setup and sample data.
-- All demonstration writes are rolled back; existing data is preserved.
USE ECommerceDB;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF (SELECT COUNT(*) FROM sys.tables WHERE name IN
('Vendor','Customer','Product','Order','OrderItem','Invoice','Payment') AND schema_id=SCHEMA_ID('dbo')) <> 7
    THROW 51000, 'Expected seven application tables.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name='trg_Product_InventoryStatus' AND is_disabled=0)
    THROW 51001, 'Inventory trigger missing or disabled.', 1;
IF EXISTS (SELECT 1 FROM dbo.Product WHERE
    status <> CASE WHEN quantity=0 THEN 'OUT_OF_STOCK' ELSE 'IN_STOCK' END)
    THROW 51002, 'Inventory status inconsistent.', 1;
PRINT 'PASS: required tables, trigger and initial inventory status.';

-- Multi-row trigger test, including restocking.
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.Product SET quantity=0;
    IF EXISTS (SELECT 1 FROM dbo.Product WHERE status <> 'OUT_OF_STOCK')
        THROW 51003, 'Multi-row depletion trigger failed.', 1;
    UPDATE dbo.Product SET quantity=3;
    IF EXISTS (SELECT 1 FROM dbo.Product WHERE status <> 'IN_STOCK')
        THROW 51004, 'Multi-row restocking trigger failed.', 1;
    ROLLBACK TRANSACTION;
    PRINT 'PASS: multi-row trigger and restocking (test writes rolled back).';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- Force an insufficient payment AFTER all five related kinds of writes.
DECLARE @customer BIGINT=(SELECT customer_id FROM dbo.Customer WHERE email=N'smaira.demo@example.com');
DECLARE @product BIGINT=(SELECT product_id FROM dbo.Product WHERE sku=N'TECH-MOUSE');
IF @customer IS NULL OR @product IS NULL
    THROW 51005, 'Load sample data first.', 1;
DECLARE @orders BIGINT=(SELECT COUNT_BIG(*) FROM dbo.[Order]);
DECLARE @items BIGINT=(SELECT COUNT_BIG(*) FROM dbo.OrderItem);
DECLARE @invoices BIGINT=(SELECT COUNT_BIG(*) FROM dbo.Invoice);
DECLARE @payments BIGINT=(SELECT COUNT_BIG(*) FROM dbo.Payment);
DECLARE @stock INT=(SELECT quantity FROM dbo.Product WHERE product_id=@product);
DECLARE @status VARCHAR(20)=(SELECT status FROM dbo.Product WHERE product_id=@product);
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @available INT, @price DECIMAL(19,2);
    SELECT @available=quantity,@price=price FROM dbo.Product WITH (UPDLOCK,HOLDLOCK)
    WHERE product_id=@product;
    IF @available < 1 THROW 51006, 'Insufficient inventory.', 1;
    INSERT dbo.[Order] (customer_id,total_amount) VALUES (@customer,@price);
    DECLARE @order BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
    INSERT dbo.OrderItem(order_id,product_id,quantity,unit_price) VALUES(@order,@product,1,@price);
    UPDATE dbo.Product SET quantity=quantity-1 WHERE product_id=@product;
    INSERT dbo.Invoice(order_id,invoice_number,total_amount)
    VALUES(@order,CONCAT(N'RB-',CONVERT(NVARCHAR(36),NEWID())),@price);
    DECLARE @amount DECIMAL(19,2)=1.00;
    INSERT dbo.Payment(order_id,method,amount,reference)
    VALUES(@order,'BANK',@amount,CONCAT(N'ROLLBACK-PAY-',CONVERT(NVARCHAR(36),NEWID())));
    IF @amount < @price THROW 51007, 'Insufficient payment: deliberate rollback.', 1;
    THROW 51008, 'Expected insufficient payment error did not occur.', 1;
END TRY
BEGIN CATCH
    DECLARE @err INT=ERROR_NUMBER();
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    IF @err <> 51007 THROW;
END CATCH;
IF (SELECT COUNT_BIG(*) FROM dbo.[Order]) <> @orders
 OR (SELECT COUNT_BIG(*) FROM dbo.OrderItem) <> @items
 OR (SELECT COUNT_BIG(*) FROM dbo.Invoice) <> @invoices
 OR (SELECT COUNT_BIG(*) FROM dbo.Payment) <> @payments
 OR (SELECT quantity FROM dbo.Product WHERE product_id=@product) <> @stock
 OR (SELECT status FROM dbo.Product WHERE product_id=@product) <> @status
    THROW 51009, 'Partial changes remain after rollback.', 1;
PRINT 'PASS: order, items, invoice, payment and inventory restored after rollback.';

SELECT vendor_id,name,email,is_active FROM dbo.Vendor;
SELECT customer_id,first_name,last_name,email FROM dbo.Customer;
SELECT product_id,sku,price,quantity,status FROM dbo.Product;
SELECT o.order_id,o.status,o.total_amount,c.email,oi.quantity,oi.unit_price,oi.line_total,
       i.invoice_number,p.method,p.amount
FROM dbo.[Order] o
JOIN dbo.Customer c ON c.customer_id=o.customer_id
JOIN dbo.OrderItem oi ON oi.order_id=o.order_id
JOIN dbo.Invoice i ON i.order_id=o.order_id
JOIN dbo.Payment p ON p.order_id=o.order_id;
GO
