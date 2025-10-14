

-- =========================
-- Part 1: CHECK Constraints
-- =========================

-- Task 1.1: Basic CHECK Constraint
DROP TABLE IF EXISTS employees_check;
CREATE TABLE employees_check (
    employee_id   INTEGER,
    first_name    TEXT,
    last_name     TEXT,
    age           INTEGER,
    salary        NUMERIC,
    CONSTRAINT chk_age_range CHECK (age BETWEEN 18 AND 65),
    CONSTRAINT chk_salary_positive CHECK (salary > 0)
);

-- Valid inserts (should succeed)
INSERT INTO employees_check (employee_id, first_name, last_name, age, salary) VALUES
(1, 'Alice', 'Brown', 30, 3500.00),
(2, 'Bob', 'Green', 45, 5500.50);


-- Task 1.2: Named CHECK Constraint
DROP TABLE IF EXISTS products_catalog;
CREATE TABLE products_catalog (
    product_id     INTEGER,
    product_name   TEXT,
    regular_price  NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Valid inserts
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(10, 'Gadget A', 100.00, 80.00),
(11, 'Widget B', 50.00, 30.00);


-- Task 1.3: Multiple Column CHECK (bookings)
DROP TABLE IF EXISTS bookings;
CREATE TABLE bookings (
    booking_id    INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests    INTEGER,
    CONSTRAINT chk_num_guests CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT chk_dates CHECK (check_out_date > check_in_date)
);

-- Valid inserts
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
(100, DATE '2024-10-01', DATE '2024-10-05', 2),
(101, DATE '2024-11-10', DATE '2024-11-12', 4);


-- Task 1.4: Testing CHECK Constraints
-- Above inserts include valid examples. The commented INSERTs are invalid and will raise errors:
-- - chk_age_range / chk_salary_positive for employees_check
-- - valid_discount for products_catalog
-- - chk_num_guests and chk_dates for bookings

-- =========================
-- Part 2: NOT NULL Constraints
-- =========================

-- Task 2.1: NOT NULL Implementation
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id       INTEGER NOT NULL,
    email             TEXT NOT NULL,
    phone             TEXT, -- nullable
    registration_date DATE NOT NULL
);

-- Valid insert
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES (1, 'a@example.com', '123-456', DATE '2024-01-01');


-- Task 2.2: Combining Constraints (inventory)
DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory (
    item_id      INTEGER NOT NULL,
    item_name    TEXT NOT NULL,
    quantity     INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price   NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Valid insert
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
(1, 'Screwdriver', 100, 5.50, NOW()),
(2, 'Hammer', 50, 12.00, NOW());


-- Task 2.3: Testing NOT NULL
-- Demonstrated above: valid inserts + commented invalid ones to test behavior.
-- Also nullable column example:
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES (4, 'nullable@example.com', NULL, DATE '2024-05-01');


-- =========================
-- Part 3: UNIQUE Constraints
-- =========================

-- Task 3.1: Single Column UNIQUE
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    user_id    INTEGER,
    username   TEXT UNIQUE,
    email      TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Valid inserts
INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'user1', 'u1@example.com', NOW()),
(2, 'user2', 'u2@example.com', NOW());


-- Task 3.2: Multi-Column UNIQUE (course_enrollments)
DROP TABLE IF EXISTS course_enrollments;
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id    INTEGER,
    course_code   TEXT,
    semester      TEXT,
    CONSTRAINT uniq_student_course_semester UNIQUE (student_id, course_code, semester)
);

-- Valid inserts
INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES
(1, 100, 'CS101', 'Fall2024'),
(2, 101, 'CS101', 'Fall2024');

-- Invalid insert (duplicate composite key) - will fail
-- INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES (3, 100, 'CS101', 'Fall2024');

-- Task 3.3: Named UNIQUE Constraints (modify users)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_key;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;

ALTER TABLE users
    ADD CONSTRAINT unique_username UNIQUE (username),
    ADD CONSTRAINT unique_email UNIQUE (email);

-- Test duplicates again (commented)
-- INSERT INTO users (user_id, username, email, created_at) VALUES (5, 'user2', 'u5@example.com', NOW()); -- duplicate username
-- INSERT INTO users (user_id, username, email, created_at) VALUES (6, 'user6', 'u2@example.com', NOW()); -- duplicate email


-- =========================
-- Part 4: PRIMARY KEY Constraints
-- =========================

-- Task 4.1: Single Column Primary Key (departments)
DROP TABLE IF EXISTS departments;
CREATE TABLE departments (
    dept_id   INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location  TEXT
);

-- Valid inserts
INSERT INTO departments (dept_id, dept_name, location) VALUES
(1, 'IT', 'HQ'),
(2, 'Sales', 'Branch A'),
(3, 'HR', 'HQ');



-- Task 4.2: Composite Primary Key (student_courses)
DROP TABLE IF EXISTS student_courses;
CREATE TABLE student_courses (
    student_id      INTEGER,
    course_id       INTEGER,
    enrollment_date DATE,
    grade           TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- Valid inserts
INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
(1000, 200, DATE '2024-09-01', 'A'),
(1001, 200, DATE '2024-09-01', 'B');

-- Invalid insert: duplicate composite PK (same student_id & course_id)
-- INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES (1000, 200, DATE '2024-09-02', 'A+');

-- Task 4.3: Comparison Exercise (as comments / explanation)
-- 1) Difference between UNIQUE and PRIMARY KEY:
--    - PRIMARY KEY: uniqueness + NOT NULL enforced; a table can have only one PRIMARY KEY.
--    - UNIQUE: enforces uniqueness but allows NULL (unless column is NOT NULL); a table can have multiple UNIQUE constraints.
-- 2) Single-column vs composite PRIMARY KEY:
--    - Single-column PK used when single attribute uniquely identifies a row.
--    - Composite PK used when combination of columns uniquely identifies a row.
-- 3) Why only one PRIMARY KEY but multiple UNIQUE:
--    - PRIMARY KEY defines the main unique identifier of the table and informs referential integrity. Multiple UNIQUEs are allowed because a table may have several alternate candidate keys.

-- =========================
-- Part 5: FOREIGN KEY Constraints
-- =========================

-- Task 5.1: Basic Foreign Key (employees_dept)
DROP TABLE IF EXISTS employees_dept;
CREATE TABLE employees_dept (
    emp_id   INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id  INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- Valid insert (dept 1 exists)
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES (10, 'Emp A', 1, DATE '2024-01-01');

-- Invalid insert: non-existent dept_id -> violates FK
-- INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES (11, 'Emp B', 999, DATE '2024-02-01');

-- Task 5.2: Multiple Foreign Keys (library schema)
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS publishers;

CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);

CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,
    title            TEXT NOT NULL,
    author_id        INTEGER REFERENCES authors(author_id),
    publisher_id     INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn             TEXT UNIQUE
);

-- Insert sample data
INSERT INTO authors (author_id, author_name, country) VALUES
(1, 'Author One', 'USA'),
(2, 'Author Two', 'UK');

INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
(1, 'Pub House', 'NYC'),
(2, 'Books Ltd', 'London');

INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
(100, 'Great Book', 1, 1, 2020, 'ISBN-0001'),
(101, 'Another Book', 2, 2, 2021, 'ISBN-0002');

-- Task 5.3: ON DELETE Options
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products_fk;
DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id    INTEGER PRIMARY KEY,
    order_id   INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity   INTEGER CHECK (quantity > 0)
);

-- Insert sample data for testing ON DELETE behavior
INSERT INTO categories (category_id, category_name) VALUES (1, 'Electronics'), (2, 'Books');
INSERT INTO products_fk (product_id, product_name, category_id) VALUES (1, 'Phone', 1), (2, 'Novel', 2);
INSERT INTO orders (order_id, order_date) VALUES (1000, DATE '2024-09-01');
INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES (5000, 1000, 1, 2);


-- =========================
-- Part 6: Practical Application (E-commerce design)
-- =========================

-- Task 6.1: E-commerce Database Design
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders_ecom;
DROP TABLE IF EXISTS products_ecom;
DROP TABLE IF EXISTS customers_ecom;

-- customers (customer_id, name, email, phone, registration_date)
CREATE TABLE customers_ecom (
    customer_id       SERIAL PRIMARY KEY,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE,
    phone             TEXT,
    registration_date DATE NOT NULL
);

-- products (product_id, name, description, price, stock_quantity)
CREATE TABLE products_ecom (
    product_id     SERIAL PRIMARY KEY,
    name           TEXT NOT NULL,
    description    TEXT,
    price          NUMERIC CHECK (price >= 0) NOT NULL,
    stock_quantity INTEGER CHECK (stock_quantity >= 0) NOT NULL
);

-- orders (order_id, customer_id, order_date, total_amount, status)
CREATE TYPE order_status_t AS ENUM ('pending','processing','shipped','delivered','cancelled');

CREATE TABLE orders_ecom (
    order_id     SERIAL PRIMARY KEY,
    customer_id  INTEGER REFERENCES customers_ecom(customer_id) ON DELETE SET NULL,
    order_date   DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status       order_status_t NOT NULL
);

-- order_details (order_detail_id, order_id, product_id, quantity, unit_price)
CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id        INTEGER REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id      INTEGER REFERENCES products_ecom(product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- Additional practical constraints: ensure total_amount equals sum of order_details (application-level or triggers; here we note it)
-- Insert sample data to demonstrate constraints

-- Customers
INSERT INTO customers_ecom (name, email, phone, registration_date) VALUES
('Customer A', 'custA@example.com', '111-1111', DATE '2024-01-01'),
('Customer B', 'custB@example.com', NULL, DATE '2024-02-15');

-- Products
INSERT INTO products_ecom (name, description, price, stock_quantity) VALUES
('Wireless Mouse', 'Ergonomic wireless mouse', 25.99, 50),
('USB Cable', '1m cable', 18.60, 100);

-- Orders and order_details
INSERT INTO orders_ecom (customer_id, order_date, total_amount, status) VALUES (1, DATE '2024-09-01', 51.98, 'pending');
-- Suppose order_id = 1
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (1, 1, 2, 25.99);

