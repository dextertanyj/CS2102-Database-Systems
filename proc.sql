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
    If (SELECT * FROM removed_department_guard(department_id)) THEN
        RAISE EXCEPTION 'Department has been removed' USING HINT = 'Department has been removed and no new rooms can be assigned to it';
    END IF;
    SELECT E.department_id INTO manager_department_id FROM Employees AS E WHERE E.id = manager_id;
    INSERT INTO MeetingRooms VALUES (floor, room, name, department_id);
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
    IF (SELECT * FROM removed_department_guard(department_id)) THEN
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

-------------------------- CORE --------------------------

CREATE OR REPLACE FUNCTION has_fever
(IN e_id INT) RETURNS BOOLEAN 
AS $$
BEGIN
    IF (SELECT temperature 
            FROM HealthDeclarations 
            WHERE id = e_id
            ORDER BY date DESC
            LIMIT 1) > 37.5 THEN 
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION has_resigned
(IN e_id INT) RETURNS BOOLEAN 
AS $$
BEGIN
    IF (SELECT resignation_date
            FROM Employees 
            WHERE id = e_id) IS NOT NULL THEN
        RETURN TRUE;
    ELSE 
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_bookings
(IN floor_number INT, IN room_number INT, IN meeting_date DATE, IN starting_hour INT)
RETURNS TABLE (floor INT, room INT, date DATE, start_hour INT, creator_id INT, approver_id INT) 
AS $$
BEGIN
    RETURN QUERY
            SELECT *
            FROM Bookings
            WHERE floor = floor_number
            AND room = room_number
            AND date = meeting_date
            AND start_hour = starting_hour;
END;
$$ LANGUAGE plpgsql;

-- book_room should call on this function on the booker
-- need to check for missing booking?
CREATE OR REPLACE PROCEDURE join_meeting
(floor_number INT, room_number INT, join_date DATE, starting_hour INT, ending_hour INT, e_id INT)
AS $$
BEGIN
    IF has_fever(e_id) = TRUE THEN
        RAISE EXCEPTION 'Employee % has a fever', e_id;

    ELSIF has_resigned(e_id) = TRUE THEN
        RAISE EXCEPTION 'Employee % has resigned', e_id;
    ELSE
        LOOP
            EXIT WHEN starting_hour = ending_hour;
            INSERT INTO Bookings(floor, room, date, start_hour, creator_id) VALUES (floor_number, room_number, join_date, starting_hour, e_id);
            starting_hour := starting_hour + 1;
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE leave_meeting
(floor_number INT, room_number INT, meeting_date DATE, starting_hour INT, ending_hour INT, e_id INT)
AS $$
BEGIN
    -- check if the employee is even inside the booking
    IF (SELECT employee_id
            FROM Attends
            WHERE employee_id = e_id
            AND floor = floor_number
            AND room = room_number
            AND date = meeting_date
            AND start_hour = starting_hour) IS NULL THEN
        RAISE EXCEPTION 'Employee % does not attend this meeting', e_id;
    -- check if the booking has already been approved
    ELSIF (SELECT approver_id
            FROM Bookings
            WHERE floor = floor_number
            AND room = room_number
            AND date = meeting_date
            AND start_hour = starting_hour) IS NOT NULL THEN
        RAISE EXCEPTION 'Meeting has already been approved';
    ELSE
        LOOP
            EXIT WHEN starting_hour = ending_hour;
            DELETE FROM Attends 
            WHERE employee_id = e_id
            AND floor = floor_number
            AND room = room_number
            AND date = meeting_date
            AND start_hour = starting_hour;
            starting_hour := starting_hour + 1;
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE approve_meeting
(floor_number INT, room_number INT, meeting_date DATE, starting_hour INT, ending_hour INT, manager_id INT)
AS $$
BEGIN
    IF (SELECT id FROM Managers WHERE id = manager_id) IS NULL THEN
        RAISE EXCEPTION 'Employeee % is not a manager', manager_id;
    -- manager approving belongs to the a different department
    ELSIF (SELECT department_id FROM Employee WHERE id = manager_id) <> (SELECT department_id FROM MeetingRooms WHERE floor = floor_number AND room = room_number) THEN
        RAISE EXCEPTION 'Approving manager does not belong to the same department as meeting room';
    ELSE
        LOOP
            EXIT WHEN starting_hour = ending_hour;
            UPDATE Bookings SET approver_id = manager_id
            WHERE floor = floor_number
            AND room = room_number
            AND date = meeting_date
            AND start_hour = starting_hour;
            starting_hour := starting_hour + 1;
        END LOOP;
    END IF;
    -- 
END;
$$ LANGUAGE plpgsql;

-------------------------- ADMIN --------------------------

CREATE OR REPLACE FUNCTION view_future_meeting
(IN start_date DATE, IN e_id INT)
RETURNS TABLE (floor INT, room INT, date DATE, start_hour INT) 
AS $$
BEGIN
    RETURN QUERY
            SELECT a.floor, a.room, a.date, a.start_hour
            FROM Attends a
            NATURAL JOIN Bookings b
            WHERE a.employee_id = e_id
            AND date >= start_date
            AND b.approver_id IS NOT NULL
            ORDER BY a.date ASC, a.start_hour ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_manager_report
(IN start_date DATE, IN manager_id INT)
RETURNS TABLE (floor INT, room INT, date DATE, start_hour INT, m_id INT) 
AS $$
BEGIN
    IF (SELECT id FROM Manager WHERE id = manager_id) IS NULL THEN
        RETURN;
    ELSE
        RETURN QUERY
                SELECT floor, room, date, start_hour, manager_id
                FROM Bookings
                NATURAL JOIN MeetingRooms
                WHERE date >= start_date
                AND approver_id IS NULL
                AND department_id = (SELECT department_id 
                                        FROM Employee
                                        WHERE id = manager_id);
    END IF;
END;
$$ LANGUAGE plpgsql;
