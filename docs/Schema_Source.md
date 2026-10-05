# Conceptual and Logical Schema

Student: Smaira Arora

## Conceptual relationships

Every child has exactly one parent. Orders can temporarily have zero items while being assembled; completed orders require one or more.

- Vendor (1) -> Product (0..many)
- Customer (1) -> Order (0..many)
- Order (1) -> OrderItem (0..many)
- Product (1) -> OrderItem (0..many)
- Order (1) -> Invoice (0..1)
- Order (1) -> Payment (0..many)

## Vendor

| Column | SQL Server type | Rules |
|---|---|---|
| vendor_id | BIGINT IDENTITY(1,1) | PK |
| name | NVARCHAR(100) | required; nonblank |
| email | NVARCHAR(254) | required; unique |
| phone | NVARCHAR(30) | optional |
| is_active | BIT | required; default 1 |

## Customer

| Column | SQL Server type | Rules |
|---|---|---|
| customer_id | BIGINT IDENTITY(1,1) | PK |
| first_name | NVARCHAR(60) | required; nonblank |
| last_name | NVARCHAR(60) | required; nonblank |
| email | NVARCHAR(254) | required; unique |
| phone | NVARCHAR(30) | optional |
| is_active | BIT | required; default 1 |

## Product

| Column | SQL Server type | Rules |
|---|---|---|
| product_id | BIGINT IDENTITY(1,1) | PK |
| vendor_id | BIGINT | required; FK Vendor |
| sku | NVARCHAR(50) | required; unique |
| name | NVARCHAR(120) | required; nonblank |
| description | NVARCHAR(1000) | optional |
| price | DECIMAL(19,2) | required; > 0 |
| quantity | INT | required; >= 0; default 0 |
| status | VARCHAR(20) | required; trigger maintained |
| is_active | BIT | required; default 1 |

## Order

| Column | SQL Server type | Rules |
|---|---|---|
| order_id | BIGINT IDENTITY(1,1) | PK |
| customer_id | BIGINT | required; FK Customer |
| order_date | DATETIME2(0) | required; UTC default |
| status | VARCHAR(20) | required; default PENDING |
| total_amount | DECIMAL(19,2) | required; >= 0 |
| currency | CHAR(3) | required; CAD only |

## OrderItem

| Column | SQL Server type | Rules |
|---|---|---|
| order_item_id | BIGINT IDENTITY(1,1) | PK |
| order_id | BIGINT | required; FK Order |
| product_id | BIGINT | required; FK Product |
| quantity | INT | required; > 0 |
| unit_price | DECIMAL(19,2) | required; > 0; price snapshot |
| line_total | DECIMAL(19,2) | computed; quantity * unit_price |

## Invoice

| Column | SQL Server type | Rules |
|---|---|---|
| invoice_id | BIGINT IDENTITY(1,1) | PK |
| order_id | BIGINT | required; unique; FK Order |
| invoice_number | NVARCHAR(40) | required; unique |
| issued_at | DATETIME2(0) | required; UTC default |
| total_amount | DECIMAL(19,2) | required; >= 0 |
| status | VARCHAR(20) | required; default ISSUED |

## Payment

| Column | SQL Server type | Rules |
|---|---|---|
| payment_id | BIGINT IDENTITY(1,1) | PK |
| order_id | BIGINT | required; FK Order |
| method | VARCHAR(20) | required; CARD or BANK |
| amount | DECIMAL(19,2) | required; > 0 |
| status | VARCHAR(20) | required; default SUCCESS |
| reference | NVARCHAR(80) | required; unique |
| paid_at | DATETIME2(0) | required; UTC default |

OrderItem has UNIQUE(order_id, product_id). All FKs use NO ACTION. Product status has IN_STOCK / OUT_OF_STOCK; Order PENDING / PAID / CANCELLED; Invoice ISSUED / PAID / VOID; Payment SUCCESS / FAILED / REFUNDED. Payment method: CARD / BANK. Currency: CAD.
