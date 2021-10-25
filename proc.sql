CREATE OR REPLACE FUNCTION removed_department_guard
(IN department_id INT, OUT resigned BOOLEAN)
RETURNS BOOLEAN AS $$
    SELECT CASE WHEN D.removal_date IS NULL THEN false ELSE true END AS resigned FROM Departments AS D WHERE D.id = department_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION resigned_employee_guard
(IN employee_id INT, OUT resigned BOOLEAN)
RETURNS BOOLEAN AS $$
    SELECT CASE WHEN E.resignation_date IS NULL THEN false ELSE true END AS resigned FROM Employees AS E WHERE E.id = employee_id;
$$ LANGUAGE sql;

CREATE OR REPLACE PROCEDURE add_department 
(id INT, name VARCHAR(255)) 
AS $$
    INSERT INTO Departments VALUES (id, name);
$$ LANGUAGE sql;

CREATE OR REPLACE PROCEDURE remove_department
(department_id INT, date DATE)
AS $$
DECLARE
BEGIN
    IF ((SELECT COUNT(*) FROM Departments WHERE Departments.id = department_id) <> 1) THEN
        RAISE EXCEPTION 'Department not found';
    END IF;
    UPDATE Departments SET removal_date = date WHERE Departments.id = department_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_room
(floor INT, room INT, name VARCHAR(255), capacity INT, manager_id INT, effective_date DATE)
AS $$
DECLARE
    manager_department_id INT;
BEGIN
    IF (SELECT * FROM resigned_employee_guard(manager_id)) THEN
        RAISE EXCEPTION 'Manager has resigned' USING HINT = 'Manager has resigned and can no longer add rooms';
    END IF;
    SELECT E.department_id INTO manager_department_id FROM Employees AS E WHERE E.id = manager_id;
    INSERT INTO MeetingRooms VALUES (floor, room, name, manager_department_id);
    INSERT INTO Updates VALUES (manager_id, floor, room, effective_date, capacity);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE change_capacity
(floor INT, room INT, capacity INT, manager_id INT, date DATE)
AS $$
DECLARE
    manager_department_id INT;
BEGIN
    SELECT E.department_id INTO manager_department_id FROM Employees AS E WHERE E.id = manager_id;
    IF ((SELECT R.department_id FROM MeetingRooms AS R WHERE R.floor = change_capacity.floor AND R.room = change_capacity.room) <> manager_department_id) THEN
        RAISE EXCEPTION 'Manager department and room department mismatch' USING HINT = 'Manager and room should belong to the same department';
    END IF;
    IF ((SELECT COUNT(*) FROM updates AS U WHERE U.floor = change_capacity.floor AND U.room = change_capacity.room AND U.date = change_capacity.date) = 1) THEN
        UPDATE Updates AS U SET manager_id = change_capacity.manager_id, capacity = change_capacity.capacity WHERE U.floor = change_capacity.floor AND U.room = change_capacity.room AND U.date = change_capacity.date;
    ELSE
        INSERT INTO Updates VALUES (manager_id, floor, room, date, capacity);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_email
(IN name VARCHAR(255), OUT employee_email VARCHAR(255))
RETURNS VARCHAR(255) AS $$
DECLARE
    username VARCHAR;
    conflict VARCHAR;
    counter INT := NULL;
BEGIN
    SELECT LOWER(REGEXP_REPLACE(TRIM(name), '\s*|_', '', 'g')) INTO username;
    SELECT MAX(E.email) INTO conflict FROM Employees AS E WHERE E.email SIMILAR TO username || '(_[0-9]*)?' || '@company.com';
    IF (conflict IS NULL) THEN
        employee_email := username || '@company.com';
        RETURN;
    END IF;
    SELECT (regexp_matches(conflict, '_([0-9]*)@'))[1] INTO conflict;
    IF (conflict IS NULL) THEN
        employee_email := username || '_1' || '@company.com';
        RETURN;
    END IF;
    SELECT CAST(conflict AS INT) INTO counter;
    counter := counter + 1;
    employee_email := username || COALESCE(CAST(counter AS VARCHAR(255)),'') || '@company.com'
    RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_employee
(IN name VARCHAR(255), IN contact_number VARCHAR(20), IN type VARCHAR(7), IN department_id INT, OUT employee_id INT, OUT employee_email VARCHAR(255))
RETURNS RECORD AS $$
BEGIN
    If (SELECT * FROM removed_department_guard(department_id)) THEN
        RAISE EXCEPTION 'Department has been removed' USING HINT = 'Department has been removed and no new employees can be assigned to it';
    END IF;
    name := TRIM(name);
    SELECT generate_email(name) INTO employee_email;
    INSERT INTO Employees (name, contact_number, email, department_id) VALUES (name, contact_number, employee_email, department_id) RETURNING Employees.id INTO employee_id;
    IF (LOWER(type) = 'junior') THEN 
        INSERT INTO Juniors VALUES (employee_id);
    ELSIF (LOWER(type) = 'senior') THEN 
        INSERT INTO Superiors VALUES (employee_id);
        INSERT INTO Seniors VALUES (employee_id);
    ELSIF (LOWER(type) = 'manager') THEN
        INSERT INTO Superiors VALUES (employee_id);
        INSERT INTO Managers VALUES (employee_id);
    ELSE
        RAISE EXCEPTION 'Invalid employee type' USING HINT = 'Accepted employee types: Junior | Senior | Manager';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE remove_employee
(employee_id INT, date Date)
AS $$
BEGIN
    IF ((SELECT COUNT(*) FROM Employees AS E WHERE E.id = remove_employee.employee_id) <> 1) THEN
        RAISE EXCEPTION 'Employee not found';
    END IF;
    UPDATE Employees SET resignation_date = date WHERE id = employee_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION non_compliance
(IN start_date DATE, IN end_date DATE, OUT employee_id INT, OUT number_of_days INT)
RETURNS SETOF RECORD AS $$
WITH CTE AS (
    SELECT H.id AS id, COUNT(*) AS days_declared
    FROM HealthDeclarations AS H
    WHERE H.date BETWEEN start_date AND end_date 
    GROUP BY H.id
) SELECT E.id, COALESCE(
        (CASE WHEN E.resignation_date < end_date THEN resignation_date ELSE end_date END) - start_date - C.days_declared + 1,
        (CASE WHEN E.resignation_date < end_date THEN resignation_date ELSE end_date END) - start_date + 1
    )
FROM Employees AS E LEFT JOIN CTE AS C ON E.id = C.id
WHERE (E.resignation_date IS NULL OR E.resignation_date >= start_date)
    AND (C.days_declared IS NULL OR C.days_declared < end_date - start_date + 1);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION view_booking_report
(IN start_date DATE, IN employee_id INT, OUT floor_number INT, OUT room_number INT, OUT date DATE, OUT start_hour INT, OUT is_approved BOOLEAN)
RETURNS SETOF RECORD AS $$
    SELECT floor AS floor_number, room AS room_number, date, start_hour, CASE WHEN approver_id IS NULL THEN FALSE ELSE TRUE END AS is_approved 
    FROM Bookings 
    WHERE date = start_date AND creator_id = employee_id;
$$ LANGUAGE sql;

CREATE OR REPLACE VIEW RoomCapacity AS 
SELECT floor, room, date, capacity
FROM Updates NATURAL JOIN (SELECT floor, room, MAX(date) AS date FROM Updates GROUP BY (floor, room)) AS LatestUpdate;

CREATE OR REPLACE FUNCTION search_room
(IN search_capacity INT, IN search_date DATE, IN search_start_hour INT, IN search_end_hour INT, OUT floor INT, OUT room INT, OUT department_id INT, OUT capacity INT)
RETURNS SETOF RECORD AS $$
    WITH RelevantBookings AS (
        SELECT *
        FROM Bookings AS B
        WHERE B.start_hour BETWEEN search_start_hour AND (search_end_hour - 1)
        AND B.date = search_date
    ) SELECT M.floor AS floor, M.room AS room, M.department_id AS department_id, R.capacity AS capacity
    FROM MeetingRooms AS M JOIN RoomCapacity AS R ON M.floor = R.floor AND M.room = R.room LEFT JOIN RelevantBookings AS B ON M.floor = B.floor AND M.room = B.room
    WHERE R.capacity >= search_capacity AND B.creator_id IS NULL
    ORDER BY R.capacity ASC;
$$ LANGUAGE sql;

CREATE OR REPLACE PROCEDURE book_room
(floor INT, room INT, date DATE, start_hour INT, end_hour INT, employee_id INT)
AS $$
BEGIN
    WHILE start_hour < end_hour LOOP
        INSERT INTO Bookings VALUES (book_room.floor, book_room.room, book_room.date, book_room.start_hour, book_room.employee_id);
        INSERT INTO Attends VALUES (book_room.employee_id, book_room.floor, book_room.room, book_room.date, book_room.start_hour);
        start_hour := start_hour + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE unbook_room
(floor INT, room INT, date DATE, start_hour INT, end_hour INT, employee_id INT)
AS $$
BEGIN
    WHILE start_hour < end_hour LOOP
        DELETE FROM Bookings AS B WHERE B.floor = unbook_room.floor AND B.room = unbook_room.room AND B.creator_id = unbook_room.employee_id AND B.start_hour BETWEEN unbook_room.start_hour AND (unbook_room.end_hour - 1);
        start_hour := start_hour + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;