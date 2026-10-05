-- Fresh schema installation. Run once after create_database.sql.
-- Stop if tables already exist; no destructive DROP statements.
USE ECommerceDB;
GO
SET XACT_ABORT ON;
GO
BEGIN TRANSACTION;
CREATE TABLE dbo.[Vendor] (
    [vendor_id] BIGINT IDENTITY(1,1) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [email] NVARCHAR(254) NOT NULL,
    [phone] NVARCHAR(30) NULL,
    [is_active] BIT NOT NULL CONSTRAINT [DF_Vendor_is_active] DEFAULT (1),
    CONSTRAINT [PK_Vendor] PRIMARY KEY ([vendor_id]),
    CONSTRAINT [CK_Vendor_name_NotBlank] CHECK (LEN(LTRIM(RTRIM([name]))) > 0),
    CONSTRAINT [UQ_Vendor_email] UNIQUE ([email]),
    CONSTRAINT [CK_Vendor_email_NotBlank] CHECK (LEN(LTRIM(RTRIM([email]))) > 0)
);

CREATE TABLE dbo.[Customer] (
    [customer_id] BIGINT IDENTITY(1,1) NOT NULL,
    [first_name] NVARCHAR(60) NOT NULL,
    [last_name] NVARCHAR(60) NOT NULL,
    [email] NVARCHAR(254) NOT NULL,
    [phone] NVARCHAR(30) NULL,
    [is_active] BIT NOT NULL CONSTRAINT [DF_Customer_is_active] DEFAULT (1),
    CONSTRAINT [PK_Customer] PRIMARY KEY ([customer_id]),
    CONSTRAINT [CK_Customer_first_name_NotBlank] CHECK (LEN(LTRIM(RTRIM([first_name]))) > 0),
    CONSTRAINT [CK_Customer_last_name_NotBlank] CHECK (LEN(LTRIM(RTRIM([last_name]))) > 0),
    CONSTRAINT [UQ_Customer_email] UNIQUE ([email]),
    CONSTRAINT [CK_Customer_email_NotBlank] CHECK (LEN(LTRIM(RTRIM([email]))) > 0)
);

CREATE TABLE dbo.[Product] (
    [product_id] BIGINT IDENTITY(1,1) NOT NULL,
    [vendor_id] BIGINT NOT NULL,
    [sku] NVARCHAR(50) NOT NULL,
    [name] NVARCHAR(120) NOT NULL,
    [description] NVARCHAR(1000) NULL,
    [price] DECIMAL(19,2) NOT NULL,
    [quantity] INT NOT NULL CONSTRAINT [DF_Product_quantity] DEFAULT (0),
    [status] VARCHAR(20) NOT NULL CONSTRAINT [DF_Product_status] DEFAULT ('IN_STOCK'),
    [is_active] BIT NOT NULL CONSTRAINT [DF_Product_is_active] DEFAULT (1),
    CONSTRAINT [PK_Product] PRIMARY KEY ([product_id]),
    CONSTRAINT [FK_Product_Vendor] FOREIGN KEY ([vendor_id]) REFERENCES dbo.[Vendor] ([vendor_id]),
    CONSTRAINT [UQ_Product_sku] UNIQUE ([sku]),
    CONSTRAINT [CK_Product_sku_NotBlank] CHECK (LEN(LTRIM(RTRIM([sku]))) > 0),
    CONSTRAINT [CK_Product_name_NotBlank] CHECK (LEN(LTRIM(RTRIM([name]))) > 0),
    CONSTRAINT [CK_Product_price] CHECK ([price] > 0),
    CONSTRAINT [CK_Product_quantity] CHECK ([quantity] >= 0),
    CONSTRAINT [CK_Product_Status] CHECK ([status] IN ('IN_STOCK', 'OUT_OF_STOCK'))
);

CREATE TABLE dbo.[Order] (
    [order_id] BIGINT IDENTITY(1,1) NOT NULL,
    [customer_id] BIGINT NOT NULL,
    [order_date] DATETIME2(0) NOT NULL CONSTRAINT [DF_Order_order_date] DEFAULT (SYSUTCDATETIME()),
    [status] VARCHAR(20) NOT NULL CONSTRAINT [DF_Order_status] DEFAULT ('PENDING'),
    [total_amount] DECIMAL(19,2) NOT NULL,
    [currency] CHAR(3) NOT NULL CONSTRAINT [DF_Order_currency] DEFAULT ('CAD'),
    CONSTRAINT [PK_Order] PRIMARY KEY ([order_id]),
    CONSTRAINT [FK_Order_Customer] FOREIGN KEY ([customer_id]) REFERENCES dbo.[Customer] ([customer_id]),
    CONSTRAINT [CK_Order_total_amount] CHECK ([total_amount] >= 0),
    CONSTRAINT [CK_Order_Status] CHECK ([status] IN ('PENDING', 'PAID', 'CANCELLED')),
    CONSTRAINT [CK_Order_Currency] CHECK ([currency] = 'CAD')
);

CREATE TABLE dbo.[OrderItem] (
    [order_item_id] BIGINT IDENTITY(1,1) NOT NULL,
    [order_id] BIGINT NOT NULL,
    [product_id] BIGINT NOT NULL,
    [quantity] INT NOT NULL,
    [unit_price] DECIMAL(19,2) NOT NULL,
    [line_total] AS CONVERT(DECIMAL(19,2), [quantity] * [unit_price]) PERSISTED,
    CONSTRAINT [PK_OrderItem] PRIMARY KEY ([order_item_id]),
    CONSTRAINT [FK_OrderItem_Order] FOREIGN KEY ([order_id]) REFERENCES dbo.[Order] ([order_id]),
    CONSTRAINT [FK_OrderItem_Product] FOREIGN KEY ([product_id]) REFERENCES dbo.[Product] ([product_id]),
    CONSTRAINT [CK_OrderItem_quantity] CHECK ([quantity] > 0),
    CONSTRAINT [CK_OrderItem_unit_price] CHECK ([unit_price] > 0),
    CONSTRAINT [UQ_OrderItem_Order_Product] UNIQUE ([order_id], [product_id])
);

CREATE TABLE dbo.[Invoice] (
    [invoice_id] BIGINT IDENTITY(1,1) NOT NULL,
    [order_id] BIGINT NOT NULL,
    [invoice_number] NVARCHAR(40) NOT NULL,
    [issued_at] DATETIME2(0) NOT NULL CONSTRAINT [DF_Invoice_issued_at] DEFAULT (SYSUTCDATETIME()),
    [total_amount] DECIMAL(19,2) NOT NULL,
    [status] VARCHAR(20) NOT NULL CONSTRAINT [DF_Invoice_status] DEFAULT ('ISSUED'),
    CONSTRAINT [PK_Invoice] PRIMARY KEY ([invoice_id]),
    CONSTRAINT [UQ_Invoice_order_id] UNIQUE ([order_id]),
    CONSTRAINT [FK_Invoice_Order] FOREIGN KEY ([order_id]) REFERENCES dbo.[Order] ([order_id]),
    CONSTRAINT [UQ_Invoice_invoice_number] UNIQUE ([invoice_number]),
    CONSTRAINT [CK_Invoice_invoice_number_NotBlank] CHECK (LEN(LTRIM(RTRIM([invoice_number]))) > 0),
    CONSTRAINT [CK_Invoice_total_amount] CHECK ([total_amount] >= 0),
    CONSTRAINT [CK_Invoice_Status] CHECK ([status] IN ('ISSUED', 'PAID', 'VOID'))
);

CREATE TABLE dbo.[Payment] (
    [payment_id] BIGINT IDENTITY(1,1) NOT NULL,
    [order_id] BIGINT NOT NULL,
    [method] VARCHAR(20) NOT NULL,
    [amount] DECIMAL(19,2) NOT NULL,
    [status] VARCHAR(20) NOT NULL CONSTRAINT [DF_Payment_status] DEFAULT ('SUCCESS'),
    [reference] NVARCHAR(80) NOT NULL,
    [paid_at] DATETIME2(0) NOT NULL CONSTRAINT [DF_Payment_paid_at] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_Payment] PRIMARY KEY ([payment_id]),
    CONSTRAINT [FK_Payment_Order] FOREIGN KEY ([order_id]) REFERENCES dbo.[Order] ([order_id]),
    CONSTRAINT [CK_Payment_amount] CHECK ([amount] > 0),
    CONSTRAINT [UQ_Payment_reference] UNIQUE ([reference]),
    CONSTRAINT [CK_Payment_reference_NotBlank] CHECK (LEN(LTRIM(RTRIM([reference]))) > 0),
    CONSTRAINT [CK_Payment_Status] CHECK ([status] IN ('SUCCESS', 'FAILED', 'REFUNDED')),
    CONSTRAINT [CK_Payment_Method] CHECK ([method] IN ('CARD', 'BANK'))
);

CREATE INDEX IX_Product_Vendor ON dbo.Product(vendor_id);
CREATE INDEX IX_Order_Customer ON dbo.[Order](customer_id);
CREATE INDEX IX_OrderItem_Product ON dbo.OrderItem(product_id);
CREATE INDEX IX_Payment_Order ON dbo.Payment(order_id);
COMMIT TRANSACTION;
GO
