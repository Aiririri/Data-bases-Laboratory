
-- Part A: Database and Table Setup


-- Create database (drop if exists so script is idempotent)
DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab WITH TEMPLATE template0 ENCODING 'UTF8';

-- Connect to the database (psql metacommand)
\connect advanced_lab;

-- Create tables
-- employees: emp_id serial primary key, first_name, last_name, department, salary, hire_date, status default 'Active'
DROP TABLE IF EXISTS employees CASCADE;
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

-- departments: dept_id serial pk, dept_name, budget, manager_id (refers to employees.emp_id but optional)
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    budget INTEGER,
    manager_id INTEGER  -- optional FK could be added after employees exist
);

-- projects: project_id serial pk, project_name, dept_id, start_date, end_date, budget
DROP TABLE IF EXISTS projects CASCADE;
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(200) NOT NULL,
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

-- Add FK constraints where appropriate (deferred to allow easier population)
ALTER TABLE departments
    ADD CONSTRAINT fk_departments_manager FOREIGN KEY (manager_id) REFERENCES employees(emp_id) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE projects
    ADD CONSTRAINT fk_projects_department FOREIGN KEY (dept_id) REFERENCES departments(dept_id) DEFERRABLE INITIALLY DEFERRED;




-- 2. INSERT with column specification (only certain columns)

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1001, 'Alice', 'Ivanova', 'IT');

-- 3. INSERT with DEFAULT values (salary uses DEFAULT (NULL) and status uses default 'Active')
INSERT INTO employees (first_name, last_name, hire_date)
VALUES ('Bob', 'Petrov', CURRENT_DATE);

-- 4. INSERT multiple rows in single statement (3 departments)
INSERT INTO departments (dept_name, budget, manager_id) VALUES
('IT', 150000, NULL),
('Sales', 120000, NULL),
('HR', 80000, NULL);

-- 5. INSERT with expressions (hire_date = current_date, salary = 50000 * 1.1)
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Carol', 'Sidorova', 'Finance', CURRENT_DATE, (50000 * 1.1)::INTEGER);

-- 6. INSERT from SELECT (subquery) into temporary table 'temp_employees' — employees in IT
DROP TABLE IF EXISTS temp_employees;
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';
-- temp_employees now holds rows copied from employees where department = 'IT'



-- Insert some sample employees for update examples
INSERT INTO employees (first_name, last_name, department, salary, hire_date) VALUES
('Diana','Kovalenko','Sales',55000,'2019-06-15'),
('Egor','Smirnov','IT',75000,'2018-03-20'),
('Fedor','Orlov',NULL,38000,'2024-02-01'),
('Gulnara','Bek','HR',45000,'2021-11-05'),
('Ilya','Novikov','Sales',62000,'2015-01-10');

-- 7. UPDATE with arithmetic expressions: Increase all salaries by 10%
UPDATE employees
SET salary = CASE WHEN salary IS NOT NULL THEN (salary * 1.10)::INTEGER ELSE NULL END;

-- 8. UPDATE with WHERE clause and multiple conditions
-- Update status to 'Senior' where salary > 60000 AND hire_date < '2020-01-01'
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression for department reassignment based on salary
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 10. UPDATE with DEFAULT: set department to DEFAULT (NULL) where status = 'Inactive'
-- Note: department has no explicit DEFAULT; DEFAULT is NULL here.
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with subquery: update department budgets to be 20% higher than the average salary of employees in that department
-- Note: departments.budget will be updated using aggregated avg salary per department name
-- This assumes departments.dept_name matches employees.department values.
UPDATE departments d
SET budget = (SELECT CEIL(AVG(e.salary) * 1.20)::INTEGER FROM employees e WHERE e.department = d.dept_name)
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department = d.dept_name);

-- 12. UPDATE multiple columns in single statement
UPDATE employees
SET salary = (CASE WHEN salary IS NOT NULL THEN (salary * 1.15)::INTEGER ELSE NULL END),
    status = 'Promoted'
WHERE department = 'Sales';


-- 13. DELETE with simple WHERE condition: delete employees where status = 'Terminated'
DELETE FROM employees WHERE status = 'Terminated';

-- 14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

-- 15. DELETE with subquery: delete departments where dept_id NOT IN (SELECT DISTINCT department FROM employees)
-- Note: employees.department stores names in this schema, so adjust: delete departments that have no matching dept_name in employees.department
DELETE FROM departments d
WHERE d.dept_name NOT IN (SELECT DISTINCT department FROM employees WHERE department IS NOT NULL);

-- 16. DELETE with RETURNING clause: delete all projects where end_date < '2023-01-01' and return deleted data
-- Insert sample projects for demo
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
('OldProject',1,'2020-01-01','2022-12-31',30000),
('ActiveProject',2,'2024-01-01','2024-12-31',60000);

-- Delete and return deleted rows
DELETE FROM projects WHERE end_date < '2023-01-01' RETURNING *;

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, salary, department) VALUES ('Null','Person', NULL, NULL);

-- 18. UPDATE NULL handling: set department = 'Unassigned' where department IS NULL
UPDATE employees SET department = 'Unassigned' WHERE department IS NULL;

-- 19. DELETE with NULL conditions: delete employees where salary IS NULL OR department IS NULL
DELETE FROM employees WHERE salary IS NULL OR department IS NULL;



-- 20. INSERT with RETURNING: insert new employee and return auto-generated emp_id and full name
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Irina','Zaitseva','IT',70000,CURRENT_DATE)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING: update salary for employees in 'IT' department (increase by 5000) and return emp_id, old salary, new salary
-- To capture old salary, we use a CTE
WITH updated AS (
    SELECT emp_id, salary AS old_salary FROM employees WHERE department = 'IT'
)
UPDATE employees e
SET salary = salary + 5000
FROM updated u
WHERE e.emp_id = u.emp_id
RETURNING e.emp_id, u.old_salary, e.salary AS new_salary;

-- 22. DELETE with RETURNING all columns: delete employees where hire_date < '2020-01-01' and return all columns
DELETE FROM employees WHERE hire_date < '2020-01-01' RETURNING *;




-- 23. Conditional INSERT: insert employee only if no employee with same first and last name exists
INSERT INTO employees (first_name, last_name, department, salary)
SELECT 'Jack','Black','Marketing',48000
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Jack' AND last_name = 'Black'
);

-- 24. UPDATE with JOIN logic using subqueries: update salaries based on department budget
-- If department budget > 100000 increase salary by 10% else by 5%
UPDATE employees e
SET salary = CASE
    WHEN d.budget > 100000 THEN (e.salary * 1.10)::INTEGER
    ELSE (e.salary * 1.05)::INTEGER
END
FROM departments d
WHERE e.department = d.dept_name;

-- 25. Bulk operations: insert 5 employees in single statement, then update their salaries by 10% in single UPDATE
INSERT INTO employees (first_name, last_name, department, salary, hire_date) VALUES
('Lena','K','IT',52000,'2024-03-01'),
('Maks','B','Sales',47000,'2024-03-01'),
('Nora','C','HR',43000,'2024-03-01'),
('Oleg','D','IT',51000,'2024-03-01'),
('Pavel','E','Sales',49000,'2024-03-01');

-- Increase salaries for these five (identified by hire_date in this example)
UPDATE employees SET salary = (salary * 1.10)::INTEGER WHERE hire_date = '2024-03-01';

-- 26. Data migration simulation: create employee_archive, move Inactive employees there then delete them from original
DROP TABLE IF EXISTS employee_archive;
CREATE TABLE employee_archive AS TABLE employees WITH NO DATA; -- same structure

-- Move rows where status = 'Inactive' into archive, then delete them
INSERT INTO employee_archive SELECT * FROM employees WHERE status = 'Inactive';
DELETE FROM employees WHERE status = 'Inactive';

-- 27. Complex business logic:
-- Update project end_date to be 30 days later for projects where budget > 50000 AND associated department has more than 3 employees.
-- First, ensure departments have employee counts by name matching
-- We assume projects.dept_id references departments.dept_id
UPDATE projects p
SET end_date = p.end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND EXISTS (
        SELECT 1 FROM departments d
        WHERE d.dept_id = p.dept_id
          AND (SELECT COUNT(*) FROM employees e WHERE e.department = d.dept_name) > 3
  );


-- Submission helper queries (simple checks)

-- Show counts for quick verification
SELECT 'employees_count' AS check, COUNT(*) FROM employees;
SELECT 'departments_count' AS check, COUNT(*) FROM departments;
SELECT 'projects_count' AS check, COUNT(*) FROM projects;
SELECT 'employee_archive_count' AS check, COUNT(*) FROM employee_archive;


