-- Run once on a fresh schema, AFTER create_triggers.sql.
-- Synthetic demonstration data; no real credentials or card details.
USE ECommerceDB;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT dbo.Vendor (name,email,phone) VALUES
(N'Maple Tech',N'vendor1@example.com',N'514-555-0101'),
(N'Everyday Essentials',N'vendor2@example.com',N'514-555-0102');
INSERT dbo.Customer (first_name,last_name,email,phone) VALUES
(N'Smaira',N'Arora',N'smaira.demo@example.com',N'514-555-0103'),
(N'Alex',N'Martin',N'alex.demo@example.com',N'514-555-0104');
DECLARE @tech BIGINT=(SELECT vendor_id FROM dbo.Vendor WHERE email=N'vendor1@example.com');
DECLARE @essentials BIGINT=(SELECT vendor_id FROM dbo.Vendor WHERE email=N'vendor2@example.com');
INSERT dbo.Product (vendor_id,sku,name,description,price,quantity) VALUES
(@tech,N'TECH-MOUSE',N'Wireless Mouse',N'Compact mouse',25.00,10),
(@tech,N'TECH-KEYBOARD',N'Keyboard',N'USB keyboard',45.00,5),
(@essentials,N'ESS-NOTEBOOK',N'Notebook',N'Ruled notebook',5.00,20),
(@essentials,N'ESS-BOTTLE',N'Water Bottle',N'Reusable bottle',15.00,0);
DECLARE @customer BIGINT=(SELECT customer_id FROM dbo.Customer WHERE email=N'smaira.demo@example.com');
DECLARE @product BIGINT=(SELECT product_id FROM dbo.Product WHERE sku=N'TECH-MOUSE');
INSERT dbo.[Order] (customer_id,status,total_amount) VALUES (@customer,'PAID',50.00);
DECLARE @order BIGINT=CONVERT(BIGINT,SCOPE_IDENTITY());
INSERT dbo.OrderItem (order_id,product_id,quantity,unit_price) VALUES (@order,@product,2,25.00);
UPDATE dbo.Product SET quantity=quantity-2 WHERE product_id=@product;
INSERT dbo.Invoice (order_id,invoice_number,total_amount,status)
VALUES (@order,N'INV-DEMO-0001',50.00,'PAID');
INSERT dbo.Payment (order_id,method,amount,reference)
VALUES (@order,'CARD',50.00,N'DEMO-PAYMENT-0001');
COMMIT TRANSACTION;
GO
