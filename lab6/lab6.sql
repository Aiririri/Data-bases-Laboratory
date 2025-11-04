
-- =========================
-- Part 1: Database Setup
-- =========================
DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  emp_name VARCHAR(50),
  dept_id INT,
  salary DECIMAL(10,2)
);

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50),
  location VARCHAR(50)
);

CREATE TABLE projects (
  project_id INT PRIMARY KEY,
  project_name VARCHAR(50),
  dept_id INT,
  budget DECIMAL(10,2)
);

-- Sample data: employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);

-- Sample data: departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');

-- Sample data: projects
INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

-- Helper: show counts
-- SELECT COUNT(*) FROM employees; SELECT COUNT(*) FROM departments; SELECT COUNT(*) FROM projects;


-- =========================
-- Part 2: CROSS JOIN Exercises
-- =========================

-- Exercise 2.1: Basic CROSS JOIN: all combinations of employees × departments
-- Result columns: emp_name, dept_name
SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;

-- Question: How many rows?  N × M
-- N = number of employees (5), M = number of departments (4) => 5 × 4 = 20 rows.

-- Exercise 2.2a: Comma notation (same CROSS JOIN)
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- Exercise 2.2b: INNER JOIN with TRUE condition (same result)
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

-- Exercise 2.3: Practical CROSS JOIN — all employees paired with all projects (availability matrix)
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;


-- =========================
-- Part 3: INNER JOIN Exercises
-- =========================

-- Exercise 3.1: Basic INNER JOIN with ON — employees with their department names (only those with dept)
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Question: How many rows? Rows for employees whose dept_id is NOT NULL and matches a department.
-- Here: emp_id 1 (101), 2 (102), 3 (101), 4 (103) => 4 rows. Tom Brown (emp_id 5) excluded because dept_id IS NULL.

-- Exercise 3.2: INNER JOIN with USING
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);

-- Difference vs ON: USING merges the common column (dept_id) once in output; ON keeps both if explicitly selected.

-- Exercise 3.3: NATURAL INNER JOIN
-- (works only if column names that should match are identical; here dept_id exists in both)
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- Exercise 3.4: Multi-table INNER JOIN: employee name, department name, project name
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id
ORDER BY e.emp_name;


-- =========================
-- Part 4: LEFT JOIN Exercises
-- =========================

-- Exercise 4.1: LEFT JOIN — all employees with department info (including employees without a department)
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
ORDER BY e.emp_id;

-- Question: How is Tom Brown represented? Tom Brown has dept_id NULL -> dept columns (dept_dept, dept_name) will be NULL.

-- Exercise 4.2: LEFT JOIN with USING
SELECT emp_name, dept_name
FROM employees
LEFT JOIN departments USING (dept_id)
ORDER BY emp_name;

-- Exercise 4.3: Find employees NOT assigned to any department
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- Exercise 4.4: LEFT JOIN with aggregation — all departments and count of employees (include 0)
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;


-- =========================
-- Part 5: RIGHT JOIN Exercises
-- =========================

-- Exercise 5.1: RIGHT JOIN — all departments with their employees (including departments without employees)
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_id, e.emp_name;

-- Exercise 5.2: Convert RIGHT JOIN to LEFT JOIN (reverse the table order)
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
ORDER BY d.dept_id, e.emp_name;

-- Exercise 5.3: Find departments without employees
SELECT d.dept_name, d.location
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;


-- =========================
-- Part 6: FULL JOIN Exercises
-- =========================

-- Exercise 6.1: Basic FULL JOIN — all employees and all departments, NULL where no match
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
ORDER BY COALESCE(d.dept_id, e.emp_id);

-- Question: Which records have NULL on left? (employees columns NULL) → rows for departments with no employees (e.g., dept_id 104).
-- Which records have NULL on right? → employees without departments (Tom Brown).

-- Exercise 6.2: FULL JOIN with projects — all departments and all projects
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_id NULLS LAST, p.project_id;

-- Exercise 6.3: Find orphaned records (employees without departments and departments without employees)
SELECT
  CASE
    WHEN e.emp_id IS NULL THEN 'Department without employees'
    WHEN d.dept_id IS NULL THEN 'Employee without department'
    ELSE 'Matched'
  END AS record_status,
  e.emp_name,
  d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL
ORDER BY record_status;


-- =========================
-- Part 7: ON vs WHERE Clause
-- =========================

-- Exercise 7.1: Filter in ON clause (LEFT JOIN)
-- Query 1: Filter in ON clause — keeps all employees, only matches departments in Building A
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.dept_id AND d.location = 'Building A'
ORDER BY e.emp_id;

-- Exercise 7.2: Filter in WHERE clause (LEFT JOIN)
-- Query 2: Filter in WHERE — this will return only rows where department.location = 'Building A' (filter after join)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A'
ORDER BY e.emp_id;

-- Explanation:
-- Query1: returns ALL employees; d.* is NULL unless department is in Building A.
-- Query2: filters AFTER join, so any row where d.location IS NULL (i.e., employee without dept) is removed — fewer rows.

-- Exercise 7.3: ON vs WHERE with INNER JOIN
-- For INNER JOIN, applying condition in ON or WHERE yields the same result (because INNER JOIN removes non-matching rows anyway).
-- Example (both equivalent):
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';


-- =========================
-- Part 8: Complex JOIN Scenarios
-- =========================

-- Exercise 8.1: Multiple joins (all departments, include employee & project info if any)
SELECT
  d.dept_name,
  e.emp_name,
  e.salary,
  p.project_name,
  p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

-- Exercise 8.2: Self Join (employee -> manager)
-- (We will add manager_id column and populate a little)
ALTER TABLE employees ADD COLUMN IF NOT EXISTS manager_id INT;

-- Sample manager assignments (make emp_id 3 the manager of 1 & 2 & 4 & 5)
UPDATE employees SET manager_id = 3 WHERE emp_id IN (1,2,4,5);
UPDATE employees SET manager_id = NULL WHERE emp_id = 3; -- manager has no manager

-- Self-join query
SELECT
  e.emp_name AS employee,
  m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;

-- Exercise 8.3: Join with Subquery — departments where avg salary > 50000
SELECT d.dept_name, ROUND(AVG(e.salary),2) AS avg_salary
FROM departments d
JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;




/*
1. What is the difference between INNER JOIN and LEFT JOIN?
   - INNER JOIN returns only rows that have matching keys in both tables.
   - LEFT JOIN returns all rows from the left table and matched rows from the right table (NULLs when no match).

2. When would you use CROSS JOIN in a practical scenario?
   - To generate all combinations (cartesian product). Useful for scheduling matrices, testing, generating permutations or default combinations (e.g., every employee × every project availability grid).

3. Explain why the position of a filter (ON vs WHERE) matters for outer joins but not for inner joins.
   - For OUTER JOINs, ON filters determine which rows match (applied during join), while WHERE filters are applied after join and can remove rows introduced by the outer side (thus can turn an outer join into a semi-inner behavior). For INNER JOINs both produce same effective result because non-matches are removed anyway.

4. What is the result of: SELECT COUNT(*) FROM table1 CROSS JOIN table2 if table1 has 5 rows and table2 has 10 rows?
   - 5 × 10 = 50 rows.

5. How does NATURAL JOIN determine which columns to join on?
   - NATURAL JOIN automatically uses all columns with the same names in both tables as join keys.

6. What are the potential risks of using NATURAL JOIN?
   - Unintended joins if tables have unexpected same-named columns; fragility when schema changes; ambiguity and reduced clarity.

7. Convert this LEFT JOIN to a RIGHT JOIN:
   - Original: SELECT * FROM A LEFT JOIN B ON A.id = B.id
   - Equivalent RIGHT JOIN: SELECT * FROM B RIGHT JOIN A ON A.id = B.id
     (or swap tables: SELECT * FROM B RIGHT JOIN A ON B.id = A.id)

8. When should you use FULL OUTER JOIN instead of other join types?
   - Use FULL OUTER JOIN when you need all rows from both tables and want to see unmatched rows from both sides (with NULLs), e.g., to find orphans on either side or produce a complete unioned view.
*/

-- =========================
-- Additional Challenges 
-- =========================

-- 1. Simulate FULL OUTER JOIN using UNION of LEFT and RIGHT (for systems without FULL JOIN)
-- LEFT part
SELECT d.*, e.emp_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
UNION
SELECT d.*, e.emp_name
FROM departments d
RIGHT JOIN employees e ON d.dept_id = e.dept_id;

-- 2. Employees who work in departments that have more than one project
SELECT DISTINCT e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN (
  SELECT dept_id FROM projects GROUP BY dept_id HAVING COUNT(*) > 1
) dp ON d.dept_id = dp.dept_id;

-- 3. Hierarchical query with self-joins (employee -> manager -> manager's manager)
SELECT e.emp_name AS employee,
       m.emp_name AS manager,
       mm.emp_name AS managers_manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
LEFT JOIN employees mm ON m.manager_id = mm.emp_id;

-- 4. All pairs of employees who work in the same department (exclude self-pairs)
SELECT a.emp_name AS emp_a, b.emp_name AS emp_b, a.dept_id
FROM employees a
JOIN employees b ON a.dept_id = b.dept_id AND a.emp_id < b.emp_id
WHERE a.dept_id IS NOT NULL
ORDER BY a.dept_id, a.emp_name, b.emp_name;

