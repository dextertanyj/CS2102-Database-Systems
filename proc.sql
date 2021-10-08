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
    IF (department_id != (SELECT E.department_id FROM Managers AS M JOIN Employees AS E ON M.id = E.id WHERE M.id = manager_id)) THEN
        RAISE EXCEPTION 'Manager department and room department mismatch' USING HINT = 'Manager and new room should belong to the same department';
    END IF;
    INSERT INTO MeetingRooms VALUES (floor, room, name, department_id);
    INSERT INTO Updates VALUES (manager_id, floor, room, effective_date, capacity);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_employee
(IN name VARCHAR(255), IN contact_number VARCHAR(20), IN type VARCHAR(7), IN department_id INT, OUT employee_id INT, OUT employee_email VARCHAR(255))
RETURNS RECORD AS $$
BEGIN
    INSERT INTO Employees (name, contact_number, email, department_id) VALUES (name, contact_number, ' ', department_id) RETURNING Employees.id INTO employee_id;
    employee_email = employee_id||'@company.com';
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
