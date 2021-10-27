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

-- TEST trigger 12 non overlapping Juniors, Seniors, Managers
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
INSERT INTO Juniors VALUES (1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Seniors VALUES (1);
INSERT INTO Seniors VALUES (6);
INSERT INTO Managers VALUES (5);
INSERT INTO Managers VALUES (6);
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (2, 'Err 2', 'contact 2', 'err2@company.com', NULL, 1);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (3, 'Err Superior 3', 'contact 3', 'err3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (3);
COMMIT;
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST trigger 22 1 approval per booking
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
    (3, 101, '3rd floor, room 101, Dept 1', 1);
INSERT INTO Bookings VALUES
    (3, 101, CURRENT_DATE, 15, 2, NULL);
UPDATE Bookings SET approver_id = 1 WHERE 
    floor = 3 AND room = 101 AND date = CURRENT_DATE AND start_hour = 15;
-- TEST
UPDATE Bookings SET approver_id = 2 WHERE 
    floor = 3 AND room = 101 AND date = CURRENT_DATE AND start_hour = 15;
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST trigger 23 no changes to attendance in already approved bookings
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
INSERT INTO MeetingRooms VALUES
    (3, 101, '3rd floor, room 101, Dept 1', 1);
INSERT INTO Bookings VALUES
    (3, 101, CURRENT_DATE, 10, 2, NULL),
    (3, 101, CURRENT_DATE, 15, 2, NULL);
INSERT INTO Attends VALUES
    (1, 3, 101, CURRENT_DATE, 15),
    (2, 3, 101, CURRENT_DATE, 15);
INSERT INTO Attends VALUES
    (2, 3, 101, CURRENT_DATE, 10);
UPDATE Bookings SET approver_id = 1 WHERE 
    floor = 3 AND room = 101 AND date = CURRENT_DATE AND start_hour = 15;
-- TEST
INSERT INTO Attends VALUES (5, 3, 101, CURRENT_DATE, 15);
UPDATE Attends SET employee_id = 5 WHERE employee_id = 2;
DELETE FROM Attends WHERE employee_id = 2;
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST trigger 24 Only managers in same department have permissions to change booking
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (3);
INSERT INTO Managers VALUES (1), (3);
COMMIT;
INSERT INTO MeetingRooms VALUES (3, 101, '3rd floor, room 101, Dept 1', 1);
-- TEST
INSERT INTO Updates VALUES (3, 3, 101, CURRENT_DATE, 10); -- Failure
INSERT INTO Updates VALUES (1, 3, 101, CURRENT_DATE, 10); -- Success
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST trigger 34 Meeting room booking or approval
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Superior 1', 'Contact 1', 'superior1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Resigned Superior 3', 'Contact 3', 'superior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Managers VALUES (4), (5), (6);
INSERT INTO Seniors VALUES (1), (2), (3);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, 6); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 3, NULL); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 3, 6); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, 4); -- Success
UPDATE Bookings SET creator_id = 3 WHERE creator_id = 1; -- Failure
UPDATE Bookings SET approver_id = 6 WHERE approver_id = 4; -- Failure
UPDATE Bookings SET creator_id = 3, approver_id = 6 WHERE creator_id = 1; -- Failure
UPDATE Bookings SET creator_id = 2 where creator_id = 1; -- Success
UPDATE Bookings SET approver_id = 5 where approver_id = 4; -- Success
UPDATE Bookings SET creator_id = 1, approver_id = 4 where creator_id = 2 and approver_id = 5; -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1);
INSERT INTO Juniors VALUES (1), (2), (3);
COMMIT;
-- TEST
INSERT INTO HealthDeclarations VALUES(3, CURRENT_DATE, 37.0); -- Failure
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0); -- Success
Update HealthDeclarations SET id = 3 WHERE id = 1; -- Failure
Update HealthDeclarations SET id = 2 WHERE id = 1; -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1),
    (4, 'Superior 4', 'Contact 4', 'superior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (4), (5);
INSERT INTO Managers VALUES (5);
INSERT INTO Seniors VALUES (4);
INSERT INTO Juniors VALUES (1), (2), (3);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(3, 1, 1, CURRENT_DATE, 1); -- Failure
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
UPDATE Attends SET employee_id = 3 WHERE employee_id = 1; -- Failure
UPDATE Attends SET employee_id = 2 WHERE employee_id = 1; -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Updates VALUES(3, 1, 1, CURRENT_DATE, 1); -- Failure
INSERT INTO Updates VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
UPDATE Updates SET manager_id = 3 WHERE manager_id = 1; -- Failure
UPDATE Updates SET manager_id = 2 WHERE manager_id = 1; -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST insert_meeting_creator_trigger
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
SELECT * FROM Attends; -- Expects (1, 1, CURRENT_DATE + 1, 1), (1, 1, CURRENT_DATE + 1, 2)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST prevent_creator_removal_trigger
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
(1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
(2, 'Junior 2', 'Contact 2', 'junior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Juniors VALUES (2);
INSERT INTO Managers VALUES (1);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
DELETE FROM Attends WHERE employee_id = 1; -- Failure
UPDATE Attends SET start_hour = 3 WHERE employee_id = 1; -- Failure
UPDATE Attends SET start_hour = 2 WHERE employee_id = 2; -- Success
DELETE FROM Attends WHERE employee_id = 2; -- Success
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST meeting_approver_department_check_trigger
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET approver_id = 2; -- Failure
UPDATE Bookings SET approver_id = 1; -- Success
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 2, 1, 1); -- Success
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 3, 1, 2); -- Failure
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST booking_date_check_trigger
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 1, 1, NULL); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, NULL); -- Success
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL); -- Success
UPDATE Bookings SET date = CURRENT_DATE - 2 WHERE date = CURRENT_DATE + 1;
UPDATE Bookings SET date = CURRENT_DATE + 2 WHERE date = CURRENT_DATE + 1;
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST health_declaration_date_check_trigger_insert_success
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
-- TEST
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.0); -- Success
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (1, CURRENT_DATE, 37.0), (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST health_declaration_date_check_trigger_update_success
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
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
UPDATE HealthDeclarations SET temperature = 37.5 WHERE id = 2; -- Success
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.5)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST health_declaration_date_check_trigger_insert_future_failure
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
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE + 1, 37.0); -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST health_declaration_date_check_trigger_update_future_failure
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
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
UPDATE HealthDeclarations SET date = CURRENT_DATE + 1 WHERE id = 2; -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST health_declaration_date_check_trigger_insert_past_failure
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
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE - 1, 37.0); -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST health_declaration_date_check_trigger_update_past_failure
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
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE, 37.0);
-- TEST
UPDATE HealthDeclarations SET date = CURRENT_DATE - 1 WHERE id = 2; -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST health_declaration_date_check_trigger_update_existing_past_failure
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
ALTER TABLE HealthDeclarations DISABLE TRIGGER health_declaration_date_check_trigger;
INSERT INTO HealthDeclarations VALUES (2, CURRENT_DATE - 1, 37.0);
ALTER TABLE HealthDeclarations ENABLE TRIGGER health_declaration_date_check_trigger;
-- TEST
UPDATE HealthDeclarations SET temperature = 37.5, date = CURRENT_DATE WHERE date = CURRENT_DATE - 1; -- Failure
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns (2, CURRENT_DATE - 1, 37.0)
-- AFTER TEST
CALL reset();
-- END TEST

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;