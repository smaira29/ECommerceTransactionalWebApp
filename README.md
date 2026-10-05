# E-Commerce Database - Quiz 1
**Student:** Smaira Arora  
**Course:** Transactional Web Applications (420-951-VA)  
**Milestone:** Database completion  
**Date:** October 4, 2026

## Submission contents
- `docs/Database_Design_Smaira_Arora.pdf`: conceptual ER schema, logical schema/data dictionary, design rules and physical implementation explanation.
- `database/create_database.sql`: creates ECommerceDB if absent.
- `database/create_tables.sql`: seven required entities, constraints and indexes.
- `database/create_triggers.sql`: multi-row inventory status trigger.
- `database/insert_sample_data.sql`: synthetic vendors, customers, products and a complete paid purchase.
- `database/verify_database.sql`: table/trigger assertions, multi-row status checks, and an actual forced rollback after order, item, stock, invoice and payment writes.
- `.gitignore`: excludes credentials, backups, generated files and local configuration.

## Requirements and setup (Windows)
Install Microsoft SQL Server and SQL Server Management Studio (SSMS), or use the SQL Server instance already installed for class. These scripts use T-SQL, GO batches and CREATE OR ALTER TRIGGER; use SQL Server 2016 SP1 or later.
1. Open SSMS and connect to your SQL Server instance using your own local authentication.
2. Open and execute `create_database.sql`.
3. Open and execute `create_tables.sql` ONCE on a fresh database. The script does not delete existing data. If existing tables conflict, stop and inspect them; do not rerun blindly.
4. Open and execute `create_triggers.sql`.
5. Open and execute `insert_sample_data.sql` ONCE.
6. Open and execute `verify_database.sql`. Run alone while nobody else edits the database.
7. Refresh Object Explorer, expand ECommerceDB > Tables, and confirm all seven tables.

Run each file separately in this order; GO is an SSMS/sqlcmd batch separator, not a statement accepted directly by JDBC. Setup needs permission to create a database and its objects. All files select ECommerceDB explicitly.

## Expected verification results
Messages should show three PASS messages. Product stock after the seed purchase: mouse 8, keyboard 5, notebook 20, bottle 0. The bottle must be OUT_OF_STOCK. The sample order, invoice and payment totals are each CAD 50.00. The rollback test leaves counts and inventory unchanged. Identity counters can advance during rollback; gaps are normal and are not partial orders.

## Design and business rules
- Vendor 1-to-many Product; Customer 1-to-many Order; Order 1-to-many OrderItem; Product 1-to-many OrderItem; Order 0-or-1 Invoice; Order 0-to-many Payment.
- Every product has a vendor, every order a customer, and every order item an order and product. A completed order must have at least one item; enforce this in the purchase service because a simple foreign key cannot require a parent to have children.
- Invoice.order_id is unique; OrderItem(order_id,product_id) is unique. Repeated cart entries should be combined into one line before checkout.
- Current product prices can change; OrderItem.unit_price preserves the checkout price. line_total is a persisted computed DECIMAL(19,2) value.
- Monetary amounts use DECIMAL(19,2); the Java layer will use BigDecimal. This milestone assumes CAD, no tax, no discount and no shipping charge. Totals are sums of line totals.
- All foreign keys use SQL Server's default NO ACTION. Referenced records cannot be deleted accidentally. Deactivate vendors/products/customers with is_active when they have history.
- SQL constraints protect values and references. Application validation must also validate email format, roles, business totals, active accounts and payment eligibility. Cross-table order/invoice/payment consistency must be coordinated in one transaction.
- Payment.method records CARD/BANK; payment references are synthetic, and no card numbers, CVVs, bank credentials or passwords are stored in this milestone.

## Transaction and concurrency design
The sample purchase commits all related writes together. Verification deliberately raises an insufficient-payment error after writes have occurred and rolls back the entire transaction. Trigger changes are included in that transaction too.
The verification example reads inventory with UPDLOCK and HOLDLOCK before decrementing it. The future Spring purchase service should use pessimistic write locks inside @Transactional, lock all products in ascending product_id order, validate inventory after locks are acquired, and commit order/items/inventory/invoice/payment together. All purchase paths must use the same locking discipline. Deadlock victims should return a clear error or use a bounded retry of the complete operation.

The final application will implement authentication, role enforcement, payment services, REST, JPA entities and React in later milestones. This ZIP is the database milestone, not the completed final application. Real payment gateways need an additional strategy for external side effects; SQL rollback alone cannot undo a real bank charge.

## Verification status
Scripts and schema documentation were reviewed for consistency. An executing SQL Server instance was not available in the authoring environment, so SQL Server execution must be verified in SSMS using the included script; no fabricated execution screenshots are included.

## GitHub and LEA
Extract the ZIP. Create a dedicated GitHub repository for this e-commerce project (do not use the mobile Wanderlist repository). In the extracted project folder terminal:
```bash
git init
git add .
git commit -m "Add e-commerce conceptual logical and SQL Server database schemas"
git branch -M main
```
Add your new repository URL and push:
```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```
Replace the URL with your own repository URL. Do not commit credentials or connection strings containing passwords. Submit the supplied ZIP on LEA under Quiz1: Database completion. If instructed, include the GitHub URL in the submission comment. Capture genuine SSMS table/verification screenshots after running the scripts if your teacher requests execution evidence.

## References
- Project description supplied by the instructor, especially entities, relationships, database, trigger and milestone sections.
- Microsoft Learn: [Create DML Triggers to Handle Multiple Rows of Data](https://learn.microsoft.com/en-us/sql/relational-databases/triggers/create-dml-triggers-to-handle-multiple-rows-of-data)
- Microsoft Learn: [Table Hints - UPDLOCK / HOLDLOCK](https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-table)
