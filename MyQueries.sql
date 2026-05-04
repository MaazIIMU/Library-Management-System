-- Project Name - Library Management System

-- Creating branch details table

Drop table if exists branch;
CREATE TABLE branch ( 
	branch_id varchar(10) PRIMARY KEY, 
	manager_id varchar(10),
	branch_address varchar(55),
	contact_no varchar(20)
	);

-- Creating employees detail table

Drop table if exists employees;
CREATE TABLE employees (
	emp_id varchar(10) PRIMARY key,
	emp_name varchar(25),
	position varchar(15),
	salary int,
	branch_id varchar(10) --fk
);

alter table employees
alter column salary type float;

-- Creating books details table

drop table if exists books;
CREATE TABLE books (
	isbn varchar(20) primary key,
	book_title varchar(60),
	category varchar(20),
	rental_price int,
	status	varchar(5),
	author varchar(30),
	publisher varchar(30)
)

Alter table books
alter column rental_price type float;

-- Creating members details table

drop table if exists members;
CREATE TABLE members (
	member_id varchar(5) primary key,
	member_name	varchar(20),
	member_address varchar(20),
	reg_date date
)

-- Creating table containing issued books data

drop table if exists issued_status;
CREATE TABLE issued_status (
	issued_id varchar(5) primary key,
	issued_member_id varchar(5), --fk
	issued_book_name varchar(75), 
	issued_date	date,
	issued_book_isbn varchar(30), --fk
	issued_emp_id varchar(5) --fk
);

-- Creating table containing returned books data

Drop TABLE if exists return_status;
CREATE TABLE return_status (
	return_id varchar(5) primary key,
	issued_id varchar(5), --fk
	return_book_name varchar(75), 
	return_date	date,
	return_book_isbn varchar(30) --fk
)

-- Adding foreign keys

ALTER TABLE issued_status
add constraint fk_member_id
FOREIGN key (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
add constraint fk_book_isbn
FOREIGN key (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
add constraint fk_emp_id
FOREIGN key (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees
add constraint fk_branch_id
FOREIGN key (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
add constraint fk_issue_id
FOREIGN key (issued_id)
REFERENCES issued_status(issued_id);

-- Project tasks

-- Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn,book_title,category,rental_price,status,author,publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
select * from books;

-- Update an Existing Member's Address

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C101';
select * from members;

-- Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS121';
SELECT * FROM issued_status;

-- Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT * FROM issued_status
SELECT
	issued_member_id,
	count (*)
FROM issued_status
group by 1
HAVING count(*) > 1;

-- CTAS
-- Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt

CREATE TABLE book_count
AS
SELECT 
	b.isbn,
	b.book_title,
	count(ist.issued_id) as no_of_issues
from books as b
JOIN
	issued_status as ist
ON ist.issued_book_isbn = b.isbn
group by 1,2;

SELECT * from book_count

-- Data Analysis & Findings

-- Retrieve All Books in a Specific Category

SELECT * FROM books
WHERE category = 'Classic';

-- Find Total Rental Income by Category

SELECT 
	b.category,
	sum(b.rental_price)
from books as b
JOIN
	issued_status as ist
ON ist.issued_book_isbn = b.isbn
group by 1;

-- List Members Who Registered in the Last 720 Days

select * from members
WHERE reg_date >= CURRENT_DATE - Interval '720 days';

-- List Employees with Their Branch Manager's Name and their branch details

SELECT 
	e1.emp_name,
	e1.position,
	e2.emp_name as manager_name
from employees as e1
JOIN branch as b
on b.branch_id = e1.branch_id
JOIN employees as e2
on b.manager_id = e2.emp_id
WHERE e1.emp_id != b.manager_id;

-- Create a Table of Books with Rental Price Above a Certain Threshold

CREATE TABLE expensive_books AS
SELECT * from books
where rental_price >7;

-- Retrieve the List of Books Not Yet Returned

SELECT ist.issued_book_name from issued_status as ist
LEFT JOIN return_status as rst
ON rst.issued_id = ist.issued_id
where rst.return_id is null;