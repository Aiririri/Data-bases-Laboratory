
-- =====================================================================
-- Part 1: Ensure Database Setup (Lab 6 tables)
-- =====================================================================

-- Drop if they exist so script is idempotent for demo purposes
DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  emp_name VARCHAR(100),
  dept_id INT,
  salary NUMERIC(12,2)
);

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(100),
  location VARCHAR(100)
);

CREATE TABLE projects (
  project_id INT PRIMARY KEY,
  project_name VARCHAR(200),
  dept_id INT,
  budget NUMERIC(14,2),
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50)
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
INSERT INTO projects (project_id, project_name, dept_id, budget, status) VALUES
(1, 'Website Redesign', 101, 100000, 'Active'),
(2, 'Employee Training', 102, 50000, 'Active'),
(3, 'Budget Analysis', 103, 75000, 'Completed'),
(4, 'Cloud Migration', 101, 150000, 'Active'),
(5, 'AI Research', NULL, 200000, 'Planned');

-- assignments table 
DROP TABLE IF EXISTS assignments;
CREATE TABLE assignments (
  assignment_id SERIAL PRIMARY KEY,
  employee_id INT REFERENCES employees(emp_id) ON DELETE CASCADE,
  project_id INT REFERENCES projects(project_id) ON DELETE CASCADE,
  hours_worked NUMERIC(6,1),
  assignment_date DATE
);

-- sample assignments
INSERT INTO assignments (employee_id, project_id, hours_worked, assignment_date) VALUES
(1,1,120.5,'2024-01-15'),
(2,1,95.0,'2024-01-20'),
(1,4,80.0,'2024-02-01'),
(3,3,60.0,'2024-03-05'),
(5,2,110.0,'2024-02-20');

-- =====================================================================
-- Part 2: Creating Basic Views
-- =====================================================================

-- Exercise 2.1: Simple View Creation
-- View: employee_details (only employees assigned to a department)
DROP VIEW IF EXISTS employee_details;
CREATE VIEW employee_details AS
SELECT
  e.emp_id,
  e.emp_name,
  e.salary,
  d.dept_name,
  d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Test: SELECT * FROM employee_details;
-- Question: How many rows? Expected: employees with dept_id not NULL and matching departments (4 in sample).
-- Tom Brown does not appear because his dept_id IS NULL.

-- Exercise 2.2: View with Aggregation (dept_statistics)
DROP VIEW IF EXISTS dept_statistics;
CREATE VIEW dept_statistics AS
SELECT
  d.dept_id,
  d.dept_name,
  COALESCE(COUNT(e.emp_id),0) AS employee_count,
  ROUND(COALESCE(AVG(e.salary),0)::numeric,2) AS avg_salary,
  COALESCE(MAX(e.salary),0) AS max_salary,
  COALESCE(MIN(e.salary),0) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Exercise 2.3: View with Multiple Joins (project_overview)
DROP VIEW IF EXISTS project_overview;
CREATE VIEW project_overview AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  d.dept_name,
  d.location,
  COALESCE((SELECT COUNT(*) FROM employees e WHERE e.dept_id = d.dept_id),0) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;

-- Exercise 2.4: View with Filtering (high_earners)
DROP VIEW IF EXISTS high_earners;
CREATE VIEW high_earners AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;



-- Part 3: Modifying and Managing Views


-- Exercise 3.1: Replace employee_details to include salary grade
DROP VIEW IF EXISTS employee_details;
CREATE OR REPLACE VIEW employee_details AS
SELECT
  e.emp_id,
  e.emp_name,
  e.salary,
  d.dept_name,
  d.location,
  CASE
    WHEN e.salary > 60000 THEN 'High'
    WHEN e.salary > 50000 THEN 'Medium'
    ELSE 'Standard'
  END AS salary_grade
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 3.2: Rename high_earners -> top_performers
DROP VIEW IF EXISTS top_performers;
ALTER VIEW high_earners RENAME TO top_performers;

-- Verify: SELECT * FROM top_performers;

-- Exercise 3.3: Temporary view creation and drop (temp_view)
DROP VIEW IF EXISTS temp_view;
CREATE TEMP VIEW temp_view AS
SELECT emp_id, emp_name, salary FROM employees WHERE salary < 50000;

-- Drop it
DROP VIEW IF EXISTS temp_view;

-- Part 4: Updatable Views


-- Exercise 4.1: Create an updatable view employee_salaries
DROP VIEW IF EXISTS employee_salaries;
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary FROM employees;



-- Exercise 4.2: Update through view (example)
-- UPDATE employee_salaries SET salary = 52000 WHERE emp_name = 'John Smith';
-- Verify: SELECT * FROM employees WHERE emp_name = 'John Smith';

-- Exercise 4.3: Insert through view
-- INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary) VALUES (6, 'Alice Johnson', 102, 58000);

-- Exercise 4.4: View with CHECK OPTION (it_employees)
DROP VIEW IF EXISTS it_employees;
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary FROM employees WHERE dept_id = 101 WITH LOCAL CHECK OPTION;

-- Trying to insert or update a row via the view that violates the WHERE clause will fail.
-- Example (should fail):
-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary) VALUES (7, 'Bob Wilson', 103, 60000);
-- Expected error: ERROR:  new row for relation "employees" violates check option for view "it_employees"

-- Part 5: Materialized Views


-- Exercise 5.1: Create a materialized view dept_summary_mv
DROP MATERIALIZED VIEW IF EXISTS dept_summary_mv;
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
  d.dept_id,
  d.dept_name,
  COUNT(e.emp_id) AS total_employees,
  COALESCE(SUM(e.salary),0) AS total_salaries,
  COUNT(DISTINCT p.project_id) AS total_projects,
  COALESCE(SUM(p.budget),0) AS total_project_budget
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
LEFT JOIN projects p ON p.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;

-- Query: SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- Exercise 5.2: Refresh materialized view after data change
-- Example:
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES (8, 'Charlie Brown', 101, 54000);
-- SELECT * FROM dept_summary_mv; -- before refresh: won't include Charlie
-- REFRESH MATERIALIZED VIEW dept_summary_mv;
-- SELECT * FROM dept_summary_mv; -- after refresh: includes Charlie

-- Exercise 5.3: Concurrent refresh
-- Need unique index for CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS dept_summary_mv_dept_id_idx ON dept_summary_mv(dept_id);

-- REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
-- Advantage: CONCURRENTLY allows reads to continue while refresh runs (less locking), but requires unique index and cannot be used inside a transaction block.

-- Exercise 5.4: Materialized view WITH NO DATA
DROP MATERIALIZED VIEW IF EXISTS project_stats_mv;
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  d.dept_name,
  COALESCE((SELECT COUNT(*) FROM assignments a WHERE a.project_id = p.project_id),0) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WITH NO DATA;

-- Querying a MV created WITH NO DATA returns zero rows until refreshed.
-- SELECT * FROM project_stats_mv; -- returns no rows until REFRESH MATERIALIZED VIEW project_stats_mv;


-- Part 6: Database Roles


-- Exercise 6.1: Create Basic Roles
-- (Requires superuser to run role creation statements)
-- Note: If you are running this as non-superuser, these commands will fail.
-- Use caution on production DBs.


CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user LOGIN PASSWORD 'report456';


-- Exercise 6.2: Role with Specific Attributes

CREATE ROLE db_creator LOGIN PASSWORD 'creator789' CREATEDB;
CREATE ROLE user_manager LOGIN PASSWORD 'manager101' CREATEROLE;
CREATE ROLE admin_user LOGIN PASSWORD 'admin999' SUPERUSER;


-- Exercise 6.3: Grant Privileges to Roles 

GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;


-- Exercise 6.4: Group Roles and membership 

CREATE ROLE hr_team NOLOGIN;
CREATE ROLE finance_team NOLOGIN;
CREATE ROLE it_team NOLOGIN;
CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';
GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;
GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;


-- Exercise 6.5: Revoke Privileges

REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;


-- Exercise 6.6: Modify Role Attributes 

ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;


-- Part 7: Advanced Role Management 


-- Exercise 7.1: Role hierarchy (requires superuser)

CREATE ROLE read_only NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;
CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';
GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;


-- Exercise 7.2: Object ownership 

CREATE ROLE project_manager LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;


-- Exercise 7.3: Reassign and Drop Roles

CREATE ROLE temp_owner LOGIN PASSWORD 'temp123';
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;
REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;


-- Exercise 7.4: Row-level security with views (simple views created above)
-- Grant example (commented):
-- GRANT SELECT ON hr_employee_view TO hr_team;


-- Part 8: Practical Scenarios


-- Exercise 8.1: Department Dashboard View
DROP VIEW IF EXISTS dept_dashboard;
CREATE VIEW dept_dashboard AS
SELECT
  d.dept_id,
  d.dept_name,
  d.location,
  COALESCE(COUNT(e.emp_id),0) AS employee_count,
  ROUND(COALESCE(AVG(e.salary),0)::numeric,2) AS avg_salary,
  COALESCE(SUM(CASE WHEN p.status = 'Active' THEN 1 ELSE 0 END),0) AS active_projects,
  COALESCE(SUM(COALESCE(p.budget,0)),0) AS total_project_budget,
  CASE WHEN COUNT(e.emp_id) = 0 THEN 0 ELSE ROUND(COALESCE(SUM(p.budget),0)/COUNT(e.emp_id)::numeric,2) END AS budget_per_employee
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;



SELECT * FROM employee_details;
SELECT * FROM dept_statistics ORDER BY employee_count DESC;
SELECT * FROM project_overview;
SELECT * FROM top_performers;
SELECT * FROM employee_salaries;
SELECT * FROM it_employees;


