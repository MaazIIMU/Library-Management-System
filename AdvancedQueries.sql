-- Advanced SQL problems

/*
Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/

SELECT 
	m.member_id,
	m.member_name,
	b.book_title,
	ist.issued_date,
	current_date - ist.issued_date as overdue_days
from issued_status as ist
JOIN 
	books as b
	ON b.isbn = ist.issued_book_isbn
JOIN 
	members as m
	ON m.member_id = ist.issued_member_id
LEFT JOIN 
	return_status as rst
	ON rst.issued_id = ist.issued_id
WHERE 
	rst.return_date is NULL
	and
	(current_date - ist.issued_date) > 30
order by 1;

/*
Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

CREATE OR REPLACE PROCEDURE add_return_records(p_issue_id varchar(5), p_return_id varchar(5), p_quality varchar(50))
LANGUAGE plpgsql
AS $$

DECLARE
	v_isbn varchar(30),
	v_book varchar(75)

BEGIN
	-- insert the book quality into return table
	insert into return_status(return_id, issued_id, return_date, book_quality)
	values (p_return_id, p_issue_id, current_date, p_quality);

	SELECT 
		issued_book_isbn,
		issued_book_name
	INTO
		v_isbn,
		v_book
	FROM issued_status
	WHERE issued_id = p_issue_id;

	update books
	set status = 'Yes'
	WHERE isbn = v_isbn;

	raise notice 'Thank you for returning book: %',v_book;

END;
$$

/*
Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, 
the number of books returned, and the total revenue generated from book rentals.
*/

DROP TABLE if exists branch_reports;
CREATE TABLE branch_reports
AS
select 
	b.branch_id,
	count (ist.issued_book_isbn) as books_issued,
	count (rst.return_id) as books_returned,
	sum(bk.rental_price) as total_income
from branch as b
JOIN 
employees as e
on e.branch_id = b.branch_id
JOIN 
issued_status as ist
ON ist.issued_emp_id = e.emp_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rst
ON rst.issued_id = ist.issued_id
group by 1;

SELECT * from branch_reports;

-- CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL '2 month'
                    );

SELECT * FROM active_members;

-- Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

select 
	e.emp_name,
	b.*,
	count(ist.issued_id) as book_issued
from employees as e
left JOIN
issued_status as ist
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON b.branch_id = e.branch_id
GROUP by 1,2
ORDER by 6 DESC;

-- Stored Procedure Objective: 
-- Create a stored procedure to manage the status of books in a library system. 
-- Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
-- The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
-- The procedure should first check if the book is available (status = 'yes'). 
-- If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
-- If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_status VARCHAR(10);

BEGIN
    SELECT 
        status 
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;


    ELSE
        RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
    END IF;
END;
$$

-- Create Table As Select (CTAS) Objective: 
-- Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
-- Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
-- The table should include: The number of overdue books. 
-- The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. 
-- The resulting table should show: Member ID Number of overdue books Total fines

SELECT 
	m.member_name,
	count (ist.issued_id) as books_overdue,
	sum(CURRENT_DATE - ist.issued_date) as total_days_overdue,
	sum(CURRENT_DATE - ist.issued_date) * 0.5 as fines
from issued_status as ist
LEFT JOIN 
return_status as rst
ON rst.issued_id = ist.issued_id
JOIN
members	as m
ON m.member_id = ist.issued_member_id
WHERE rst.return_id is Null
group by 1;