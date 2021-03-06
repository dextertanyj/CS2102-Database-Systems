/***********************
* Procedures/Functions *
***********************/

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

CREATE OR REPLACE PROCEDURE CheckFuture
(date DATE, start_hour INT) AS $$
BEGIN
    IF date < CURRENT_DATE OR date == CURRENT_DATE AND start_hour <= extract(HOUR FROM CURRENT_TIME) THEN
        RAISE EXCEPTION 'Date and time must be in the future.';
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
    CALL CheckFuture(date, start_hour);
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
    CALL CheckFuture(date, start_hour);
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

/***********
* Triggers *
***********/

/******************************************************************************
* E-5 Each employee must be one and only one of the three kinds of employees. *
******************************************************************************/
/* Non Overlap Constraints */
-- Insert or update of Juniors -> Must not exist in Superiors
CREATE OR REPLACE FUNCTION check_junior_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Superiors) THEN
        RAISE EXCEPTION 'Employee % already exists in Superiors.', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_junior ON Juniors;

CREATE TRIGGER non_overlap_junior
BEFORE INSERT OR UPDATE ON Juniors
FOR EACH ROW EXECUTE FUNCTION check_junior_overlap();

-- Insert or update of Superiors -> Must not exist in Juniors
CREATE OR REPLACE FUNCTION check_superior_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Juniors) THEN
        RAISE EXCEPTION 'Employee % already exists in Juniors.', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_superior ON Superiors;

CREATE TRIGGER non_overlap_superior
BEFORE INSERT OR UPDATE ON Superiors
FOR EACH ROW EXECUTE FUNCTION check_superior_overlap();

-- Insert or update of Seniors -> Must not exist in Managers
CREATE OR REPLACE FUNCTION check_senior_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Managers) THEN
        RAISE EXCEPTION 'Employee % already exists in Managers.', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_senior ON Seniors;

CREATE TRIGGER non_overlap_senior 
BEFORE INSERT OR UPDATE ON Seniors
FOR EACH ROW EXECUTE FUNCTION check_senior_overlap();

-- Insert or update of Managers -> Must not exist in Seniors
CREATE OR REPLACE FUNCTION check_manager_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Seniors) THEN
        RAISE EXCEPTION 'Employee % already exists in Seniors.', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_manager ON Managers;

CREATE TRIGGER non_overlap_manager
BEFORE INSERT OR UPDATE ON Managers
FOR EACH ROW EXECUTE FUNCTION check_manager_overlap();

/* Covering Constraints - Insert Cases */
-- Insert into Employees -> Must exist in either Juniors or Superiors
CREATE OR REPLACE FUNCTION check_covering_employee() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.id NOT IN (
        SELECT id FROM Juniors UNION
        SELECT id FROM Superiors) THEN
		RAISE EXCEPTION 'Employee % must exist either as a Junior, Senior or Manager.', NEW.id;
	END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS covering_employee_constraint ON Employees;

CREATE CONSTRAINT TRIGGER covering_employee_constraint 
AFTER INSERT ON Employees
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_covering_employee();

-- Insert into Superiors -> Must exist in either Seniors or Managers
CREATE OR REPLACE FUNCTION check_covering_superior() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.id NOT IN (
        SELECT id FROM Seniors UNION
        SELECT id FROM Managers) THEN
		RAISE EXCEPTION 'Superior % must exist either as a Senior or Manager.', NEW.id;
	END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS covering_superior_constraint ON Superiors;

CREATE CONSTRAINT TRIGGER covering_superior_constraint 
AFTER INSERT ON Superiors 
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_covering_superior();

/* Covering Constraints - Delete Cases */
-- Delete from Junior or Superior -> Either does not exist in Employees or must exist in either Juniors or Superiors
CREATE OR REPLACE FUNCTION existing_employee_covering_check() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT id FROM Employees WHERE id = OLD.id) IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    IF OLD.id NOT IN (SELECT id FROM Juniors UNION SELECT id FROM Superiors) THEN
        RAISE EXCEPTION 'Employee % must exist either as a Junior, Senior or Manager.', OLD.id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_junior_trigger ON Juniors;

CREATE CONSTRAINT TRIGGER delete_junior_trigger
AFTER UPDATE OR DELETE ON Juniors
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION existing_employee_covering_check();

DROP TRIGGER IF EXISTS delete_superior_trigger ON Superiors;

CREATE CONSTRAINT TRIGGER delete_superior_trigger
AFTER UPDATE OR DELETE ON Superiors
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION existing_employee_covering_check();

-- Delete from Manager or Senior -> Either does not exist in Superiors or must exist in either Seniors or Managers
CREATE OR REPLACE FUNCTION existing_superior_covering_check() RETURNS TRIGGER AS $$
BEGIN
    -- If OLD employee is not in Superiors, then they must have been deleted from Superiors.
    -- The delete from Junior or Superior case will handle constraint checking.
    IF (SELECT id FROM Superiors WHERE id = OLD.id) IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    IF OLD.id NOT IN (SELECT id FROM Seniors UNION SELECT id FROM Managers) THEN
        RAISE EXCEPTION 'Superior % must exist either as a Senior or Manager.', OLD.id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_senior_trigger ON Seniors;

CREATE CONSTRAINT TRIGGER delete_senior_trigger
AFTER UPDATE OR DELETE ON Seniors 
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION existing_superior_covering_check();

DROP TRIGGER IF EXISTS delete_manager_trigger ON Managers;

CREATE CONSTRAINT TRIGGER delete_manager_trigger
AFTER DELETE ON Managers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION existing_superior_covering_check();

/******************************************************************************
*                                   END E-5                                   *
******************************************************************************/

-- A-3 If an employee is having a fever, they cannot join a booked meeting.
CREATE OR REPLACE FUNCTION check_fever_attends() RETURNS TRIGGER AS $$
DECLARE
    temperature NUMERIC(3, 1) := NULL;
BEGIN
    SELECT H.temperature FROM HealthDeclarations AS H INTO temperature WHERE date = CURRENT_DATE AND id = NEW.employee_id;
    IF (temperature IS NOT NULL AND temperature > 37.5) THEN
		RAISE EXCEPTION 'Employee % is unable to join the meeting as they are having a fever.', NEW.employee_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_fever_attends_trigger ON Attends;

CREATE TRIGGER check_fever_attends_trigger
BEFORE INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_fever_attends();

-- A-4 Once approved, there should be no more changes in the participants and the participants will definitely attend the meeting.
CREATE OR REPLACE FUNCTION check_attends_change() RETURNS TRIGGER AS $$
DECLARE
    old_approver_id INT;
    new_approver_id INT;
BEGIN
    SELECT approver_id INTO old_approver_id FROM Bookings 
    WHERE floor = OLD.floor
        AND room = OLD.room
        AND date = OLD.date
        AND start_hour = OLD.start_hour;
    SELECT approver_id INTO new_approver_id FROM Bookings
    WHERE floor = NEW.floor
        AND room = NEW.room
        AND date = NEW.date
        AND start_hour = NEW.start_hour;
    
    IF TG_OP = 'DELETE' THEN
        IF old_approver_id IS NOT NULL THEN
            IF OLD.date >= (SELECT resignation_date FROM Employees WHERE id = OLD.employee_id) THEN
                RETURN OLD;
            END IF;
            RAISE EXCEPTION 'Booking (floor: %, room: %, date: %, time: %) has already been approved.', 
                OLD.floor, OLD.room, OLD.date, OLD.start_hour;
        END IF;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF old_approver_id IS NOT NULL THEN
            RAISE EXCEPTION 'Previous booking (floor: %, room: %, date: %, time: %) has already been approved.', 
                OLD.floor, OLD.room, OLD.date, OLD.start_hour;
        END IF;
        IF new_approver_id IS NOT NULL THEN
            RAISE EXCEPTION 'Incoming booking (floor: %, room: %, date: %, time: %) has already been approved.', 
                NEW.floor, NEW.room, NEW.date, NEW.start_hour;
        END IF;
        RETURN NEW;
    ELSE
        IF new_approver_id IS NOT NULL THEN
            RAISE EXCEPTION 'Booking (floor: %, room: %, date: %, time: %) has already been approved.', 
                NEW.floor, NEW.room, NEW.date, NEW.start_hour;           
        END IF;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lock_attends ON Attends;

CREATE TRIGGER lock_attends
BEFORE INSERT OR UPDATE OR DELETE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_attends_change();

-- C-1 A manager from the same department as the meeting room may change the meeting room capacity.
CREATE OR REPLACE FUNCTION check_update_capacity_perms() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT department_id FROM Employees WHERE id = NEW.manager_id) <>
        (SELECT department_id FROM MeetingRooms WHERE floor = NEW.floor AND room = NEW.room) THEN
        RAISE EXCEPTION 'Employee % does not have permissions to update the capacity of this meeting room.', NEW.manager_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_capacity_perms ON Updates;

CREATE TRIGGER update_capacity_perms
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_update_capacity_perms();

-- C-4 A meeting room can only have its capacity updated for a date not in the past, i.e. in the present or the future.
CREATE OR REPLACE FUNCTION check_update_capacity_time() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Meeting room capacity can only be updated for the future.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_capacity_not_in_past ON Updates;

CREATE TRIGGER update_capacity_not_in_past
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_update_capacity_time();

-- B-12 When an employee resigns, they are no longer allowed to book any meetings.
CREATE OR REPLACE FUNCTION check_resigned_creator() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.creator_id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee % has resigned.', NEW.creator_id;
	END IF ;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_creator_trigger ON Bookings;

CREATE TRIGGER check_resigned_creator_trigger
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_resigned_creator();

-- B-13 When an employee resigns, they are no longer allowed to approve any meetings.
CREATE OR REPLACE FUNCTION check_resigned_approver() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.approver_id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee % has resigned.', NEW.approver_id;
	END IF ;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_approver_trigger ON Bookings;

CREATE TRIGGER check_resigned_approver_trigger
BEFORE INSERT OR UPDATE OF approver_id ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_resigned_approver();

-- H-6 When an employee resigns, they are no longer allowed to make any health declarations.
CREATE OR REPLACE FUNCTION check_resigned_health_declaration() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee % has resigned.', NEW.id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_health_declaration_trigger ON HealthDeclarations;

CREATE TRIGGER check_resigned_health_declaration_trigger
BEFORE INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION check_resigned_health_declaration();

-- A-5 When an employee resigns, they are no longer allowed to join any booked meetings.
CREATE OR REPLACE FUNCTION check_resigned_attends() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.employee_id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee % has resigned.', NEW.employee_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_attends_trigger ON Attends;

CREATE TRIGGER check_resigned_attends_trigger
BEFORE INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_resigned_attends();

-- C-3 When an employee resigns, they are no longer allowed to change any meeting room capacities.
CREATE OR REPLACE FUNCTION check_resigned_updates() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.manager_id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee % has resigned.', NEW.manager_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_updates_trigger ON Updates;

CREATE TRIGGER check_resigned_updates_trigger
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_resigned_updates();

-- B-10 If an employee is having a fever, they cannot book a room.
CREATE OR REPLACE FUNCTION check_fever_booking() RETURNS TRIGGER AS $$
DECLARE
    temperature NUMERIC(3, 1) := NULL;
BEGIN
    SELECT H.temperature FROM HealthDeclarations AS H INTO temperature WHERE date = CURRENT_DATE AND id = NEW.creator_id;
    IF (temperature IS NOT NULL AND temperature > 37.5) THEN
		RAISE EXCEPTION 'Employee % is having a fever.', NEW.creator_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_fever_booking_trigger ON Bookings;

CREATE TRIGGER check_fever_booking_trigger
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_fever_booking();

-- B-5 The employee booking the room immediately joins the booked meeting.
CREATE OR REPLACE FUNCTION insert_meeting_creator()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.creator_id IS DISTINCT FROM OLD.creator_id) THEN
        IF (TG_OP = 'UPDATE') THEN
            DELETE FROM Attends 
            WHERE employee_id = OLD.creator_id 
                AND floor = OLD.floor 
                AND room = OLD.room 
                AND date = OLD.date 
                AND start_hour = OLD.start_hour;
        END IF;
        IF (NOT EXISTS 
            (SELECT * 
            FROM Attends AS A 
            WHERE A.employee_id = NEW.creator_id 
                AND A.room = NEW.room 
                AND A.floor = NEW.floor 
                AND A.date = NEW.date 
                AND A.start_hour = NEW.start_hour)
        ) THEN
            INSERT INTO Attends VALUES (NEW.creator_id, NEW.floor, NEW.room, NEW.date, NEW.start_hour);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insert_meeting_creator_trigger ON Bookings;

CREATE TRIGGER insert_meeting_creator_trigger
AFTER INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION insert_meeting_creator();

-- B-15 A meeting must be attended by its creator.
CREATE OR REPLACE FUNCTION prevent_creator_removal()
RETURNS TRIGGER AS $$
BEGIN
    IF (EXISTS
        (SELECT * 
        FROM Bookings AS B 
        WHERE B.creator_id = OLD.employee_id 
            AND B.room = OLD.room 
            AND B.floor = OLD.floor 
            AND B.date = OLD.date 
            AND B.start_hour = OLD.start_hour)
    ) THEN
        RAISE EXCEPTION 'Employee % cannot leave the meeting as they are the host.', OLD.employee_id;
    END IF;
    OLD = COALESCE(NEW, OLD);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_creator_removal_trigger ON Attends;

CREATE TRIGGER prevent_creator_removal_trigger
BEFORE DELETE OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION prevent_creator_removal();

-- B-7 A manager can only approve a booked meeting if the meeting room used is in the same department as the manager.
CREATE OR REPLACE FUNCTION meeting_approver_department_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.approver_id IS NOT NULL AND
        ((SELECT department_id FROM Employees AS E WHERE E.id = NEW.approver_id)
        IS DISTINCT FROM 
        (SELECT department_id FROM MeetingRooms AS M WHERE M.floor = NEW.floor AND M.room = NEW.room))
    ) THEN 
        RAISE EXCEPTION 'Employee % does not have permissions to approve this booking.', NEW.approver_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS meeting_approver_department_check_trigger ON Bookings;

CREATE TRIGGER meeting_approver_department_check_trigger
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION meeting_approver_department_check();

-- B-4 A booking can only be made for future meetings.
CREATE OR REPLACE FUNCTION booking_date_check()
RETURNS TRIGGER AS $$
BEGIN
    IF ((NEW.date < CURRENT_DATE) OR (NEW.date = CURRENT_DATE AND NEW.start_hour <= extract(HOUR FROM CURRENT_TIME))) THEN
        RAISE EXCEPTION 'Bookings can only be made for the future.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS booking_date_check_trigger ON Bookings;

CREATE TRIGGER booking_date_check_trigger
BEFORE INSERT OR UPDATE OF floor, room, date, start_hour ON Bookings
FOR EACH ROW EXECUTE FUNCTION booking_date_check();

-- B-8 An approval can only be made for future meetings.
CREATE OR REPLACE FUNCTION approval_only_for_future_meetings_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_hours_into_the_day INT := DATE_PART('HOUR', CURRENT_TIMESTAMP);
BEGIN
    IF (NEW.approver_id IS NOT NULL AND (NEW.date < CURRENT_DATE OR (NEW.date = CURRENT_DATE AND NEW.start_hour <= current_hours_into_the_day))) THEN
        RAISE EXCEPTION 'Approvals can only be given for future bookings.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS approval_only_for_future_meetings_trigger ON Bookings;

CREATE TRIGGER approval_only_for_future_meetings_trigger
BEFORE INSERT OR UPDATE OF approver_id ON Bookings
FOR EACH ROW EXECUTE FUNCTION approval_only_for_future_meetings_trigger();

-- A-2 An employee can only join future meetings.
CREATE OR REPLACE FUNCTION employee_join_only_future_meetings_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_hours_into_the_day INT := DATE_PART('HOUR', CURRENT_TIMESTAMP);
BEGIN
    IF (NEW.date < CURRENT_DATE OR (NEW.date = CURRENT_DATE AND NEW.start_hour <= current_hours_into_the_day)) THEN
        RAISE EXCEPTION 'Joining a meeting can only be done for future meetings.';
END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS employee_join_only_future_meetings_trigger ON Attends;

CREATE TRIGGER employee_join_only_future_meetings_trigger
BEFORE INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION employee_join_only_future_meetings_trigger();

-- MR-4 Each meeting room must have at least one relevant capacities entry.
CREATE OR REPLACE FUNCTION check_capacities_participation()
RETURNS TRIGGER AS $$
BEGIN
    IF(NOT EXISTS(SELECT * FROM Updates AS U WHERE U.floor = NEW.floor AND U.room = NEW.room)) THEN
        RAISE EXCEPTION 'Meeting room (floor: %, room: %) does not have an assigned capacity.', NEW.floor, NEW.room;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_capacities_participation_trigger ON MeetingRooms;

CREATE CONSTRAINT TRIGGER check_capacities_participation_trigger 
AFTER INSERT OR UPDATE ON MeetingRooms
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_capacities_participation();

CREATE OR REPLACE FUNCTION check_existing_capacities_participation()
RETURNS TRIGGER AS $$
BEGIN
    IF (NOT EXISTS (SELECT * FROM MeetingRooms AS M WHERE M.floor = OLD.floor AND M.room = OLD.room)) THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    IF (NOT EXISTS (SELECT * FROM Updates AS U WHERE U.floor = OLD.floor AND U.room = OLD.room)) THEN
        RAISE EXCEPTION 'Meeting room (floor: %, room: %) does not have an assigned capacity.', OLD.floor, OLD.room;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_existing_capacities_participation_trigger ON Updates;

CREATE CONSTRAINT TRIGGER check_existing_capacities_participation_trigger 
AFTER UPDATE OR DELETE ON Updates
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_existing_capacities_participation();

-- C-2 If a meeting room has its capacity changed, all future meetings that exceed the new capacity will be removed.
CREATE OR REPLACE FUNCTION check_future_meetings_on_capacity_change_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_hours_into_the_day INT := DATE_PART('HOUR', CURRENT_TIMESTAMP);
BEGIN
    DELETE FROM Bookings 
    WHERE ROW(floor, room, date, start_hour) IN 
    (SELECT a.floor, a.room, a.date, a.start_hour
        FROM Attends a
        WHERE a.date > NEW.date OR (a.date = NEW.date AND a.start_hour > current_hours_into_the_day)
        GROUP BY a.floor, a.room, a.date, a.start_hour
        HAVING count(a.employee_id) > NEW.capacity);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_future_meetings_on_capacity_change_trigger ON Updates;

CREATE TRIGGER check_future_meetings_on_capacity_change_trigger
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_future_meetings_on_capacity_change_trigger();

-- A-6 The number of people attending a meeting should not exceed the latest past capacity declared.
CREATE OR REPLACE FUNCTION check_meeting_capacity_trigger()
RETURNS TRIGGER AS $$
DECLARE 
    room_capacity INT := (SELECT capacity 
                            FROM RoomCapacities(NEW.date)
                            WHERE floor = NEW.floor
                            AND room = NEW.room);
                            
    current_room_count INT := (SELECT COUNT(*)
                                FROM Attends AS A
                                WHERE A.floor = NEW.floor
                                AND A.room = NEW.room
                                AND A.date = NEW.date
                                AND A.start_hour = NEW.start_hour);
BEGIN
    IF room_capacity IS NULL THEN
        RAISE EXCEPTION 'Meeting room (floor: %, room: %) does not have an effective capacity record.', NEW.floor, NEW.room;
    END IF;
    IF current_room_count > room_capacity THEN
        RAISE EXCEPTION 'Meeting room capacity has been reached.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_meeting_capacity_trigger ON Attends;

CREATE TRIGGER check_meeting_capacity_trigger
AFTER INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_meeting_capacity_trigger();

-- B-14 A approved booked meeting can no longer have any of its details changed, except for the revocation of its approver.
CREATE OR REPLACE FUNCTION lock_details_approved_bookings()
RETURNS TRIGGER AS $$
DECLARE
    resignation_date DATE := NULL;
BEGIN
    IF (OLD.approver_id IS NULL) THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = OLD.approver_id;
    IF (resignation_date < OLD.date AND OLD.approver_id IS DISTINCT FROM NEW.approver_id) THEN
        RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Unable to modify approved booking.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lock_details_approved_bookings_trigger ON Bookings;

CREATE TRIGGER lock_details_approved_bookings_trigger
BEFORE UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION lock_details_approved_bookings();

-- E-11 When a department has been removed, employees cannot be added to it.
-- MR-5 When a department has been removed, meeting rooms cannot be added to it.
CREATE OR REPLACE FUNCTION lock_removed_department()
RETURNS TRIGGER AS $$
BEGIN
    IF ((SELECT removal_date FROM Departments AS D WHERE D.id = NEW.department_id) IS NOT NULL) THEN
        RAISE EXCEPTION 'Department % has already been removed.', NEW.department_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lock_removed_department_employees_trigger ON Employees;

CREATE TRIGGER lock_removed_department_employees_trigger
BEFORE INSERT OR UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION lock_removed_department();

DROP TRIGGER IF EXISTS lock_removed_department_meeting_rooms_trigger ON MeetingRooms;

CREATE TRIGGER lock_removed_department_meeting_rooms_trigger
BEFORE INSERT OR UPDATE ON MeetingRooms
FOR EACH ROW EXECUTE FUNCTION lock_removed_department();

-- E-7 When an employee resigns, the employee is removed from all future meetings, approved or otherwise.
-- E-8 When an employee resigns, the employee has all their future booked meetings cancelled, approved or otherwise.
-- E-9 When an employee resigns, all future approvals granted by the employee are revoked.
CREATE OR REPLACE FUNCTION handle_resignation()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.resignation_date IS NOT NULL) THEN
        DELETE FROM Bookings AS B WHERE B.date > NEW.resignation_date AND B.creator_id = NEW.id;
        DELETE FROM Attends AS A WHERE A.date > NEW.resignation_date AND A.employee_id = NEW.id;
        UPDATE Bookings AS B SET approver_id = NULL 
        WHERE (B.date > CURRENT_DATE OR (B.date = CURRENT_DATE AND B.start_hour > extract(HOUR FROM CURRENT_TIME)))
            AND B.approver_id = NEW.id;
        DELETE FROM HealthDeclarations AS H WHERE H.date > NEW.resignation_date AND H.id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS handle_resignation_trigger ON Employees;

CREATE TRIGGER handle_resignation_trigger
AFTER INSERT OR UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION handle_resignation();

