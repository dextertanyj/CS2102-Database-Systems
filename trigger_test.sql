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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (3, 101, '3rd floor, room 101, Dept 1', 1);
INSERT INTO Updates VALUES
    (1, 3, 101, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (3, 101, '3rd floor, room 101, Dept 1', 1);
INSERT INTO Updates VALUES
    (1, 3, 101, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (3, 101, '3rd floor, room 101, Dept 1', 1);
INSERT INTO Updates VALUES
    (1, 3, 101, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
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
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Attends;
-- AFTER TEST
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting insert_resigned_employee_attendance_failure
-- BEFORE TEST
CALL reset();
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(3, 1, 1, CURRENT_DATE, 1); -- Failure
SELECT * FROM Attends;
-- AFTER TEST
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting update_employee_attendance_success
-- BEFORE TEST
CALL reset();
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Attends;
UPDATE Attends SET employee_id = 2 WHERE employee_id = 1; -- Success
SELECT * FROM Attends;
-- AFTER TEST
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting update_resigned_employee_attendance_failure
-- BEFORE TEST
CALL reset();
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, NULL);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Attends;
UPDATE Attends SET employee_id = 3 WHERE employee_id = 1; -- Failure
SELECT * FROM Attends;
-- AFTER TEST
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Updates VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
SELECT * FROM Updates;
UPDATE Updates SET manager_id = 3 WHERE manager_id = 1; -- Failure
SELECT * FROM Updates;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST insert_meeting_creator_trigger_insert_case
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
SELECT * FROM Attends; -- Expects (1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST insert_meeting_creator_trigger_update_case
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
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
UPDATE Bookings SET creator_id = 2;
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Expects (1, 1, CURRENT_DATE + 1, 1), (1, 1, CURRENT_DATE + 1, 2)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST prevent_creator_removal_trigger_update_other_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
(1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
(2, 'Junior 2', 'Contact 2', 'junior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
INSERT INTO Juniors VALUES (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
UPDATE Attends SET start_hour = 2 WHERE employee_id = 2; -- Success
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Expects (1, 1, 1, CURRENT_DATE + 1, 1), (1, 1, 1, CURRENT_DATE + 1, 2), (2, 1, 1, CURRENT_DATE + 1, 2)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST prevent_creator_removal_trigger_delete_other_success
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
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
DELETE FROM Attends WHERE employee_id = 2; -- Success
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Expects (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST prevent_creator_removal_trigger_delete_creator_failure
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
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
DELETE FROM Attends WHERE employee_id = 1; -- Failure
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Expects (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST


-- TEST prevent_creator_removal_trigger_update_creator_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
(1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
(2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
COMMIT;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 2, NULL);
-- TEST
UPDATE Attends SET start_hour = 2 WHERE employee_id = 1; -- Failure
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Expects (1, 1, 1, CURRENT_DATE + 1, 1), (2, 1, 1, CURRENT_DATE + 1, 2)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST meeting_approver_department_check_trigger_insert_same_department_success
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
-- TEST
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, 1); -- Success
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; 
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST meeting_approver_department_check_trigger_update_same_department_success
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET approver_id = 1; -- Success
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST meeting_approver_department_check_trigger_insert_different_department_failure
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
-- TEST
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 3, 1, 2); -- Failure
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST meeting_approver_department_check_trigger_update_different_department_failure
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
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST booking_date_check_trigger_insert_future_sucess
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (4, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL); -- Success
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL); -- Success
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST booking_date_check_trigger_update_future_success
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
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
-- TEST
UPDATE Bookings SET date = CURRENT_DATE, start_hour = extract(HOUR FROM CURRENT_TIME) + 1 WHERE date = CURRENT_DATE + 1 AND start_hour = 1; -- Success
UPDATE Bookings SET date = CURRENT_DATE + 2 WHERE date = CURRENT_DATE + 1 AND start_hour = 2; -- Success
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL), (1, 1, CURRENT_DATE + 2, 2, 1, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST booking_date_check_trigger_insert_past_failure
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
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL); -- Failure
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST booking_date_check_trigger_update_past_failure
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
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
-- TEST
UPDATE Bookings SET date = CURRENT_DATE, start_hour = extract(HOUR FROM CURRENT_TIME) - 1 WHERE date = CURRENT_DATE - 1 AND start_hour = 1; -- Failure
UPDATE Bookings SET date = CURRENT_DATE - 1, start_hour = extract(HOUR FROM CURRENT_TIME) + 1 WHERE date = CURRENT_DATE + 1 AND start_hour = 2; -- Failure
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, NULL)
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

-- TEST lock_approved_bookings_trigger_resigned_approver_update_success
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
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
UPDATE Bookings SET approver_id = 2 WHERE floor = 1 AND room = 1;
-- ALTER TABLE Employees DISABLE TRIGGER resigned_employee_cleanup_trigger;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 2;
-- ALTER TABLE Employees ENABLE TRIGGER resigned_employee_cleanup_trigger;
-- TEST
UPDATE Bookings SET approver_id = NULL WHERE floor = 1 AND room = 1 AND start_hour = 1;
UPDATE Bookings SET approver_id = 1 WHERE floor = 1 AND room = 1 AND start_hour = 2;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST lock_approved_bookings_trigger_update_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Managers VALUES (1), (2), (3), (4);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
UPDATE Bookings SET approver_id = 2 WHERE floor = 1 AND room = 1 AND start_hour = 1;
UPDATE Bookings SET approver_id = 3 WHERE floor = 1 AND room = 1 AND start_hour = 2;
UPDATE Bookings SET approver_id = 4 WHERE floor = 1 AND room = 1 AND start_hour = 3;
-- ALTER TABLE Employees DISABLE TRIGGER resigned_employee_cleanup_trigger;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 1 OR id = 4;
-- ALTER TABLE Employees ENABLE TRIGGER resigned_employee_cleanup_trigger;
-- TEST
ALTER TABLE Bookings DISABLE TRIGGER check_resignation_booking_create_approve_trigger;
UPDATE Bookings SET approver_id = NULL WHERE floor = 1 AND room = 1 AND start_hour = 1;
UPDATE Bookings SET approver_id = 2 WHERE floor = 1 AND room = 1 AND start_hour = 2;
UPDATE Bookings SET creator_id = 2 WHERE floor = 1 AND room = 1 AND start_hour = 3;
ALTER TABLE Bookings ENABLE TRIGGER check_resignation_booking_create_approve_trigger;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, 2), (1, 1, CURRENT_DATE + 1, 2, 1, 3), (1, 1, CURRENT_DATE + 1, 3, 1, 4)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST check_meeting_room_updates_trigger_insert_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE + 1, 1);
COMMIT;
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (1, 1, 'Room 1', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST check_meeting_room_updates_trigger_update_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE + 1, 1);
COMMIT;
-- TEST
BEGIN TRANSACTION;
UPDATE MeetingRooms SET floor = 2, room = 2 WHERE floor = 1 AND room = 1;
COMMIT;
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (2, 2, 'Room 1', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 2, 2, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST check_meeting_room_updates_trigger_insert_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
COMMIT;
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns NULL
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;
