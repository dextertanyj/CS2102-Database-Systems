CREATE OR REPLACE FUNCTION RoomCapacities
(IN query_date DATE, OUT floor INT, OUT room INT, OUT date DATE, OUT capacity INT)
RETURNS SETOF RECORD AS $$
    SELECT floor, room, date, capacity
    FROM Updates NATURAL JOIN (
        SELECT floor, room, MAX(date) AS date
        FROM Updates
        WHERE date <= RoomCapacities.query_date
        GROUP BY (floor, room)
    ) AS LatestRelevantUpdate;
$$ LANGUAGE sql;

CREATE OR REPLACE PROCEDURE TimeGuard
(start_hour INT, end_hour INT) AS $$
BEGIN
    IF (start_hour >= end_hour) THEN
        RAISE EXCEPTION 'Meeting time period is invalid.';
    END IF;
END;
$$ LANGUAGE plpgsql;

/****************
***** BASIC *****
****************/

CREATE OR REPLACE PROCEDURE add_department 
(id INT, name VARCHAR(255)) AS $$
    INSERT INTO Departments VALUES (id, name);
$$ LANGUAGE sql;

CREATE OR REPLACE PROCEDURE remove_department
(id INT) AS $$
DECLARE
BEGIN
    IF (NOT EXISTS (SELECT * FROM Departments AS D WHERE D.id = remove_department.id)) THEN
        RAISE EXCEPTION 'Department % not found.', id;
    END IF;
    IF ((SELECT removal_date FROM Departments AS D WHERE D.id = remove_department.id) IS NOT NULL) THEN
        RAISE EXCEPTION 'Department % has been removed.', id;
    END IF;
    UPDATE Departments SET removal_date = CURRENT_DATE WHERE Departments.id = remove_department.id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_room
(floor INT, room INT, name VARCHAR(255), capacity INT, manager_id INT, effective_date DATE) AS $$
DECLARE
    department_id INT := NULL;
BEGIN
    SELECT E.department_id INTO department_id FROM Employees AS E WHERE E.id = manager_id;
    INSERT INTO MeetingRooms VALUES (floor, room, name, department_id);
    INSERT INTO Updates VALUES (manager_id, floor, room, effective_date, capacity);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE change_capacity
(floor INT, room INT, capacity INT, manager_id INT, date DATE) AS $$
BEGIN
    IF (EXISTS
        (SELECT * FROM Updates AS U
        WHERE U.floor = change_capacity.floor
            AND U.room = change_capacity.room
            AND U.date = change_capacity.date)
    ) THEN
        UPDATE Updates AS U SET manager_id = change_capacity.manager_id, capacity = change_capacity.capacity
        WHERE U.floor = change_capacity.floor AND U.room = change_capacity.room AND U.date = change_capacity.date;
    ELSE
        INSERT INTO Updates VALUES (manager_id, floor, room, date, capacity);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_email
(IN name VARCHAR(255), OUT employee_email VARCHAR(255))
RETURNS VARCHAR(255) AS $$
DECLARE
    username VARCHAR(255);
    conflict VARCHAR(255);
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
    name := TRIM(name);
    SELECT generate_email(name) INTO employee_email;
    INSERT INTO Employees (name, contact_number, email, department_id) 
        VALUES (name, contact_number, employee_email, department_id) 
        RETURNING Employees.id INTO employee_id;
    IF (LOWER(type) = 'junior') THEN 
        INSERT INTO Juniors VALUES (employee_id);
    ELSIF (LOWER(type) = 'senior') THEN 
        INSERT INTO Superiors VALUES (employee_id);
        INSERT INTO Seniors VALUES (employee_id);
    ELSIF (LOWER(type) = 'manager') THEN
        INSERT INTO Superiors VALUES (employee_id);
        INSERT INTO Managers VALUES (employee_id);
    ELSE
        RAISE EXCEPTION 'Invalid employee type.' USING HINT = 'Accepted employee types: Junior | Senior | Manager';
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE remove_employee
(id INT, date Date) AS $$
BEGIN
    IF (NOT EXISTS(SELECT * FROM Employees AS E WHERE E.id = remove_employee.id)) THEN
        RAISE EXCEPTION 'Employee % not found.', id;
    END IF;
    IF ((SELECT resignation_date FROM Employees AS E WHERE E.id = remove_employee.id) IS NOT NULL) THEN
        RAISE EXCEPTION 'Employee % has already resigned.', id;
    END IF;
    UPDATE Employees AS E SET resignation_date = date WHERE E.id = remove_employee.id;
END;
$$ LANGUAGE plpgsql;

/***************
***** CORE *****
***************/

CREATE OR REPLACE FUNCTION search_room
(IN required_capacity INT, IN date DATE, IN start_hour INT, IN end_hour INT, OUT floor INT, OUT room INT, OUT department_id INT, OUT capacity INT)
RETURNS SETOF RECORD AS $$
BEGIN
    CALL TimeGuard(start_hour, end_hour);
    IF (required_capacity < 1) THEN
        RAISE EXCEPTION 'Capacity should be greater than 0.';
    END IF;
    RETURN QUERY WITH RelevantBookings AS (
        SELECT *
        FROM Bookings AS B
        WHERE B.start_hour BETWEEN search_room.start_hour AND (search_room.end_hour - 1)
        AND B.date = search_room.date
    ) SELECT M.floor AS floor, M.room AS room, M.department_id AS department_id, R.capacity AS capacity
    FROM MeetingRooms AS M JOIN (SELECT * FROM RoomCapacities(search_room.date)) AS R ON M.floor = R.floor AND M.room = R.room LEFT JOIN RelevantBookings AS B ON M.floor = B.floor AND M.room = B.room
    WHERE R.capacity >= search_room.required_capacity AND B.creator_id IS NULL
    ORDER BY R.capacity ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE book_room
(floor INT, room INT, date DATE, start_hour INT, end_hour INT, employee_id INT)
AS $$
BEGIN
    CALL TimeGuard(start_hour, end_hour);
    WHILE start_hour < end_hour LOOP
        INSERT INTO Bookings VALUES (book_room.floor, book_room.room, book_room.date, book_room.start_hour, book_room.employee_id);
        start_hour := start_hour + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE unbook_room
(floor INT, room INT, date DATE, start_hour INT, end_hour INT, employee_id INT)
AS $$
DECLARE
    loop_hour INT := start_hour;
BEGIN
    CALL TimeGuard(start_hour, end_hour);
    WHILE loop_hour < end_hour LOOP
        IF (NOT EXISTS 
            (SELECT * FROM Bookings AS B 
            WHERE B.floor = unbook_room.floor 
                AND B.room = unbook_room.room 
                AND B.start_hour = loop_hour)
        ) THEN
            RAISE EXCEPTION
            'No existing booking found (floor:% room:% date:% start hour:%).',
            floor, room, date, loop_hour;
        END IF;
        IF ((SELECT creator_id FROM Bookings AS B 
            WHERE B.floor = unbook_room.floor 
                AND B.room = unbook_room.room 
                AND B.start_hour = loop_hour) 
            IS DISTINCT FROM unbook_room.employee_id
        ) THEN
            RAISE EXCEPTION
            'Employee % does not have permission to remove booking (floor:% room:% date:% start hour:%).',
            employee_id, floor, room, date, loop_hour;
        END IF;
        loop_hour := loop_hour + 1;
    END LOOP;
    DELETE FROM Bookings AS B
    WHERE B.floor = unbook_room.floor
        AND B.room = unbook_room.room
        AND B.creator_id = unbook_room.employee_id
        AND B.start_hour BETWEEN unbook_room.start_hour AND (unbook_room.end_hour - 1);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE join_meeting
(floor INT, room INT, date DATE, start_hour INT, end_hour INT, employee_id INT)
AS $$
BEGIN
    CALL TimeGuard(start_hour, end_hour);
    WHILE start_hour < end_hour LOOP
        INSERT INTO Attends VALUES (employee_id, floor, room, date, start_hour);
        start_hour := start_hour + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE leave_meeting
(floor INT, room INT, date DATE, start_hour INT, end_hour INT, employee_id INT)
AS $$
DECLARE
    loop_hour INT := start_hour;
BEGIN
    CALL TimeGuard(start_hour, end_hour);
    WHILE loop_hour < end_hour LOOP
        IF (NOT EXISTS 
            (SELECT * FROM Attends AS A
            WHERE A.floor = leave_meeting.floor
                AND A.room = leave_meeting.room
                AND A.start_hour = loop_hour
                AND A.employee_id = leave_meeting.employee_id)
        ) THEN
            RAISE EXCEPTION
            'Employee % has not joined meeting (floor:% room:% date:% start hour:%).',
            employee_id, floor, room, date, loop_hour;
        END IF;
        loop_hour := loop_hour + 1;
    END LOOP;
    DELETE FROM Attends AS A 
    WHERE A.employee_id = leave_meeting.employee_id
        AND A.floor = leave_meeting.floor
        AND A.room = leave_meeting.room
        AND A.date = leave_meeting.date
        AND A.start_hour BETWEEN leave_meeting.start_hour AND (leave_meeting.end_hour - 1) ;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE approve_meeting
(floor INT, room INT, date DATE, start_hour INT, end_hour INT, manager_id INT)
AS $$
BEGIN
    CALL TimeGuard(start_hour, end_hour);
    WHILE start_hour < end_hour LOOP
        UPDATE Bookings AS B SET approver_id = manager_id
        WHERE B.floor = approve_meeting.floor
            AND B.room = approve_meeting.room
            AND B.date = approve_meeting.date
            AND B.start_hour = approve_meeting.start_hour;
        start_hour := start_hour + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

/****************
***** ADMIN *****
****************/

CREATE OR REPLACE FUNCTION non_compliance
(IN start_date DATE, IN end_date DATE, OUT employee_id INT, OUT number_of_days BIGINT)
RETURNS SETOF RECORD AS $$
BEGIN
    IF (start_date > end_date) THEN
        RAISE EXCEPTION 'Query date interval is invalid.';
    END IF;
    RETURN QUERY
        WITH CTE AS (
            SELECT H.id AS id, COUNT(*) AS days_declared
            FROM HealthDeclarations AS H
            WHERE H.date BETWEEN start_date AND end_date 
            GROUP BY H.id
        ) SELECT E.id AS employee_id, COALESCE(
                (CASE WHEN E.resignation_date < end_date THEN resignation_date ELSE end_date END) - start_date - C.days_declared + 1,
                (CASE WHEN E.resignation_date < end_date THEN resignation_date ELSE end_date END) - start_date + 1
            ) AS number_of_days
        FROM Employees AS E LEFT JOIN CTE AS C ON E.id = C.id
        WHERE (E.resignation_date IS NULL OR E.resignation_date >= start_date)
            AND (C.days_declared IS NULL OR C.days_declared < end_date - start_date + 1)
        ORDER BY number_of_days DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_booking_report
(IN start_date DATE, IN employee_id INT, OUT floor_number INT, OUT room_number INT, OUT date DATE, OUT start_hour INT, OUT is_approved BOOLEAN)
RETURNS SETOF RECORD AS $$
    SELECT B.floor AS floor_number, B.room AS room_number, B.date, B.start_hour, CASE WHEN B.approver_id IS NULL THEN FALSE ELSE TRUE END AS is_approved 
    FROM Bookings AS B
    WHERE B.date >= start_date AND B.creator_id = view_booking_report.employee_id ORDER BY date ASC, start_hour ASC;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION view_future_meeting
(IN start_date DATE, IN employee_id INT, OUT floor_number INT, OUT room_number INT, OUT date DATE, OUT start_hour INT)
RETURNS SETOF RECORD AS $$
    SELECT A.floor AS floor_number, A.room AS room_number, A.date, A.start_hour
    FROM Attends AS A
    NATURAL JOIN Bookings AS B
    WHERE A.employee_id = view_future_meeting.employee_id
    AND A.date >= start_date
    AND B.approver_id IS NOT NULL
    ORDER BY A.date ASC, A.start_hour ASC;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION view_manager_report
(IN start_date DATE, IN manager_id INT, OUT floor_number INT, OUT room_number INT, OUT date DATE, OUT start_hour INT, OUT creator_id INT)
RETURNS SETOF RECORD AS $$
BEGIN
    IF (SELECT id FROM Managers AS M WHERE M.id = manager_id) IS NULL THEN
        RETURN;
    ELSE
        RETURN QUERY
            SELECT B.floor AS floor_number, B.room AS room_number, B.date, B.start_hour, B.creator_id
            FROM Bookings AS B
            NATURAL JOIN MeetingRooms AS M
            WHERE B.date >= start_date
            AND B.approver_id IS NULL
            AND M.department_id = (SELECT department_id 
                                    FROM Employees AS E
                                    WHERE E.id = manager_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

/*****************
***** HEALTH *****
*****************/

CREATE OR REPLACE PROCEDURE declare_health
(id INT, date DATE, temperature NUMERIC(3, 1))
AS $$
BEGIN
    IF (EXISTS (SELECT * FROM HealthDeclarations AS H WHERE H.id = declare_health.id AND H.date = declare_health.date)) THEN
        UPDATE HealthDeclarations AS H SET temperature = declare_health.temperature WHERE H.id = declare_health.id AND H.date = declare_health.date;
        RETURN;
    END IF;
    INSERT INTO HealthDeclarations VALUES (id, date, temperature);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION contact_tracing
(IN id INT, OUT employee_id INT)
RETURNS SETOF INT AS $$
DECLARE
    cursor refcursor;
    time INT := extract(HOUR FROM CURRENT_TIME);
    declaration_date DATE := NULL;
BEGIN
    If (NOT EXISTS (SELECT * FROM HealthDeclarations AS H WHERE H.id = contact_tracing.id ORDER BY date DESC LIMIT 1)) THEN
        RAISE EXCEPTION 'Employee % does not have a declared temperature.', id;
    END IF;
    IF ((SELECT H.temperature FROM HealthDeclarations AS H WHERE H.id = contact_tracing.id ORDER BY date DESC LIMIT 1) <= 37.5) THEN
        RETURN;
    END IF;
    SELECT H.date INTO declaration_date FROM HealthDeclarations AS H WHERE H.id = contact_tracing.id ORDER BY date DESC LIMIT 1;
    ALTER TABLE Attends DISABLE TRIGGER lock_attends;
    DELETE FROM Bookings AS B 
    WHERE ((B.date = declaration_date AND B.start_hour > time) OR (B.date > declaration_date)) AND B.creator_id = contact_tracing.id;
    DELETE FROM Attends AS A
    WHERE ((A.date = declaration_date AND A.start_hour > time) OR (A.date > declaration_date)) AND A.employee_id = contact_tracing.id;
    OPEN cursor FOR
        WITH CTE AS (
            SELECT A.*
            FROM Attends AS A NATURAL JOIN Bookings AS B
            WHERE B.approver_id IS NOT NULL
                AND ((A.date BETWEEN declaration_date - 3 AND declaration_date - 1) OR (A.date = declaration_date AND A.start_hour <= time))
        ) SELECT DISTINCT A.employee_id
        FROM CTE AS A JOIN CTE AS B
            ON A.floor = B.floor
                AND A.room = B.room
                AND A.date = B.date
                AND A.start_hour = B.start_hour
                AND A.employee_id IS DISTINCT FROM B.employee_id
        WHERE B.employee_id = contact_tracing.id;
    LOOP
        FETCH NEXT FROM cursor INTO employee_id;
        EXIT WHEN NOT FOUND;
        DELETE FROM Bookings AS B 
        WHERE B.creator_id = contact_tracing.employee_id AND ((B.date BETWEEN declaration_date + 1 AND declaration_date + 7) OR (B.date = declaration_date AND B.start_hour > time));
        DELETE FROM Attends AS A 
        WHERE A.employee_id = contact_tracing.employee_id AND ((A.date BETWEEN declaration_date + 1 AND declaration_date + 7) OR (A.date = declaration_date AND A.start_hour > time));
        RETURN NEXT;
    END LOOP;
    CLOSE cursor;
    ALTER TABLE Attends ENABLE TRIGGER lock_attends;
END;
$$ LANGUAGE plpgsql;
