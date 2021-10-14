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
        UPDATE updates SET manager_id = change_capacity.manager_id, capacity = change_capacity.capacity WHERE floor = change_capacity.floor AND room = change_capacity.room AND date = change_capacity.date;
    ELSE
        INSERT INTO updates VALUES (manager_id, floor, room, date, capacity);
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
