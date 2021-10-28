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

-- TEST trigger 34 Meeting room booking or approval insert_employee_booking_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Seniors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (4), (5), (6);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, NULL); -- Success
SELECT * FROM Bookings;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Meeting room booking or approval insert_resigned_employee_booking_failure
-- BEFORE TEST
CALL reset();
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Seniors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (4), (5), (6);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, 6); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 3, NULL); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 3, 6); -- Failure
SELECT * FROM Bookings;
-- AFTER TEST
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
CALL reset();
-- TEST END

-- TEST trigger 34 Meeting room booking or approval update_employee_booking_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Seniors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (4), (5), (6);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, NULL); -- Success
SELECT * FROM Bookings;
UPDATE Bookings SET creator_id = 2 where creator_id = 1; -- Success
SELECT * FROM Bookings;
UPDATE Bookings SET approver_id = 5 where approver_id IS NULL; -- Success
SELECT * FROM Bookings;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Meeting room booking or approval update_resigned_employee_booking_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Seniors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (4), (5), (6);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, NULL); -- Success
SELECT * FROM Bookings;
UPDATE Bookings SET creator_id = 3 WHERE creator_id = 1; -- Failure
SELECT * FROM Bookings;
UPDATE Bookings SET approver_id = 6 WHERE approver_id IS NULL; -- Failure
SELECT * FROM Bookings;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration insert_employee_declaration_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Seniors VALUES (1), (2), (3);
COMMIT;
-- TEST
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0); -- Success
SELECT * FROM HealthDeclarations;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration insert_resigned_employee_declaration_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Seniors VALUES (1), (2), (3);
COMMIT;
-- TEST
INSERT INTO HealthDeclarations VALUES(3, CURRENT_DATE, 37.0); -- Failure
SELECT * FROM HealthDeclarations;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration update_employee_declaration_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Seniors VALUES (1), (2), (3);
COMMIT;
-- TEST
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0); -- Success
SELECT * FROM HealthDeclarations;
Update HealthDeclarations SET id = 2 WHERE id = 1; -- Success
SELECT * FROM HealthDeclarations;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration update_resigned_employee_declaration_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Seniors VALUES (1), (2), (3);
COMMIT;
-- TEST
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0); -- Success
SELECT * FROM HealthDeclarations;
Update HealthDeclarations SET id = 3 WHERE id = 1; -- Failure
SELECT * FROM HealthDeclarations;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting insert_employee_attendance_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (1), (2), (3), (4);
INSERT INTO Managers VALUES (5);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Attends;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting insert_resigned_employee_attendance_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (1), (2), (3), (4);
INSERT INTO Managers VALUES (5);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(3, 1, 1, CURRENT_DATE, 1); -- Failure
SELECT * FROM Attends;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting update_employee_attendance_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (1), (2), (3), (4);
INSERT INTO Managers VALUES (5);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Attends;
UPDATE Attends SET employee_id = 2 WHERE employee_id = 1; -- Success
SELECT * FROM Attends;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting update_resigned_employee_attendance_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Resigned Senior 3', 'Contact 3', 'senior3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (1), (2), (3), (4);
INSERT INTO Managers VALUES (5);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Attends;
UPDATE Attends SET employee_id = 3 WHERE employee_id = 1; -- Failure
SELECT * FROM Attends;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity insert_employee_update_success
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
INSERT INTO Updates VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Updates;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity insert_resigned_employee_update_failure
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
SELECT * FROM Updates;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity update_employee_update_success
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
INSERT INTO Updates VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Updates;
UPDATE Updates SET manager_id = 2 WHERE manager_id = 1; -- Success
SELECT * FROM Updates;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity update_resigned_employee_update_failure
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
INSERT INTO Updates VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Updates;
UPDATE Updates SET manager_id = 3 WHERE manager_id = 1; -- Failure
SELECT * FROM Updates;
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

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;