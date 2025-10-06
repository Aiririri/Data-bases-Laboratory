
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  department,
  salary
FROM employees
ORDER BY employee_id;

-- Task 1.2: SELECT DISTINCT unique departments
-- ---------------------------------------------------------
-- Task 1.2
SELECT DISTINCT department
FROM employees
ORDER BY department;

-- Task 1.3: Projects with budget_category (CASE)
-- ---------------------------------------------------------
-- Task 1.3
SELECT
  project_id,
  project_name,
  budget,
  CASE
    WHEN budget > 150000 THEN 'Large'
    WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
    ELSE 'Small'
  END AS budget_category
FROM projects
ORDER BY budget DESC;

-- Task 1.4: Use COALESCE to display email (fallback text)
-- ---------------------------------------------------------
-- Task 1.4
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  COALESCE(email, 'No email provided') AS email_display
FROM employees
ORDER BY employee_id;



-- Part 2: WHERE Clause and Comparison Operators


-- Task 2.1: Employees hired after 2020-01-01
-- ---------------------------------------------------------
-- Task 2.1
SELECT employee_id, first_name || ' ' || last_name AS full_name, hire_date
FROM employees
WHERE hire_date > DATE '2020-01-01'
ORDER BY hire_date;

-- Task 2.2: Employees whose salary BETWEEN 60000 and 70000
-- ---------------------------------------------------------
-- Task 2.2
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary BETWEEN 60000 AND 70000
ORDER BY salary;

-- Task 2.3: Employees whose last name starts with 'S' or 'J'
-- ---------------------------------------------------------
-- Task 2.3
SELECT employee_id, first_name || ' ' || last_name AS full_name, last_name
FROM employees
WHERE last_name LIKE 'S%' OR last_name LIKE 'J%'
ORDER BY last_name;

-- Task 2.4: Employees who have a manager and work in IT
-- ---------------------------------------------------------
-- Task 2.4
SELECT employee_id, first_name || ' ' || last_name AS full_name, manager_id, department
FROM employees
WHERE manager_id IS NOT NULL AND department = 'IT'
ORDER BY employee_id;


-- =========================
-- Part 3: String and Mathematical Functions
-- =========================

-- Task 3.1:
-- Employee names in uppercase, length of last name, first 3 chars of email
-- ---------------------------------------------------------
-- Task 3.1
SELECT
  employee_id,
  UPPER(first_name || ' ' || last_name) AS full_name_upper,
  LENGTH(last_name) AS last_name_length,
  SUBSTRING(COALESCE(email, '') FROM 1 FOR 3) AS email_first3
FROM employees
ORDER BY employee_id;

-- Task 3.2:
-- Annual salary, monthly salary (rounded to 2 decimals), 10% raise amount
-- ---------------------------------------------------------
-- Task 3.2
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  salary AS monthly_salary_current,
  (salary * 12) AS annual_salary,
  ROUND((salary * 12) / 12.0, 2) AS monthly_salary_rounded,  -- same as salary, but formatted
  ROUND((salary * 12) * 0.10, 2) AS ten_percent_raise_annual
FROM employees
ORDER BY employee_id;

-- Task 3.3:
-- Use format() to create formatted string for projects
-- ---------------------------------------------------------
-- Task 3.3
SELECT
  project_id,
  format('Project: %s - Budget: $%s - Status: %s',
         project_name,
         to_char(budget, 'FM999,999,999.00'),
         COALESCE(status, 'N/A')) AS project_summary
FROM projects
ORDER BY project_id;

-- Task 3.4:
-- How many years each employee has been with company (integer years)
-- ---------------------------------------------------------
-- Task 3.4
SELECT
  employee_id,
  first_name || ' ' || last_name AS full_name,
  hire_date,
  date_part('year', age(CURRENT_DATE, hire_date))::INT AS years_with_company
FROM employees
ORDER BY years_with_company DESC, employee_id;



-- Part 4: Aggregate Functions and GROUP BY


-- Task 4.1: Average salary per department
-- ---------------------------------------------------------
-- Task 4.1
SELECT
  department,
  ROUND(AVG(salary)::numeric, 2) AS avg_salary,
  COUNT(*) AS employee_count
FROM employees
GROUP BY department
ORDER BY avg_salary DESC NULLS LAST;

-- Task 4.2: Total hours worked on each project (including project name)
-- ---------------------------------------------------------
-- Task 4.2
SELECT
  p.project_id,
  p.project_name,
  COALESCE(SUM(a.hours_worked), 0) AS total_hours_worked
FROM projects p
LEFT JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
ORDER BY total_hours_worked DESC;

-- Task 4.3: Count employees in each department; show only departments with > 1 employee (HAVING)
-- ---------------------------------------------------------
-- Task 4.3
SELECT
  department,
  COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1
ORDER BY employee_count DESC;

-- Task 4.4: Max and min salary and total payroll
-- ---------------------------------------------------------
-- Task 4.4
SELECT
  MAX(salary) AS max_salary,
  MIN(salary) AS min_salary,
  SUM(COALESCE(salary,0)) AS total_payroll
FROM employees;




-- Task 5.1: UNION of (salary > 65000) and (hired after 2020-01-01)
-- Both queries must have same columns: employee_id, full_name, salary
-- ---------------------------------------------------------
-- Task 5.1
(
  SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
  FROM employees
  WHERE salary > 65000
)
UNION
(
  SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
  FROM employees
  WHERE hire_date > DATE '2020-01-01'
)
ORDER BY salary DESC NULLS LAST;

-- Task 5.2: INTERSECT: employees who work in IT AND have salary > 65000
-- ---------------------------------------------------------
-- Task 5.2
(
  SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
  FROM employees
  WHERE department = 'IT'
)
INTERSECT
(
  SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
  FROM employees
  WHERE salary > 65000
);

-- Task 5.3: EXCEPT: employees NOT assigned to any projects
-- We'll select same columns from employees and subtract those who appear in assignments
-- ---------------------------------------------------------
-- Task 5.3
(
  SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
  FROM employees
)
EXCEPT
(
  SELECT e.employee_id, e.first_name || ' ' || e.last_name AS full_name, e.salary
  FROM employees e
  JOIN assignments a ON e.employee_id = a.employee_id
)
ORDER BY employee_id;




-- Task 6.1: Use EXISTS to find employees who have at least one assignment
-- ---------------------------------------------------------
-- Task 6.1
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS full_name
FROM employees e
WHERE EXISTS (
  SELECT 1 FROM assignments a WHERE a.employee_id = e.employee_id
)
ORDER BY e.employee_id;

-- Task 6.2: Use IN with subquery to find employees working on projects with status 'Active'
-- ---------------------------------------------------------
-- Task 6.2
SELECT DISTINCT e.employee_id, e.first_name || ' ' || e.last_name AS full_name, p.status
FROM employees e
WHERE e.employee_id IN (
  SELECT a.employee_id
  FROM assignments a
  JOIN projects p ON a.project_id = p.project_id
  WHERE p.status = 'Active'
)
ORDER BY e.employee_id;

-- Task 6.3: Use ANY to find employees whose salary is greater than ANY employee in Sales
-- (i.e., salary > min salary in Sales)
-- ---------------------------------------------------------
-- Task 6.3
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > ANY (SELECT salary FROM employees WHERE department = 'Sales')
ORDER BY salary DESC;




-- Task 7.1:
-- For each employee: name, department, average hours across their assignments,
-- and rank within department by salary (use RANK() window function)
-- ---------------------------------------------------------
-- Task 7.1
SELECT
  e.employee_id,
  e.first_name || ' ' || e.last_name AS full_name,
  e.department,
  ROUND(COALESCE(AVG(a.hours_worked) OVER (PARTITION BY e.employee_id), 0)::numeric, 2) AS avg_hours_worked,
  RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC NULLS LAST) AS salary_rank_in_department
FROM employees e
LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary
ORDER BY e.department NULLS LAST, salary_rank_in_department;

-- Task 7.2: Projects where total hours > 150; show project name, total hours, number of employees assigned
-- ---------------------------------------------------------
-- Task 7.2
SELECT
  p.project_id,
  p.project_name,
  SUM(a.hours_worked) AS total_hours,
  COUNT(DISTINCT a.employee_id) AS num_employees_assigned
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150
ORDER BY total_hours DESC;

-- Task 7.3: Departments report:
-- total employees, avg salary, highest paid employee name
-- Use GREATEST and LEAST somewhere (compare avg and highest for demonstration)
-- ---------------------------------------------------------
-- Task 7.3
WITH dept_stats AS (
  SELECT
    department AS dept_name,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary)::numeric, 2) AS avg_salary,
    MAX(salary) AS highest_salary
  FROM employees
  GROUP BY department
)
SELECT
  ds.dept_name,
  ds.total_employees,
  ds.avg_salary,
  ds.highest_salary,
  -- Find one (any) employee name who has the highest salary in the department
  (SELECT e.first_name || ' ' || e.last_name
   FROM employees e
   WHERE e.department = ds.dept_name AND e.salary = ds.highest_salary
   LIMIT 1) AS highest_paid_employee,
  -- Demonstrate GREATEST and LEAST: compare avg and highest salary
  GREATEST(ds.avg_salary, ds.highest_salary) AS greatest_of_avg_and_highest,
  LEAST(ds.avg_salary, ds.highest_salary) AS least_of_avg_and_highest
FROM dept_stats ds
ORDER BY ds.total_employees DESC NULLS LAST;




