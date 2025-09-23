
-- Task 1.1
DROP DATABASE IF EXISTS university_main;
CREATE DATABASE university_main
    WITH OWNER = CURRENT_USER
    TEMPLATE template0
    ENCODING 'UTF8';

DROP DATABASE IF EXISTS university_archive;
CREATE DATABASE university_archive
    WITH CONNECTION LIMIT = 50
    TEMPLATE template0;


CREATE DATABASE university_test
    WITH IS_TEMPLATE = true
    CONNECTION LIMIT = 10;

-- Task 1.2

DROP DATABASE IF EXISTS university_distributed;
CREATE DATABASE university_distributed
    WITH ENCODING 'LATIN9'
    LC_COLLATE='C'
    LC_CTYPE='C'
    TEMPLATE template0;



-- Task 2.1
DROP TABLE IF EXISTS students CASCADE;
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone CHAR(15),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa NUMERIC(4,2),
    is_active BOOLEAN,
    graduation_year SMALLINT
);

DROP TABLE IF EXISTS professors CASCADE;
CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    office_number VARCHAR(20),
    hire_date DATE,
    salary NUMERIC(12,2),
    is_tenured BOOLEAN,
    years_experience INTEGER
);

DROP TABLE IF EXISTS courses CASCADE;
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8),
    course_title VARCHAR(100),
    description TEXT,
    credits SMALLINT,
    max_enrollment INTEGER,
    course_fee NUMERIC(10,2),
    is_online BOOLEAN,
    created_at TIMESTAMP WITHOUT TIME ZONE
);

-- Task 2.2
DROP TABLE IF EXISTS class_schedule CASCADE;
CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    course_id INTEGER,
    professor_id INTEGER,
    classroom VARCHAR(20),
    class_date DATE,
    start_time TIME WITHOUT TIME ZONE,
    end_time TIME WITHOUT TIME ZONE,
    duration INTERVAL
);

DROP TABLE IF EXISTS student_records CASCADE;
CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    course_id INTEGER,
    semester VARCHAR(20),
    year INTEGER,
    grade CHAR(2),
    attendance_percentage NUMERIC(4,1),
    submission_timestamp TIMESTAMP WITH TIME ZONE,
    last_updated TIMESTAMP WITH TIME ZONE
);

-- Task 3.1
ALTER TABLE students
    ADD COLUMN IF NOT EXISTS middle_name VARCHAR(30),
    ADD COLUMN IF NOT EXISTS student_status VARCHAR(20) DEFAULT 'ACTIVE';

ALTER TABLE students
    ALTER COLUMN phone TYPE VARCHAR(20),
    ALTER COLUMN gpa SET DEFAULT 0.00;

-- Task 3.1
ALTER TABLE professors
    ADD COLUMN IF NOT EXISTS department_code CHAR(5),
    ADD COLUMN IF NOT EXISTS research_area TEXT,
    ADD COLUMN IF NOT EXISTS last_promotion_date DATE;

ALTER TABLE professors
    ALTER COLUMN years_experience TYPE SMALLINT,
    ALTER COLUMN is_tenured SET DEFAULT FALSE;

-- Task 3.1
ALTER TABLE courses
    ADD COLUMN IF NOT EXISTS prerequisite_course_id INTEGER,
    ADD COLUMN IF NOT EXISTS difficulty_level SMALLINT,
    ADD COLUMN IF NOT EXISTS lab_required BOOLEAN DEFAULT FALSE;

ALTER TABLE courses
    ALTER COLUMN course_code TYPE VARCHAR(10),
    ALTER COLUMN credits SET DEFAULT 3;

-- Task 3.2
ALTER TABLE class_schedule
    ADD COLUMN IF NOT EXISTS room_capacity INTEGER,
    ADD COLUMN IF NOT EXISTS session_type VARCHAR(15),
    ADD COLUMN IF NOT EXISTS equipment_needed TEXT;

ALTER TABLE class_schedule
    DROP COLUMN IF EXISTS duration,
    ALTER COLUMN classroom TYPE VARCHAR(30);

-- Task 3.2
ALTER TABLE student_records
    ADD COLUMN IF NOT EXISTS extra_credit_points NUMERIC(4,1) DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS final_exam_date DATE;

ALTER TABLE student_records
    ALTER COLUMN grade TYPE VARCHAR(5);

ALTER TABLE student_records
    DROP COLUMN IF EXISTS last_updated;


-- Task 4.1
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100),
    department_code CHAR(5),
    building VARCHAR(50),
    phone VARCHAR(15),
    budget NUMERIC(15,2),
    established_year INTEGER
);

DROP TABLE IF EXISTS library_books CASCADE;
CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13),
    title VARCHAR(200),
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price NUMERIC(10,2),
    is_available BOOLEAN,
    acquisition_timestamp TIMESTAMP WITHOUT TIME ZONE
);

DROP TABLE IF EXISTS student_book_loans CASCADE;
CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    book_id INTEGER,
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    fine_amount NUMERIC(8,2),
    loan_status VARCHAR(20)
);

-- Task 4.2
ALTER TABLE professors ADD COLUMN IF NOT EXISTS department_id INTEGER;
ALTER TABLE students ADD COLUMN IF NOT EXISTS advisor_id INTEGER;
ALTER TABLE courses ADD COLUMN IF NOT EXISTS department_id INTEGER;


DROP TABLE IF EXISTS grade_scale CASCADE;
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points NUMERIC(3,2)
);

DROP TABLE IF EXISTS semester_calendar CASCADE;
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN
);


-- Task 5.1
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage NUMERIC(4,1),
    max_percentage NUMERIC(4,1),
    gpa_points NUMERIC(3,2),
    description TEXT
);


DROP TABLE IF EXISTS semester_calendar CASCADE;
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN
);

-- Task 5.2
DROP DATABASE IF EXISTS university_distributed;
DROP DATABASE IF EXISTS university_backup;

CREATE DATABASE university_backup
    WITH TEMPLATE university_main;
