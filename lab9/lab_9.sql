

DROP TABLE IF EXISTS transactions_demo_products;
DROP TABLE IF EXISTS transactions_demo_accounts;

CREATE TABLE accounts (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  balance DECIMAL(10,2) DEFAULT 0.00
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  shop VARCHAR(100) NOT NULL,
  product VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL
);


INSERT INTO accounts (name, balance) VALUES
 ('Alice', 1000.00),
 ('Bob', 500.00),
 ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
 ('Joe''s Shop', 'Coke', 2.50),
 ('Joe''s Shop', 'Pepsi', 3.00);


-- ============================================================
-- 3.2 Task 1: Basic Transaction with COMMIT
-- ============================================================



BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
COMMIT;


BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
COMMIT;
SELECT * FROM accounts ORDER BY id;


-- ============================================================
-- 3.3 Task 2: Using ROLLBACK
-- ============================================================



BEGIN;
UPDATE accounts SET balance = balance - 500.00 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';  
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';  



-- ============================================================
-- 3.4 Task 3: Working with SAVEPOINTs
-- ============================================================

BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';  
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';    

ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';  
COMMIT;
SELECT * FROM accounts ORDER BY id;




-- ============================================================
-- 3.5 Task 4: Isolation Level Demonstration 
-- ============================================================


-- Scenario A: READ COMMITTED
-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';    

SELECT * FROM products WHERE shop = 'Joe''s Shop';    
COMMIT;

-- Terminal 2:
BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;


-- Scenario B: SERIALIZABLE
-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'Joe''s Shop';  

SELECT * FROM products WHERE shop = 'Joe''s Shop';  
COMMIT;

-- Terminal 2:
BEGIN;
DELETE / INSERT ...
COMMIT;



-- a) Terminal1 will see a different result before and after: coke/pepsi first, then fanta (or empty/depending on the operations)

-- b) Terminal1 will not see any changes made by Terminal2 after the begining of the transaction.
-- c) difference: READ COMMITTED shows newly commited data on every query 
--   while SERIALIZABLE gives a consistent snapshot which can lead to errors when conflicted



-- ============================================================
-- 3.6 Task 5: Phantom Read Demonstration (REPEATABLE READ)
-- ============================================================
-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';

SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Terminal 2:
BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;


-- a) REPEATABLE READ Terminal1 will not see the new line. Since it uses snapshot from the begining of the transaction
-- b) Phantom read — it's when you run the same query twice in the same transaction and the second time, new row appear of dissapear even if you didn't change anything
-- c) SERIALIZABLE


-- ============================================================
-- 3.7 Task 6: Dirty Read Demonstration (READ UNCOMMITTED)
-- ============================================================
-- Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';

SELECT * FROM products WHERE shop = 'Joe''s Shop';

SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

-- Terminal 2:
BEGIN;
UPDATE products SET price = 99.99 WHERE product = 'Fanta';
ROLLBACK;


-- a) Terminal1 saw 99.99. Because Terminal 1 is reading data that was never committed and may be rolled back.
-- b) A dirty read happens when a transaction reads data that another transaction has modified but not yet committed.
-- c)gives incorrect values

-- ============================================================
-- 4. Independent Exercises 
-- ============================================================

-- Exercise 1: Transfer $200 from Bob to Wally if Bob has sufficient funds.


DROP FUNCTION IF EXISTS transfer_if_funds(numeric, text, text);
CREATE OR REPLACE FUNCTION transfer_if_funds(amount NUMERIC, from_name TEXT, to_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql AS $$
DECLARE
  from_balance NUMERIC;
BEGIN
  
  SELECT balance INTO from_balance FROM accounts WHERE name = from_name FOR UPDATE;

  IF from_balance IS NULL THEN
    RETURN format('Account %s not found', from_name);
  END IF;

  IF from_balance < amount THEN
    RETURN format('Insufficient funds in %s: balance=%.2f, required=%.2f', from_name, from_balance, amount);
  END IF;

  
  UPDATE accounts SET balance = balance - amount WHERE name = from_name;
  UPDATE accounts SET balance = balance + amount WHERE name = to_name;

  RETURN format('Transfer %.2f from %s to %s completed', amount, from_name, to_name);
END;
$$;


-- Exercise 2: Transaction with multiple savepoints

BEGIN;
INSERT INTO products (shop, product, price) VALUES ('DemoShop', 'Gadget1', 100.00);
SAVEPOINT sp1;
UPDATE products SET price = 120.00 WHERE shop='DemoShop' AND product='Gadget1';
SAVEPOINT sp2;
DELETE FROM products WHERE shop='DemoShop' AND product='Gadget1';

ROLLBACK TO sp1;
COMMIT;




-- Exercise 3: Simultaneous withdrawals demonstration (outline and SQL example)

DROP TABLE IF EXISTS withdrawals_log;
CREATE TABLE withdrawals_log (
  id SERIAL PRIMARY KEY,
  acc_id INT,
  amount NUMERIC,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


DROP FUNCTION IF EXISTS safe_withdraw(acc INT, amt NUMERIC);
CREATE OR REPLACE FUNCTION safe_withdraw(acc INT, amt NUMERIC)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
  bal NUMERIC;
BEGIN
  
  SELECT balance INTO bal FROM accounts WHERE id = acc FOR UPDATE;
  IF bal IS NULL THEN
    RETURN 'Account not found';
  END IF;
  IF bal < amt THEN
    RETURN format('Insufficient funds: balance=%.2f, requested=%.2f', bal, amt);
  END IF;
  UPDATE accounts SET balance = balance - amt WHERE id = acc;
  INSERT INTO withdrawals_log (acc_id, amount) VALUES (acc, amt);
  RETURN format('Withdrawn %.2f from account %s', amt, acc);
END;
$$;



-- Exercise 4: Sells relation and MAX < MIN problem demonstration

DROP TABLE IF EXISTS sells;
CREATE TABLE sells (
  shop VARCHAR(50),
  product VARCHAR(50),
  price DECIMAL(10,2)
);

INSERT INTO sells (shop, product, price) VALUES
('S1','A', 10.00),
('S1','B', 20.00);


-- ============================================================
-- 5. Self-Assessment Answers 
-- ============================================================

-- 1) ACID:
--    Atomicity
--    Consistency
--    Isolation
--    Durability

-- 2) Difference COMMIT vs ROLLBACK:
--    COMMIT saves the changes; ROLLBACK goes back.

-- 3) When to use SAVEPOINT:
--    When partial rollback is needed inside of a big  transaction

-- 4) Compare isolation levels:
--    READ UNCOMMITTED < READ COMMITTED < REPEATABLE READ < SERIALIZABLE


-- 5) Dirty read: A dirty read happens when a transaction reads data that another transaction has modified but not yet committed

-- 6) A non-repeatable read occurs when a transaction reads the same row twice and gets different results because another transaction modified or deleted that row in between.

-- 7) You run the same query twice in the same transaction and the second time, new rows appear or disappear even though you didn’t change anything.

-- 8) Why choose READ COMMITTED over SERIALIZABLE:
--    the best throughput, less conflicts, less serialization errors

-- 9) How transactions maintain consistency:
--    Locking, MVCC, ACID properties.

-- 10) What happens to uncommitted changes on crash:
--    they rollback; only COMMITTED changes survive.


