SET client_min_messages TO WARNING;
CREATE OR REPLACE PROCEDURE reset()
AS $$
    TRUNCATE Departments CASCADE;
    TRUNCATE Employees CASCADE;
    TRUNCATE Juniors CASCADE;
    TRUNCATE Superiors CASCADE;
    TRUNCATE Seniors CASCADE;
    TRUNCATE Managers CASCADE;
    TRUNCATE HealthDeclarations CASCADE;
    TRUNCATE MeetingRooms CASCADE;
    TRUNCATE Bookings CASCADE;
    TRUNCATE Attends CASCADE;
    TRUNCATE Updates CASCADE;
$$ LANGUAGE sql;

-- TEST add_department
-- BEFORE TEST
CALL reset();
-- TEST
CALL add_department(1, 'Department 1'); -- Success
SELECT COUNT(*) FROM departments; -- Return 1;
CALL add_department(2, 'Department 1'); -- Success
SELECT COUNT(*) FROM departments; -- Return 2;
CALL add_department(1, 'Department 1'); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_department
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
-- TEST
CALL remove_department(1, CURRENT_DATE); -- Success
SELECT removal_date FROM Departments WHERE id = 1;
CALL remove_department(0, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (4, 'Resigned Manager 4', 'Contact 4', 'manager4@company.com', CURRENT_DATE, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2), (3), (4);
-- TEST
CALL add_room(1, 1, 'Room 1', 10, 1, CURRENT_DATE); -- Success
CALL add_room(2, 1, 'Room 2', 10, 3, CURRENT_DATE); -- Success
CALL add_room(1, 1, 'Room 3', 10, 1, CURRENT_DATE); -- Failure
CALL add_room(1, 1, 'Room 4', 10, 3, CURRENT_DATE); -- Failure
CALL add_room(3, 1, 'Room 5', 10, 4, CURRENT_DATE); -- Failure
CALL add_room(4, 1, 'Room 6', 10, 5, CURRENT_DATE); -- Failure
CALL add_room(5, 1, 'Room 7', 10, 6, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (4, 'Resigned Manager 4', 'Contact 4', 'manager4@company.com', CURRENT_DATE, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2), (3), (4);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
-- TEST
CALL change_capacity(1, 1, 20, 1, CURRENT_DATE); -- Success
CALL change_capacity(1, 1, 30, 2, CURRENT_DATE); -- Success
CALL change_capacity(1, 1, 40, 3, CURRENT_DATE); -- Failure
CALL change_capacity(2, 1, 50, 2, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'manager', 1); -- Success
SELECT * FROM Managers AS M JOIN Employees AS E ON M.id = E.id WHERE M.id = 1;
SELECT add_employee('John Doe', 'Contact 2', 'senior' , 1); -- Success
SELECT * FROM Seniors AS S JOIN Employees AS E ON S.id = E.id WHERE S.id = 2;
SELECT add_employee('Jane Doe', 'Contact 3', 'junior' , 1); -- Success
SELECT * FROM Seniors AS J JOIN Employees AS E ON J.id = E.id WHERE J.id = 3;
SELECT add_employee('John Doe', 'Contact 4', 'junior' , 4); -- Failure
SELECT add_employee('John Doe', 'Contact 5', 'Unknown' , 4); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_employee
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
-- TEST
CALL remove_employee(1, CURRENT_DATE); -- Success
SELECT E.resignation_date FROM Employees AS E WHERE E.id = 1; -- Returns CURRENT_DATE
CALL remove_employee(3, CURRENT_DATE); -- Success
SELECT E.resignation_date FROM Employees AS E WHERE E.id = 3; -- Returns CURRENT_DATE
CALL remove_employee(10, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;

-- TEST non_compliance
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO HealthDeclarations VALUES
    (1, CURRENT_DATE - 3, 37.0),
    (1, CURRENT_DATE - 2, 37.0),
    (1, CURRENT_DATE - 1, 37.0),
    (1, CURRENT_DATE, 37.0),
    (2, CURRENT_DATE - 3, 37.0),
    (2, CURRENT_DATE - 1, 37.0),
    (2, CURRENT_DATE, 37.0),
    (3, CURRENT_DATE - 3, 37.0),
    (3, CURRENT_DATE - 1, 37.0),
    (5, CURRENT_DATE - 2, 37.0),
    (5, CURRENT_DATE - 1, 37.0);
-- TEST
SELECT * FROM non_compliance(CURRENT_DATE - 3, CURRENT_DATE); -- Expected: (2,1), (3,1), (4,4), (5,2)
-- AFTER TEST
-- END TEST