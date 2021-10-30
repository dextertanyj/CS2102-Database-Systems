SET client_min_messages TO WARNING;
CREATE OR REPLACE PROCEDURE reset()
AS $$
    TRUNCATE
    Departments,
    Employees,
    Juniors,
    Superiors,
    Seniors,
    Managers,
    HealthDeclarations,
    MeetingRooms,
    Bookings,
    Attends,
    Updates 
CASCADE;
$$ LANGUAGE sql;

/*****************
* ADD DEPARTMENT *
*****************/

-- TEST Unique Name & ID Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
CALL add_department(2, 'Department 2'); -- Success
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', NULL), (2, 'Department 2', NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Duplicate Name Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
CALL add_department(2, 'Department 1'); -- Success
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', NULL), (2, 'Department 1', NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Duplicate ID Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
CALL add_department(1, 'Department 2'); -- Failure
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', NULL)
-- AFTER TEST
CALL reset();
-- TEST END

/********************
* REMOVE DEPARTMENT *
********************/

-- TEST remove_department_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
-- TEST
CALL remove_department(1, CURRENT_DATE); -- Success
SELECT removal_date FROM Departments WHERE id = 1; -- Returns CURRENT_DATE
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_department_non_existant_department_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
-- TEST
CALL remove_department(3, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

/***********
* ADD ROOM *
***********/

-- TEST add_room_sucess
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(2, 1, 'Room 2-1', 10, 1, CURRENT_DATE); -- Success
SELECT COUNT(*) FROM MeetingRooms; -- Returns 3
SELECT COUNT(*) FROM Updates; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_duplicate_name_sucess
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(2, 1, 'Room 1-1', 10, 1, CURRENT_DATE); -- Success
SELECT COUNT(*) FROM MeetingRooms; -- Returns 3
SELECT COUNT(*) FROM Updates; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_duplicate_location_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(1, 1, 'Room Unique Name', 10, 1, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_duplicate_location_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(1, 1, 'Room Unique Name', 10, 1, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_resigned_manager_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(2, 1, 'Room 2-1', 10, 3, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_senior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(2, 1, 'Room 2-1', 10, 4, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_junior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(2, 1, 'Room 2-1', 10, 5, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

/******************
* CHANGE CAPACITY *
******************/

-- TEST change_capacity_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
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
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
-- TEST
CALL change_capacity(1, 1, 20, 2, CURRENT_DATE); -- Success
SELECT capacity FROM Updates WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE; -- Returns 20
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_resigned_employee_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
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
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
-- TEST
CALL change_capacity(1, 1, 20, 3, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_different_department_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
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
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
-- TEST
CALL change_capacity(1, 1, 20, 2, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_senior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
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
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
-- TEST
CALL change_capacity(1, 1, 20, 5, CURRENT_DATE); -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_junior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
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
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
-- TEST
CALL change_capacity(1, 1, 20, 6, CURRENT_DATE); -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_non_existant_room_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
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
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
-- TEST
CALL change_capacity(2, 1, 20, 1, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

/***************
* ADD EMPLOYEE *
***************/

-- TEST add_employee_manager_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'manager', 1); -- Success
SELECT * FROM Managers AS M JOIN Employees AS E ON M.id = E.id WHERE E.name = 'John Doe';
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_senior_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'manager', 1); -- Success
SELECT * FROM Managers AS M JOIN Employees AS E ON M.id = E.id WHERE E.name = 'John Doe';
SELECT add_employee('John Doe', 'Contact 1', 'senior' , 1); -- Success
SELECT * FROM Seniors AS S JOIN Employees AS E ON S.id = E.id WHERE E.name = 'John Doe';
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_junior_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'junior' , 1); -- Success
SELECT * FROM Seniors AS J JOIN Employees AS E ON J.id = E.id WHERE E.name = 'John Doe';
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_invalid_department_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'junior', 2); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_unknown_type_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'Unknown' , 1); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_duplicate_name_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
SELECT add_employee('Manager 1', 'Contact 2', 'manager' , 1); -- Success
SELECT * FROM Seniors AS J JOIN Employees AS E ON J.id = E.id WHERE E.name = 'Manager 1' AND E.contact = 'Contact 2';
-- AFTER TEST
CALL reset();
-- TEST END

/******************
* REMOVE EMPLOYEE *
******************/

-- TEST remove_employee_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Resigned Manager 2', 'Contact 2', 'manager2@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
-- TEST
CALL remove_employee(1, CURRENT_DATE); -- Success
SELECT E.resignation_date FROM Employees AS E WHERE E.id = 1; -- Returns CURRENT_DATE
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_employee_already_resigned_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Resigned Manager 2', 'Contact 2', 'manager2@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
-- TEST
CALL remove_employee(2, CURRENT_DATE); -- Failure
SELECT E.resignation_date FROM Employees AS E WHERE E.id = 2; -- Returns CURRENT_DATE - 1
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_employee_non_existant_employee_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Resigned Manager 2', 'Contact 2', 'manager2@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
-- TEST
CALL remove_employee(3, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

/**************
* SEARCH ROOM *
**************/

-- TEST search_room
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1', 1),
    (1, 2, 'Room 2', 1),
    (2, 1, 'Room 3', 2);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE, 10),
    (1, 1, 2, CURRENT_DATE, 5),
    (1, 2, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
SELECT search_room(10, CURRENT_DATE + 1, 4, 8); -- Returns (1, 1, 1, 10), (2, 1, 2, 10)
SELECT search_room(5, CURRENT_DATE + 1, 4, 8); -- Returns (1, 2, 1, 5), (1, 1, 1, 10), (2, 1, 2, 10)
SELECT search_room(10, CURRENT_DATE + 1, 1, 4); -- Returns (2, 1, 2, 10)
SELECT search_room(10, CURRENT_DATE + 1, 3, 4); -- Returns (2, 1, 2, 10)
SELECT search_room(10, CURRENT_DATE + 1, 4, 5); -- Returns (1, 1, 1, 10), (2, 1, 2, 10)
SELECT search_room(10, CURRENT_DATE + 2, 1, 3); -- Returns (1, 1, 1, 10), (2, 1, 2, 10)
-- AFTER TEST
CALL reset();
-- TEST END

/************
* BOOK ROOM *
************/

-- TEST book_room_single_hour_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 2, 0, 1, 2);
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 2; -- Return 1
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_single_hour_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 23, 24, 2);
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 2; -- Return 1
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_multiple_hour_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 2, 4, 6, 2); -- Success
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 2; -- Return 2
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_senior_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 2, 4, 6, 4); -- Success
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 2; -- Return 2
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_invalid_end_time_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 24, 25, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_invalid_duration_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 24, 2, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_invalid_start_time_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, -1, 0, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_overlapping_periods_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 2, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_overlapping_periods_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 4, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_overlapping_periods_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 10, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_junior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 10, 5); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

/**************
* UNBOOK ROOM *
**************/

-- TEST unbook_room_partial_batch_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 2, 1);
SELECT COUNT(*) FROM Bookings; -- Returns 2
SELECT COUNT(*) FROM Attends; -- Returns 2
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_entire_batch_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 4, 1);
SELECT COUNT(*) FROM Bookings; -- Returns 0
SELECT COUNT(*) FROM Attends; -- Returns 0
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_different_employee_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 3, 2);
SELECT COUNT(*) FROM Bookings; -- Returns 3
SELECT COUNT(*) FROM Attends; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_non_existent_booking_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 4, 5, 1);
SELECT COUNT(*) FROM Bookings; -- Returns 3
SELECT COUNT(*) FROM Attends; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_non_existent_room_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 2, CURRENT_DATE + 1, 1, 2, 1);
SELECT COUNT(*) FROM Bookings; -- Returns 3
SELECT COUNT(*) FROM Attends; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

/***************
* JOIN MEETING *
***************/

/****************
* LEAVE MEETING *
****************/

/******************
* APPROVE MEETING *
******************/

/*****************
* NON COMPLIANCE *
*****************/

-- TEST non_compliance
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO Seniors VALUES (4);
COMMIT;
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
-- Set Manager 3 to Resigned after declaring temperature (Otherwise temperature declaration is not allowed by trigger)
UPDATE Employees SET resignation_date = CURRENT_DATE - 1 WHERE id = 3;
-- TEST
SELECT * FROM non_compliance(CURRENT_DATE - 3, CURRENT_DATE); -- Expected: (4,4), (5,2), (2,1), (3,1)
-- AFTER TEST
CALL reset();
-- TEST END

/**********************
* VIEW BOOKING REPORT *
**********************/

-- TEST view_booking_report
-- BEFORE TEST
CALL reset();
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Seniors VALUES (1), (2);
INSERT INTO Managers VALUES (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (3, 1, 1, CURRENT_DATE - 2, 10);
COMMIT;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 2, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 3, 1, 1, 3),
    (1, 1, CURRENT_DATE, 2, 2, NULL),
    (1, 1, CURRENT_DATE, 3, 2, NULL);
-- TEST
SELECT * FROM view_booking_report(CURRENT_DATE, 1); -- Expected: (1,1,CURRENT_DATE,1,f), (1,1,CURRENT_DATE + 1,2,f), (1,1,CURRENT_DATE + 2,1,f)
-- AFTER TEST
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
CALL reset();
-- TEST END

/**********************
* VIEW FUTURE MEETING *
**********************/

/**********************
* VIEW MANAGER REPORT *
**********************/

/*****************
* DECLARE HEALTH *
*****************/

-- TEST declare_health_successful
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(1, CURRENT_DATE, 37.5); -- Success
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (1, CURRENT_DATE, 37.5), (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST declare_health_repeat_successful
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(2, CURRENT_DATE, 37.5); -- Success
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.5)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST declare_health_retired_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(3, CURRENT_DATE, 37.5); -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST declare_health_non_existent_employee_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(4, CURRENT_DATE, 37.5); -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST declare_health_past_date_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(1, CURRENT_DATE - 1, 37.5); -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST declare_health_future_date_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(1, CURRENT_DATE + 1, 37.5); -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST declare_health_low_temperature_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(1, CURRENT_DATE, 33.0); -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST declare_health_high_temperature_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(1, CURRENT_DATE, 45.0); -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

/******************
* CONTACT TRACING *
******************/

-- TEST contact_tracing_no_fever
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 2, 0),
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1),
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1),
    (2, 1, 1, CURRENT_DATE + 1, 0);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
UPDATE Bookings SET approver_id = 2 WHERE date = CURRENT_DATE - 2 OR date = CURRENT_DATE + 1;
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.0);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns NULL
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |            
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |            
     1 |    1 | CURRENT_DATE + 1 |                1 |          1 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 2 |                1 
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 
           1 |     1 |    1 | CURRENT_DATE + 1 |                1
           2 |     1 |    1 | CURRENT_DATE + 1 |                1
*/
-- TEST
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST contact_tracing_no_declaration
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1),
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1),
    (2, 1, 1, CURRENT_DATE + 1, 1);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
UPDATE Bookings SET approver_id = 2 WHERE date = CURRENT_DATE - 2 OR date = CURRENT_DATE + 1;
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
-- TEST
SELECT * FROM contact_tracing(1); -- Throws error
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |            
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |            
     1 |    1 | CURRENT_DATE + 1 |                1 |          1 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 
           1 |     1 |    1 | CURRENT_DATE + 1 |                1
           2 |     1 |    1 | CURRENT_DATE + 1 |                1
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST contact_tracing_fever_has_future_booking_no_close_contact
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (1, 2, 'Room 1-2', 1),
    (2, 1, 'Room 2-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 4, 1, 1, NULL), -- Attended by ALL
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL), -- Not Approved, Attended by ALL
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL),
    (1, 2, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 2, NULL),
    (2, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 3, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL), -- Deleted
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL), -- Attended by ALL, Deleted
    (1, 1, CURRENT_DATE + 1, 2, 2, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 3, NULL),
    (1, 1, CURRENT_DATE + 8, 1, 1, NULL); -- Attended by 2
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 4, 1),
    (3, 1, 1, CURRENT_DATE - 4, 1),
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (3, 1, 1, CURRENT_DATE - 2, 1),
    (2, 1, 1, CURRENT_DATE + 1, 1),
    (3, 1, 1, CURRENT_DATE + 1, 1),
    (2, 1, 1, CURRENT_DATE + 8, 1);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
UPDATE Bookings SET approver_id = 2 WHERE date = CURRENT_DATE - 4 OR date = CURRENT_DATE OR date = CURRENT_DATE + 1;
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns NULL
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 4 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |            
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |           2
     1 |    2 | CURRENT_DATE     | CURRENT_HOUR - 1 |          2 |           2
     2 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          3 |           2
     1 |    1 | CURRENT_DATE + 1 |                2 |          2 |           2
     1 |    1 | CURRENT_DATE + 1 |                3 |          3 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 4 |                1
           2 |     1 |    1 | CURRENT_DATE - 4 |                1
           3 |     1 |    1 | CURRENT_DATE - 4 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           3 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    2 | CURRENT_DATE     | CURRENT_HOUR - 1
           3 |     2 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    1 | CURRENT_DATE + 1 |                2
           3 |     1 |    1 | CURRENT_DATE + 1 |                3
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST contact_tracing_fever_has_future_attendance_no_close_contact
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (1, 2, 'Room 1-2', 1),
    (2, 1, 'Room 2-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 4, 1, 1, NULL), -- Attended by ALL
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL), -- Not Approved, Attended by ALL
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL),
    (1, 2, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 2, NULL),
    (2, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 3, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 2, NULL), -- Attended By 1
    (1, 1, CURRENT_DATE + 1, 2, 2, NULL), -- Attended by 1
    (1, 1, CURRENT_DATE + 1, 3, 3, NULL),
    (1, 1, CURRENT_DATE + 8, 2, 2, NULL);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 4, 1),
    (3, 1, 1, CURRENT_DATE - 4, 1),
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (3, 1, 1, CURRENT_DATE - 2, 1),
    (1, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (1, 1, 1, CURRENT_DATE + 1, 2), -- Removed
    (1, 1, 1, CURRENT_DATE + 8, 2);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
UPDATE Bookings SET approver_id = 2 WHERE date = CURRENT_DATE - 4 OR date = CURRENT_DATE OR date = CURRENT_DATE + 1;
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns NULL
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 4 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |            
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |           2
     1 |    2 | CURRENT_DATE     | CURRENT_HOUR - 1 |          2 |           2
     2 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          3 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 |          2 |           2
     1 |    1 | CURRENT_DATE + 1 |                2 |          2 |           2
     1 |    1 | CURRENT_DATE + 1 |                3 |          3 |           2
     1 |    1 | CURRENT_DATE + 8 |                2 |          2 |            
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 4 |                1
           2 |     1 |    1 | CURRENT_DATE - 4 |                1
           3 |     1 |    1 | CURRENT_DATE - 4 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           3 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    2 | CURRENT_DATE     | CURRENT_HOUR - 1
           3 |     2 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1
           2 |     1 |    1 | CURRENT_DATE + 1 |                2
           3 |     1 |    1 | CURRENT_DATE + 1 |                3
           2 |     1 |    1 | CURRENT_DATE + 8 |                2
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST contact_tracing_fever_has_close_contact_has_future_attendance
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Manager 6', 'Contact 6', 'manager6@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Managers VALUES (1), (2), (3), (4), (5), (6);
COMMIT;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (1, 2, 'Room 1-2', 1),
    (2, 1, 'Room 2-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 4, 1, 1, NULL), -- Attended by 6
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL), -- Attended by 2
    (1, 1, CURRENT_DATE - 2, 2, 2, NULL), -- Attended by 1 and 3
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2, 4, NULL), -- Attended by 1 and 5
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL), -- Attended by 4
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 6, NULL), -- Attended by all
    (1, 1, CURRENT_DATE + 7, 6, 6, NULL),
    (1, 1, CURRENT_DATE + 8, 2, 2, NULL); -- Attended by all
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (6, 1, 1, CURRENT_DATE - 4, 1),
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (1, 1, 1, CURRENT_DATE - 2, 2),
    (3, 1, 1, CURRENT_DATE - 2, 2),
    (1, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2),
    (5, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2),
    (4, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1),
    (1, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (3, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (4, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (5, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (1, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (2, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (3, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (4, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (5, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (1, 1, 1, CURRENT_DATE + 8, 2), -- Removed
    (3, 1, 1, CURRENT_DATE + 8, 2),
    (4, 1, 1, CURRENT_DATE + 8, 2),
    (5, 1, 1, CURRENT_DATE + 8, 2),
    (6, 1, 1, CURRENT_DATE + 8, 2);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
UPDATE Bookings SET approver_id = 2;
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns (2), (3), (4), (5)
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 4 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                2 |          2 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2 |          4 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 |          6 |           2
     1 |    1 | CURRENT_DATE + 7 |                6 |          6 |           2
     1 |    1 | CURRENT_DATE + 8 |                2 |          2 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 4 |                1
           6 |     1 |    1 | CURRENT_DATE - 4 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                2
           2 |     1 |    1 | CURRENT_DATE - 2 |                2
           3 |     1 |    1 | CURRENT_DATE - 2 |                2
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           4 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           5 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           4 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           6 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1
           6 |     1 |    1 | CURRENT_DATE + 7 |                6
           2 |     1 |    1 | CURRENT_DATE + 8 |                2
           3 |     1 |    1 | CURRENT_DATE + 8 |                2
           4 |     1 |    1 | CURRENT_DATE + 8 |                2
           5 |     1 |    1 | CURRENT_DATE + 8 |                2
           6 |     1 |    1 | CURRENT_DATE + 8 |                2
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST contact_tracing_fever_has_close_contact_has_future_booking
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Managers VALUES (1), (2), (3), (4), (5);
COMMIT;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (1, 2, 'Room 1-2', 1),
    (2, 1, 'Room 2-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL), -- Attended by 2
    (1, 1, CURRENT_DATE - 2, 2, 2, NULL), -- Attended by 1 and 3
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2, 4, NULL), -- Attended by 1 and 5
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL), -- Attended by 4
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 2, NULL), -- Removed
    (1, 1, CURRENT_DATE + 7, 3, 3, NULL), -- Removed
    (1, 1, CURRENT_DATE + 7, 4, 4, NULL), -- Removed
    (1, 1, CURRENT_DATE + 7, 5, 5, NULL), -- Removed
    (1, 1, CURRENT_DATE + 8, 2, 2, NULL);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (1, 1, 1, CURRENT_DATE - 2, 2),
    (3, 1, 1, CURRENT_DATE - 2, 2),
    (1, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2),
    (5, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2),
    (4, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
UPDATE Bookings SET approver_id = 2;
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns (2), (3), (4), (5)
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                2 |          2 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2 |          4 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |           2
     1 |    1 | CURRENT_DATE + 8 |                2 |          2 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                2
           2 |     1 |    1 | CURRENT_DATE - 2 |                2
           3 |     1 |    1 | CURRENT_DATE - 2 |                2
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           4 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           5 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           4 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    1 | CURRENT_DATE + 8 |                2
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST join_meeting
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
INSERT INTO Juniors VALUES (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 2);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 10, 2),
    (1, 1, CURRENT_DATE + 1, 11, 2);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 10, 2);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
-- TEST
/* All tests below should return the tables below unless otherwise mentioned:

 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE + 1 |         10
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
(2 rows)

 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE + 1 |         11
           2 |     1 |    1 | CURRENT_DATE + 1 |         11
(2 rows)
*/
---- success
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 1);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting full
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 3);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: already joined
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 5);
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 1);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting non existent
CALL join_meeting(2, 2, CURRENT_DATE + 1, 10, 12, 3);    
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: cannot join meeting in the past
CALL join_meeting(1, 1, CURRENT_DATE - 1, 10, 11, 3);  
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE - 1, 10);
/* Expected table:
 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
(1 row)
*/
---- failure: non existent employee
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 100);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting approved
UPDATE Bookings SET approver_id = 1 WHERE ROW (floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 11, 3);  
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST leave_meeting
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 1),
    (4, 'Junior 4', 'Contact 4', 'junior4@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
INSERT INTO Juniors VALUES (3), (4);
INSERT INTO MeetingRooms VALUES (1, 1, 'Meeting Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 10, 2),
    (1, 1, CURRENT_DATE + 1, 11, 2);
INSERT INTO Attends VALUES 
    (3, 1, 1, CURRENT_DATE + 1, 10),
    (3, 1, 1, CURRENT_DATE + 1, 11),
    (4, 1, 1, CURRENT_DATE + 1, 10),
    (4, 1, 1, CURRENT_DATE + 1, 11),
    (1, 1, 1, CURRENT_DATE + 1, 10),
    (1, 1, 1, CURRENT_DATE + 1, 11);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 10, 2);
INSERT INTO Attends VALUES (4, 1, 1, CURRENT_DATE - 1, 10);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
-- TEST
/* All tests below should return the tables below unless otherwise mentioned:
 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE + 1 |         10
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
           3 |     1 |    1 | CURRENT_DATE + 1 |         10
(3 rows)
 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE + 1 |         11
           2 |     1 |    1 | CURRENT_DATE + 1 |         11
           3 |     1 |    1 | CURRENT_DATE + 1 |         11
*/
---- success
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 4);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: employee trying to leave does not attend meeting
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 4);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting non existent
CALL leave_meeting(2, 2, CURRENT_DATE + 1, 10, 12, 3);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: non existent employee
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 100);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting creator cannot leave
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 2);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: cannot leave approve meeting
UPDATE Bookings SET approver_id = 1 WHERE ROW (floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 11, 3);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST approve_meeting_manager
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Departments VALUES (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (3);
INSERT INTO Seniors VALUES (2);
INSERT INTO MeetingRooms VALUES (1, 1, 'Meeting Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 10, 2);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 11, 2);
-- TEST
/* All tests below should return the tables below unless otherwise mentioned:
 floor | room | date | start_hour | creator_id | approver_id
-------+------+------+------------+------------+-------------
(0 rows)
*/
---- failure: approver from different department
CALL approve_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 3); 
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
---- failure: approver does not exist
CALL approve_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 5); 
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
---- failure: approver is not a manager
CALL approve_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 2); 
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
---- failure: approving meeting that does not exist
CALL approve_meeting(2, 2, CURRENT_DATE + 1, 10, 12, 1); -- CALL still goes through
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
---- success
CALL approve_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 1); 
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
/*
cs2102_project=# SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
 floor | room |       date       | start_hour | creator_id | approver_id
-------+------+------------------+------------+------------+-------------
     1 |    1 | CURRENT_DATE + 1 |         10 |          2 |           1
     1 |    1 | CURRENT_DATE + 1 |         11 |          2 |           1
(2 rows)
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST view_future_meeting
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Seniors VALUES (2);
INSERT INTO Managers VALUES (1);
INSERT INTO MeetingRooms VALUES (1, 1, 'Meeting Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 10, 2);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 11, 1),
    (1, 1, CURRENT_DATE + 1, 10, 1),
    (1, 1, CURRENT_DATE + 2, 10, 2),
    (1, 1, CURRENT_DATE + 2, 11, 2);
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE + 1, 11),
    (2, 1, 1, CURRENT_DATE + 1, 10);
UPDATE Bookings SET approver_id = 1 WHERE date = CURRENT_DATE + 1;
-- TEST
SELECT * FROM Attends WHERE employee_id = 2;
/* Expected: 
 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           2 |     1 |    1 | CURRENT_DATE - 1 |         10
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
           2 |     1 |    1 | CURRENT_DATE + 1 |         11
           2 |     1 |    1 | CURRENT_DATE + 1 |         11
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
(4 rows)
*/
SELECT * FROM view_future_meeting(CURRENT_DATE, 2);
/* Expected: 
 floor | room |       date       | start_hour
-------+------+------------------+------------
     1 |    1 | CURRENT_DATE + 1 |         10
     1 |    1 | CURRENT_DATE + 1 |         11
(2 rows)
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST view_manager_report
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Seniors VALUES (2);
INSERT INTO Managers VALUES (1);
INSERT INTO MeetingRooms VALUES (1, 1, 'Meeting Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
COMMIT;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 10, 2);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 11, 1),
    (1, 1, CURRENT_DATE + 1, 10, 1),
    (1, 1, CURRENT_DATE + 2, 10, 2),
    (1, 1, CURRENT_DATE + 2, 11, 2);
UPDATE Bookings SET approver_id = 1 WHERE ROW(date, start_hour) = (CURRENT_DATE + 2, 11);
-- TEST
SELECT * FROM Bookings;
/* Expected:
 floor | room |       date       | start_hour | creator_id | approver_id
-------+------+------------------+------------+------------+-------------
     1 |    1 | CURRENT_DATE - 1 |         10 |          2 |
     1 |    1 | CURRENT_DATE + 1 |         11 |          1 |
     1 |    1 | CURRENT_DATE + 1 |         10 |          1 |
     1 |    1 | CURRENT_DATE + 1 |         10 |          2 |
     1 |    1 | CURRENT_DATE + 1 |         11 |          2 |           1
(5 rows)
*/
SELECT * FROM view_manager_report(CURRENT_DATE, 1);
/* Expected:
 floor | room |       date       | start_hour | creator_id | approver_id
-------+------+------------------+------------+------------+-------------
     1 |    1 | CURRENT_DATE + 1 |         10 |          1 |
     1 |    1 | CURRENT_DATE + 1 |         11 |          1 |
     1 |    1 | CURRENT_DATE + 1 |         10 |          2 |
(3 rows)
*/
-- AFTER TEST
CALL reset();
-- END TEST

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;
