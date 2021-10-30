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

-- TEST trigger E5 non overlapping Juniors, Seniors, Managers
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
-- insert a manager into Juniors
INSERT INTO Juniors VALUES (1); -- Failure, employee is already a Superior
-- insert a senior into Juniors
INSERT INTO Juniors VALUES (5); -- Failure, employee is already a Superior
-- insert a manager into Seniors
INSERT INTO Seniors VALUES (1); -- Failure, employee is already a Manager
-- insert a junior into Seniors
INSERT INTO Seniors VALUES (6); -- Failure, employee is not a Superior (Schema)
-- insert a senior into Managers
INSERT INTO Managers VALUES (5); -- Failure, employee is already a Senior
-- insert a junior into Managers
INSERT INTO Managers VALUES (6); -- Failure, employee is not a Superior (Schema)

-- insert an employee, without insertion into Junior, Senior, Manager
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (2, 'Err 2', 'contact 2', 'err2@company.com', NULL, 1);
COMMIT; -- Failure, employee must exist either as junior, senior or manager

-- insert an employee into Superiors only, not into Senior or Manager
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (3, 'Err Superior 3', 'contact 3', 'err3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (3);
COMMIT; -- Failure, employee must exists either as senior or manager once a superior

-- update a Superior into an already taken Junior id
UPDATE Superiors SET id = 6 WHERE id = 1; -- Failure, employee id=6 is already a Junior
-- update a Junior into an already taken id
UPDATE Juniors SET id = 1 WHERE id = 6; -- Failure, employee id=1 is already a Superior
-- update a Manager into an already taken id
UPDATE Managers SET id = 6 WHERE id = 1; -- Failure, employee id=6 is not in Superior (Schema)
-- update a Senior into an already taken id
UPDATE Seniors SET id = 1 WHERE id = 5; -- Failure, employee id=1 is already a Manager

-- only delete a junior
DELETE FROM Juniors WHERE id = 6; -- Failure, Junior is not re-inserted as a Junior/Superior
-- delete a junior then insert into superior
BEGIN TRANSACTION;
DELETE FROM Juniors WHERE id = 6;
INSERT INTO Superiors VALUES (6);
END; -- Failure, employee must exist either as Manager or Senior once a Superior
-- delete a junior, insert into junior again
BEGIN TRANSACTION;
DELETE FROM Juniors WHERE id = 6;
INSERT INTO Juniors VALUES (6);
END; -- Success
-- delete a junior, insert into superior, insert into manager
BEGIN TRANSACTION;
DELETE FROM Juniors WHERE id = 6;
INSERT INTO Superiors VALUES (6);
INSERT INTO Managers VALUES (6);
END; -- Success

-- only delete a superior
DELETE FROM Superiors WHERE id = 6; -- Failure, Superior is not re-inserted as a Junior/Superior
-- delete a Superior, insert into Superior (Manager) again
BEGIN TRANSACTION;
DELETE FROM Superiors WHERE id = 6;
INSERT INTO Superiors VALUES (6);
INSERT INTO Managers VALUES (6);
END; -- Success
-- delete a superior then insert into junior
BEGIN TRANSACTION;
DELETE FROM Superiors WHERE id = 6;
INSERT INTO Juniors VALUES (6);
END; -- Success

-- only delete a senior
DELETE FROM Seniors WHERE id = 5; -- Failure, Senior is not re-inserted as Junior/Superior
--delete a senior, then insert into Senior again
BEGIN TRANSACTION;
DELETE FROM Seniors WHERE id = 5;
INSERT INTO Seniors VALUES (5);
END; -- Success
--delete a senior, then insert into manager
BEGIN TRANSACTION;
DELETE FROM Seniors WHERE id = 5;
INSERT INTO Managers VALUES (5);
END; -- Success

-- only delete a manager
DELETE FROM Managers WHERE id = 1; -- Failure, Manager is not re-inserted as Junior/Superior
-- delete a manager, then insert into Manager again
BEGIN TRANSACTION;
DELETE FROM Managers WHERE id = 1;
INSERT INTO Managers VALUES (1);
END; -- Success
-- delete a manager then insert into senior
BEGIN TRANSACTION;
DELETE FROM Managers WHERE id = 1;
INSERT INTO Seniors VALUES (1);
END; -- Success

-- AFTER TEST
CALL reset();
-- END TEST

-- TEST A4 no changes to attendance in already approved bookings
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Resigned today Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1),
    (7, 'Resigned yesterday Junior 7', 'Contact 7', 'junior7@company.com', NULL, 1),
    (8, 'Resigned tomorrow Junior 8', 'Contact 8', 'junior8@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2);
INSERT INTO Juniors VALUES (6), (7), (8);
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
    (1, 3, 101, CURRENT_DATE, 10),
    (1, 3, 101, CURRENT_DATE, 15),
    (5, 3, 101, CURRENT_DATE, 10),
    (6, 3, 101, CURRENT_DATE, 15),
    (7, 3, 101, CURRENT_DATE, 15),
    (8, 3, 101, CURRENT_DATE, 15);
UPDATE Bookings SET approver_id = 1 WHERE 
    floor = 3 AND room = 101 AND date = CURRENT_DATE AND start_hour = 15;
-- TEST
-- insert an employee into an already approved booking
INSERT INTO Attends VALUES (5, 3, 101, CURRENT_DATE, 15); -- Failure, booking for this room has been approved

-- update an employee's attendance in an already approved booking
UPDATE Attends SET employee_id = 5 WHERE employee_id = 1 AND start_hour = 15; -- Failure, previous booking for this room has been approved
-- delete an employee's attendance in an already approved booking
DELETE FROM Attends WHERE employee_id = 1 AND start_hour = 15; -- Failure, booking for this room has been approved

-- update an employee's attendance in a not-approved booking, into an already-approved booking
UPDATE Attends SET start_hour = 15 WHERE employee_id = 5; -- Failure, the incoming booking has already been approved

-- delete an employee's attendance when he has resigned today
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 6;
DELETE FROM Attends WHERE employee_id = 6; -- Success

-- delete an employee's attendance when he has resigned yesterday
UPDATE Employees SET resignation_date = CURRENT_DATE - 1 WHERE id = 7;
DELETE FROM Attends WHERE employee_id = 7; -- Success

-- delete an employee's attendance when he resigns tomorrow
UPDATE Employees SET resignation_date = CURRENT_DATE + 1 WHERE id = 8;
DELETE FROM Attends WHERE employee_id = 8; -- Failure, employee should still attend the already approved meeting

-- AFTER TEST
CALL reset();
-- END TEST

-- TEST C1 Only managers in same department have permissions to change capacity
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
-- allow a manager from another department to update the room's capacity
INSERT INTO Updates VALUES (3, 3, 101, CURRENT_DATE, 10); -- Failure, manager does not have perms to change capacity
-- allow a manager from the same department to update the room's capacity
INSERT INTO Updates VALUES (1, 3, 101, CURRENT_DATE, 10); -- Success
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST C4 Meeting room can only have Updates not in the past (present and future only)
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
INSERT INTO MeetingRooms VALUES (3, 101, '3rd floor, room 101, Dept 1', 1);
-- TEST
-- Update capacity yesterday 
INSERT INTO Updates VALUES (1, 3, 101, CURRENT_DATE - 1, 10); -- Failure, meeting room capacity cannot be changed in the past
-- Update capacity today 
INSERT INTO Updates VALUES (1, 3, 101, CURRENT_DATE, 10); -- Success
-- Update capacity tomorrow
INSERT INTO Updates VALUES (1, 3, 101, CURRENT_DATE + 1, 10); -- Success
-- AFTER TEST
CALL reset();
-- END TEST

/**********************************************************************************
* B-12 When an employee resigns, they are no longer allowed to book any meetings. *
***********************************************************************************/

-- TEST Insert Success
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

-- TEST Update Success
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

-- TEST trigger 34 Insert Failure
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
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, NULL); -- Success
UPDATE Bookings SET approver_id = 4 WHERE start_hour = 1; -- Success
UPDATE Bookings SET creator_id = 3 WHERE creator_id = 1; -- Failure
UPDATE Bookings SET approver_id = 6 WHERE approver_id = 4; -- Failure
UPDATE Bookings SET creator_id = 3, approver_id = 6 WHERE creator_id = 1; -- Failure
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

/*************************************************************************************
* B-13 When an employee resigns, they are no longer allowed to approve any meetings. *
*************************************************************************************/

/****************************************************************************************
* A-5 When an employee resigns, they are no longer allowed to join any booked meetings. *
****************************************************************************************/

-- TEST Insert Success
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
INSERT INTO Attends VALUES(2, 1, 1, CURRENT_DATE + 1, 1);
SELECT * FROM Attends ORDER BY date, start_hour, floor, room; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (2, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Insert Resigned Failure
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 2;
-- TEST
INSERT INTO Attends VALUES(2, 1, 1, CURRENT_DATE + 1, 1); -- Exception
SELECT * FROM Attends ORDER BY date, start_hour, floor, room; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Update Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Senior 3', 'Contact 3', 'senior3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Attends VALUES(2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
UPDATE Attends SET employee_id = 3 WHERE employee_id = 2;
SELECT * FROM Attends ORDER BY date, start_hour, floor, room; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (3, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Update Resigned Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Senior 3', 'Contact 3', 'senior3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2), (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Attends VALUES(2, 1, 1, CURRENT_DATE + 1, 1);
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 3;
-- TEST
UPDATE Attends SET employee_id = 3 WHERE employee_id = 2; -- Exception
SELECT * FROM Attends ORDER BY date, start_hour, floor, room; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (2, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- TEST END

/************************************************************************************************
* C-3 When an employee resigns, they are no longer allowed to change any meeting room capacities.
************************************************************************************************/

-- TEST Insert Success
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

-- TEST Insert Resigned Failure
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

-- TEST Update Success
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

-- TEST Update Resigned Failure
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
UPDATE Bookings SET approver_id = 2; -- Failure
UPDATE Bookings SET approver_id = 1; -- Success
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 2, 1, NULL); -- Success
UPDATE Bookings SET approver_id = 1 WHERE start_hour = 2; -- Success
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 3, 1, 2); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

/********************************************************************************************
* H-6 When an employee resigns, they are no longer allowed to make any health declarations. *
********************************************************************************************/

-- TEST Insert Success
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

-- TEST Insert Resigned Failure
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

-- TEST Update Success
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

-- TEST Update Resigned Failure
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

-- TEST insert_meeting_creator_trigger_insert_success
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
SELECT * FROM Attends; -- Expects (1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST insert_meeting_creator_trigger_update_success
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
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
INSERT INTO Attends VALUES
    (3, 1, 1, CURRENT_DATE + 1, 2);
-- TEST
UPDATE Bookings SET creator_id = 2 WHERE start_hour = 1;
UPDATE Bookings SET creator_id = 3 WHERE start_hour = 2;
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Expects (2, 1, 1, CURRENT_DATE + 1, 1), (3, 1, 1, CURRENT_DATE + 1, 2)
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

-- TEST Trigger B-9: approval_for_future_meetings_only_allow_future_meeting_bookings
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 1);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 2, NULL);
UPDATE Bookings SET approver_id = 1 WHERE ROW (floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 1); -- SUCCESS
SELECT COUNT(*) from Bookings WHERE approver_id IS NOT NULL; -- Expected: 1
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST approval_for_future_meetings_past_meetings_failure 
CALL reset();
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 1);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 1, 2, NULL);
UPDATE Bookings SET approver_id = 1 WHERE ROW (floor, room, date, start_hour) = (1, 1, CURRENT_DATE - 1, 1); -- RAISE EXCEPTION: Cannot approve or update meetings of the past
SELECT COUNT(*) from Bookings WHERE approver_id IS NOT NULL; -- Expected: 0
-- AFTER TEST
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
CALL reset();
-- END TEST

-- TEST employee_join_only_future_meetings_trigger_success
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 2);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 2, NULL);
INSERT INTO Attends VALUES (1, 1, 1, CURRENT_DATE + 1, 1); -- Should pass
SELECT COUNT(*) from Attends; -- Expected: 2
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST employee_join_only_future_meetings_trigger_failure
-- BEFORE TEST
CALL reset();
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 1);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 1, 2, NULL); -- EXCEPTION RAISE: Cannot join meetings in the past
SELECT COUNT(*) from Attends; -- Expected: 0
-- AFTER TEST
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
CALL reset();
-- END TEST

-- TEST check_future_meetings_on_capacity_change_trigger_success
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 1),
    (4, 'Junior 4', 'Contact 4', 'junior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
INSERT INTO Juniors VALUES (3), (4), (5);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 3, 8);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 2, NULL);
-- TEST
INSERT INTO Attends VALUES (1, 1, 1, CURRENT_DATE + 1, 1);
INSERT INTO Attends VALUES (3, 1, 1, CURRENT_DATE + 1, 1);
INSERT INTO Attends VALUES (4, 1, 1, CURRENT_DATE + 1, 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 2, 4);
SELECT COUNT(*) from Bookings; -- Expected: 1
SELECT COUNT(*) from Attends; -- Expected: 4
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 2);
SELECT COUNT(*) from Bookings; -- Expected: 0
SELECT COUNT(*) from Attends; -- Expected: 0
-- AFTER TEST
CALL reset();
-- END TEST


-- TEST check_meeting_capacity_trigger_insert
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 1),
    (4, 'Junior 4', 'Contact 4', 'junior4@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
INSERT INTO Juniors VALUES (3), (4);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 3);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 2, NULL);
INSERT INTO Attends VALUES (1, 1, 1, CURRENT_DATE + 1, 1);
INSERT INTO Attends VALUES (3, 1, 1, CURRENT_DATE + 1, 1);
INSERT INTO Attends VALUES (4, 1, 1, CURRENT_DATE + 1, 1); -- RAISE EXCEPTION: Cannot attend booking due to meeting room capacity limit reached
SELECT COUNT(*) from Attends; -- Expected: 3
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST check_meeting_capacity_trigger_update
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 1),
    (4, 'Junior 4', 'Contact 4', 'junior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
INSERT INTO Juniors VALUES (3), (4), (5);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO MeetingRooms VALUES (1, 2, 'Room 2', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 3);
INSERT INTO Updates VALUES (1, 1, 2, CURRENT_DATE - 1, 3);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Bookings VALUES (1, 2, CURRENT_DATE + 1, 1, 2, NULL);
-- TEST
INSERT INTO Attends VALUES (3, 1, 1, CURRENT_DATE + 1, 1);
INSERT INTO Attends VALUES (4, 1, 1, CURRENT_DATE + 1, 1); 
INSERT INTO Attends VALUES (5, 1, 2, CURRENT_DATE + 1, 1); 
UPDATE Attends SET room = 1 WHERE ROW(floor, room) = (1, 2); -- RAISE EXCEPTION: Cannot attend booking due to meeting room capacity limit reached
SELECT * from Attends WHERE floor = 1 AND room = 1; -- Expected: (1, 1, 1, CURRENT_DATE + 1, 1), (3, 1, 1, CURRENT_DATE + 1, 1), (4, 1, 1, CURRENT_DATE + 1, 1)
SELECT * from Attends WHERE floor = 1 AND room = 2; -- Expected: (2, 1, 2, CURRENT_DATE + 1, 1), (5, 1, 2, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

/****************************************************************************
* E-11 When a department has been removed, employees cannot be added to it. *
****************************************************************************/

-- TEST Successful Insert
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', NULL), (2, 'Department 2', NULL);
-- TEST
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
SELECT * FROM Employees; -- Returns (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Successful Update
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', NULL), (2, 'Department 2', NULL);
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
UPDATE Departments SET removal_date = CURRENT_DATE WHERE id = 1;
-- TEST
UPDATE Employees SET department_id = 2 WHERE id = 1;
SELECT * FROM Employees; -- Returns (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 2)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert Failure 
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', NULL);
UPDATE Departments SET removal_date = CURRENT_DATE WHERE id = 1;
-- TEST
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
SELECT * FROM Employees; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', NULL), (2, 'Department 2', NULL);
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
UPDATE Departments SET removal_date = CURRENT_DATE WHERE id = 2;
-- TEST
UPDATE Employees SET department_id = 2 WHERE id = 1;
SELECT * FROM Employees; -- Returns (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1)
-- AFTER TEST
CALL reset();
-- END TEST

/********************************************************************************
* MR-5 When a department has been removed, meeting rooms cannot be added to it. *
********************************************************************************/

-- TEST Successful Insert
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', NULL);
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
SELECT * FROM MeetingRooms; -- Returns (1, 1, 'Room 1-1', 1);
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Successful Update
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', NULL), (2, 'Department 2', NULL);
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
UPDATE Departments SET removal_date = CURRENT_DATE WHERE id = 1;
-- TEST
UPDATE MeetingRooms SET department_id = 2 WHERE floor = 1 AND room = 1;
SELECT * FROM MeetingRooms; -- Returns (1, 1, 'Room 1-1', 2);
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert Failure 
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', NULL);
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
UPDATE Departments SET removal_date = CURRENT_DATE WHERE id = 1;
-- TEST
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
SELECT * FROM MeetingRooms; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', NULL), (2, 'Department 2', NULL);
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
UPDATE Departments SET removal_date = CURRENT_DATE WHERE id = 2;
-- TEST
UPDATE MeetingRooms SET department_id = 2 WHERE floor = 1 AND room = 1;
SELECT * FROM MeetingRooms; -- Returns (1, 1, 'Room 1-1', 1);
-- AFTER TEST
CALL reset();
-- END TEST

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;
