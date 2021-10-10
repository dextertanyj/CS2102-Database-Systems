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
    UPDATE departments SET removal_date = date WHERE Departments.id = department_id;
$$ LANGUAGE sql;

CREATE OR REPLACE PROCEDURE add_room
(floor INT, room INT, name VARCHAR(255), capacity INT, department_id INT, manager_id INT, effective_date DATE)
AS $$
BEGIN
    IF (department_id <> (SELECT E.department_id FROM Employees AS E WHERE E.id = manager_id)) THEN
        RAISE EXCEPTION 'Manager department and room department mismatch' USING HINT = 'Manager and new room should belong to the same department';
    END IF;
    IF (SELECT * FROM resigned_employee_guard(manager_id)) THEN
        RAISE EXCEPTION 'Manager has resigned' USING HINT = 'Manager has resigned and can no longer add rooms';
    END IF;
    If (SELECT * FROM removed_department_guard(department_id)) THEN
        RAISE EXCEPTION 'Department has been removed' USING HINT = 'Department has been removed and no new rooms can be assigned to it';
    END IF;
    INSERT INTO MeetingRooms VALUES (floor, room, name, department_id);
    INSERT INTO Updates VALUES (manager_id, floor, room, effective_date, capacity);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE change_capacity
(room_floor INT, update_room INT, new_capacity INT, update_manager_id INT, effective_date DATE)
AS $$
BEGIN
    IF ((SELECT COUNT(*) FROM updates AS U WHERE U.floor = room_floor AND U.room = update_room AND U.date = effective_date) = 1) THEN
        UPDATE updates SET manager_id = update_manager_id, capacity = new_capacity WHERE floor = room_floor AND room = update_room AND date = effective_date;
    ELSE
        INSERT INTO updates VALUES (update_manager_id, room_floor, update_room, effective_date, new_capacity);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_employee
(IN name VARCHAR(255), IN contact_number VARCHAR(20), IN type VARCHAR(7), IN department_id INT, OUT employee_id INT, OUT employee_email VARCHAR(255))
RETURNS RECORD AS $$
BEGIN
    If (SELECT * FROM removed_department_guard(department_id)) THEN
        RAISE EXCEPTION 'Department has been removed' USING HINT = 'Department has been removed and no new employees can be assigned to it';
    END IF;
    INSERT INTO Employees (name, contact_number, email, department_id) VALUES (name, contact_number, ' ', department_id) RETURNING Employees.id INTO employee_id;
    employee_email := employee_id||'@company.com';
    UPDATE Employees SET email = employee_email WHERE id = employee_id;
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
    UPDATE Employees SET resignation_date = date WHERE id = employee_id;
$$ LANGUAGE sql;
