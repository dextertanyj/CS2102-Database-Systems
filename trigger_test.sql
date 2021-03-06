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

/***************************************************************************
* A-3 If an employee is having a fever, they cannot join a booked meeting. *
***************************************************************************/

-- TEST Insert With Declaration Success 
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
INSERT INTO HealthDeclarations VALUES 
    (1, CURRENT_DATE, 37.0);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
ALTER TABLE Bookings DISABLE TRIGGER insert_meeting_creator_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
ALTER TABLE Bookings ENABLE TRIGGER insert_meeting_creator_trigger;
-- TEST
INSERT INTO Attends VALUES (1, 1, 1, CURRENT_DATE + 1, 1);
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert No Declaration Success
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
INSERT INTO HealthDeclarations VALUES 
    (1, CURRENT_DATE, 37.0);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (2, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert Fever Failure 
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
INSERT INTO HealthDeclarations VALUES 
    (1, CURRENT_DATE, 37.0),
    (2, CURRENT_DATE, 37.6);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1); -- Failure
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update With Declaration Success 
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
INSERT INTO HealthDeclarations VALUES 
    (1, CURRENT_DATE, 37.0),
    (2, CURRENT_DATE, 37.0),
    (3, CURRENT_DATE, 37.5);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
UPDATE Attends SET employee_id = 3 WHERE employee_id = 2;
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (3, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update No Declaration Success 
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
INSERT INTO HealthDeclarations VALUES 
    (1, CURRENT_DATE, 37.0),
    (2, CURRENT_DATE, 37.0);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
UPDATE Attends SET employee_id = 3 WHERE employee_id = 2;
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (3, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Fever Failure 
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
INSERT INTO HealthDeclarations VALUES 
    (1, CURRENT_DATE, 37.0),
    (2, CURRENT_DATE, 37.0),
    (3, CURRENT_DATE, 37.6);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
UPDATE Attends SET employee_id = 3 WHERE employee_id = 2; -- Exception
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (2, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

/**********************************************************************************************************************************
* A-4 Once approved, there should be no more changes in the participants and the participants will definitely attend the meeting. *
**********************************************************************************************************************************/

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

/***************************************************************************************************
* C-1 A manager from the same department as the meeting room may change the meeting room capacity. *
***************************************************************************************************/

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

/************************************************************************************
* C-4 A meeting room can only have its capacity updated for a date not in the past. *
************************************************************************************/

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

/******************************************************************
* B-10 If an employee is having a fever, they cannot book a room. *
******************************************************************/

-- TEST Insert With Declaration Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.5);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL); -- Success
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert No Declaration Success
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL); -- Success
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert Fever Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update With Declaration Success
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
INSERT INTO HealthDeclarations VALUES
    (1, CURRENT_DATE, 37.5),
    (2, CURRENT_DATE, 37.5);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET creator_id = 2 WHERE creator_id = 1; -- Success
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 2, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update No Declaration Success 
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
INSERT INTO HealthDeclarations VALUES
    (1, CURRENT_DATE, 37.5);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET creator_id = 2 WHERE creator_id = 1; -- Success
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 2, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Fever Failure
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
INSERT INTO HealthDeclarations VALUES
    (1, CURRENT_DATE, 37.5),
    (2, CURRENT_DATE, 37.6);
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET creator_id = 2 WHERE creator_id = 1; -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
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
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Insert Resigned Failure
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 1;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
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
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET creator_id = 2 WHERE creator_id = 1;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 2, NULL)
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
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 2;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET creator_id = 2 WHERE creator_id = 1; -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

/*************************************************************************************
* B-13 When an employee resigns, they are no longer allowed to approve any meetings. *
*************************************************************************************/

-- TEST Insert Success
-- BEFORE TEST
CALL reset();
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
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
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, 2);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 2)
-- AFTER TEST
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
CALL reset();
-- TEST END

-- TEST Insert Resigned Failure
-- BEFORE TEST
CALL reset();
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
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
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 2;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, 2); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
CALL reset();
-- TEST END

-- TEST Update Success
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
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET approver_id = 2 WHERE approver_id IS NULL;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 2)
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
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 2;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET approver_id = 2 WHERE approver_id IS NULL; -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

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
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Insert Resigned Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 1;
-- TEST
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10); -- Exception
COMMIT;
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns NULL
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
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
UPDATE Updates SET manager_id = 2 WHERE manager_id = 1;
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (2, 1, 1, CURRENT_DATE, 10)
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
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 2;
-- TEST
UPDATE Updates SET manager_id = 2 WHERE manager_id = 1; -- Exception
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10)
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
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Seniors VALUES (1);
COMMIT;
-- TEST
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0);
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns (1, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Insert Resigned Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Seniors VALUES (1);
COMMIT;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 1;
-- TEST
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0); -- Exception
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns NULL
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
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Seniors VALUES (1), (2);
COMMIT;
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0);
-- TEST
Update HealthDeclarations SET id = 2 WHERE id = 1;
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns (2, CURRENT_DATE, 37.0)
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
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Seniors VALUES (1), (2);
COMMIT;
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0);
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 2;
-- TEST
Update HealthDeclarations SET id = 2 WHERE id = 1;
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns (1, CURRENT_DATE, 37.0)
-- AFTER TEST
CALL reset();
-- TEST END

/**************************************************************************
* B-5 The employee booking the room immediately joins the booked meeting. *
**************************************************************************/

-- TEST Insert Success
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
SELECT * FROM Attends; -- Returns (1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Success
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
INSERT INTO Attends VALUES
    (3, 1, 1, CURRENT_DATE + 1, 2);
-- TEST
UPDATE Bookings SET creator_id = 2 WHERE start_hour = 1;
UPDATE Bookings SET creator_id = 3 WHERE start_hour = 2;
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (2, 1, 1, CURRENT_DATE + 1, 1), (3, 1, 1, CURRENT_DATE + 1, 2)
-- AFTER TEST
CALL reset();
-- END TEST

/**************************************************
* B-15 A meeting must be attended by its creator. *
**************************************************/

-- TEST Delete Other Attendee Success
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
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
INSERT INTO Attends VALUES (2, 1, 1, CURRENT_DATE + 1, 1);
-- TEST
DELETE FROM Attends WHERE employee_id = 2;
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Delete Creator Failure
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
DELETE FROM Attends WHERE employee_id = 1; -- Exception
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Creator Attendance Failure
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
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 2, NULL);
-- TEST
UPDATE Attends SET start_hour = 2 WHERE employee_id = 1; -- Exception
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (2, 1, 1, CURRENT_DATE + 1, 2)
-- AFTER TEST
CALL reset();
-- END TEST

/*********************************************************************************************************************
* B-7 A manager can only approve a booked meeting if the meeting room used is in the same department as the manager. *
*********************************************************************************************************************/

-- TEST Insert Success
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, 1);
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Success
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET approver_id = 1;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert Different Department Failure
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 3, 1, 2); -- Exception
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Different Department Failure
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
-- TEST
UPDATE Bookings SET approver_id = 2; -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

/******************************************************
* B-4 A booking can only be made for future meetings. *
******************************************************/

-- TEST Insert Success
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE, CURRENT_HOUR + 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Success
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
-- TEST
UPDATE Bookings SET date = CURRENT_DATE, start_hour = extract(HOUR FROM CURRENT_TIME) + 1 WHERE date = CURRENT_DATE + 1 AND start_hour = 1;
UPDATE Bookings SET date = CURRENT_DATE + 2 WHERE date = CURRENT_DATE + 1 AND start_hour = 2;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE, CURRENT_HOUR + 1, 1, NULL), (1, 1, CURRENT_DATE + 2, 2, 1, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert Past Failure
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL); -- Exception
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Past Failure
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL);
-- TEST
UPDATE Bookings SET date = CURRENT_DATE, start_hour = extract(HOUR FROM CURRENT_TIME) - 1 WHERE date = CURRENT_DATE + 1 AND start_hour = 1; -- Exception
UPDATE Bookings SET date = CURRENT_DATE - 1, start_hour = extract(HOUR FROM CURRENT_TIME) + 1 WHERE date = CURRENT_DATE + 1 AND start_hour = 2; -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, NULL)
-- AFTER TEST
CALL reset();
-- END TEST

/***************************************************************************************************************************
* B-14 A approved booked meeting can no longer have any of its details changed, except for the revocation of its approver. *
***************************************************************************************************************************/

-- TEST Update Success
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
-- ALTER TABLE Employees DISABLE TRIGGER handle_resignation_trigger;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 2;
-- ALTER TABLE Employees ENABLE TRIGGER handle_resignation_trigger;
-- TEST
UPDATE Bookings SET approver_id = NULL WHERE floor = 1 AND room = 1 AND start_hour = 1;
UPDATE Bookings SET approver_id = 1 WHERE floor = 1 AND room = 1 AND start_hour = 2;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Not Resigned Failure
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
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL), -- Approver resigned
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL); -- Approver resigned
UPDATE Bookings SET approver_id = 2 WHERE floor = 1 AND room = 1 AND start_hour = 1;
UPDATE Bookings SET approver_id = 3 WHERE floor = 1 AND room = 1 AND start_hour = 2;
UPDATE Bookings SET approver_id = 4 WHERE floor = 1 AND room = 1 AND start_hour = 3;
-- ALTER TABLE Employees DISABLE TRIGGER handle_resignation_trigger;
UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 1 OR id = 4;
-- ALTER TABLE Employees ENABLE TRIGGER handle_resignation_trigger;
-- TEST
ALTER TABLE Bookings DISABLE TRIGGER check_resignation_booking_create_approve_trigger;
UPDATE Bookings SET approver_id = NULL WHERE floor = 1 AND room = 1 AND start_hour = 1; -- Exception
UPDATE Bookings SET approver_id = 2 WHERE floor = 1 AND room = 1 AND start_hour = 2; -- Exception
UPDATE Bookings SET creator_id = 2 WHERE floor = 1 AND room = 1 AND start_hour = 3; -- Exception
ALTER TABLE Bookings ENABLE TRIGGER check_resignation_booking_create_approve_trigger;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, 2), (1, 1, CURRENT_DATE + 1, 2, 1, 3), (1, 1, CURRENT_DATE + 1, 3, 1, 4)
-- AFTER TEST
CALL reset();
-- END TEST

/***************************************************************************
* MR-4 Each meeting room must have at least one relevant capacities entry. *
***************************************************************************/

-- TEST Insert Success
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
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE + 1, 1);
COMMIT;
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (1, 1, 'Room 1-1', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Success
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE + 1, 1);
COMMIT;
-- TEST
UPDATE MeetingRooms SET floor = 2, room = 2, name = 'Room 2-2' WHERE floor = 1 AND room = 1;
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (2, 2, 'Room 2-2', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 2, 2, CURRENT_DATE + 1, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Insert No Capacity Entry Failure
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
COMMIT; -- Exception
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns NULL
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Update Capacities Failure
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
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (2, 2, 'Room 2-2', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 2, 2, CURRENT_DATE, 1);
COMMIT;
-- TEST
UPDATE Updates SET floor = 2, room = 2 WHERE floor = 1 AND room = 1;
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE + 1, 1), (1, 2, 2, CURRENT_DATE, 1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Delete Success
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE + 1, 1);
COMMIT;
-- TEST
DELETE FROM MeetingRooms WHERE floor = 1 AND room = 1;
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

/**************************************************************************
* B-8 A manager can only approve a booked meeting if it is in the future. *
**************************************************************************/

-- approval_for_future_meetings_only_allow_future_meeting_bookings
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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 2, 1);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 1, 2, NULL);
UPDATE Bookings SET approver_id = 1 WHERE ROW (floor, room, date, start_hour) = (1, 1, CURRENT_DATE - 1, 1); -- RAISE EXCEPTION: Approvals can only be given for future bookings.
SELECT COUNT(*) from Bookings WHERE approver_id IS NOT NULL; -- Expected: 0
-- AFTER TEST
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
CALL reset();
-- END TEST

/*************************************************
* A-2 An employee can only join future meetings. *
*************************************************/

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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 2, 1);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
COMMIT;
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 1, 2, NULL); -- EXCEPTION RAISE: Joining a meeting can only be done for future meetings.
SELECT COUNT(*) from Attends; -- Expected: 0
-- AFTER TEST
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
CALL reset();
-- END TEST

/********************************************************************************************************************
* C-2 If a meeting room has its capacity changed, all future meetings that exceed the new capacity will be removed. *
********************************************************************************************************************/

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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
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
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
CALL reset();
-- END TEST

/****************************************************************************************************
* A-6 The number of people attending a meeting should not exceed the latest past capacity declared. *
****************************************************************************************************/

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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 3);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO MeetingRooms VALUES (1, 2, 'Room 2', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 3);
INSERT INTO Updates VALUES (1, 1, 2, CURRENT_DATE - 1, 3);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;

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

-- TEST Insert Success
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

-- TEST Update Success
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
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1); -- Exception
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
UPDATE MeetingRooms SET department_id = 2 WHERE floor = 1 AND room = 1; -- Exception
SELECT * FROM MeetingRooms; -- Returns (1, 1, 'Room 1-1', 1);
-- AFTER TEST
CALL reset();
-- END TEST

/********************************************************************************************************************
* E-7 When an employee resigns, the employee is removed from all future meetings, approved or otherwise.            *
* E-8 When an employee resigns, the employee has all their future booked meetings cancelled, approved or otherwise. *
* E-9 When an employee resigns, all future approvals granted by the employee are revoked.                           *
********************************************************************************************************************/

-- TEST Success
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
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE - 3, 1, 1, NULL),
    (1, 1, CURRENT_DATE - 3, 2, 2, NULL),
    (1, 1, CURRENT_DATE - 3, 4, 2, NULL),
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL),
    (1, 1, CURRENT_DATE - 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE - 1, 3, 1, NULL),
    (1, 1, CURRENT_DATE - 1, 2, 2, NULL),
    (1, 1, CURRENT_DATE - 1, 4, 2, NULL),
    (1, 1, CURRENT_DATE - 1, 6, 2, NULL), -- Approved
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL), -- Removed
    (1, 1, CURRENT_DATE + 1, 2, 2, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL), -- Approved, Removed
    (1, 1, CURRENT_DATE + 1, 4, 2, NULL),
    (1, 1, CURRENT_DATE + 1, 6, 2, NULL); -- Approval removed
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE - 3, 2),
    (1, 1, 1, CURRENT_DATE - 3, 4), -- Approved
    (1, 1, 1, CURRENT_DATE - 1, 2), -- Removed
    (1, 1, 1, CURRENT_DATE - 1, 4), -- Approved, Removed
    (1, 1, 1, CURRENT_DATE + 1, 2), -- Removed
    (1, 1, 1, CURRENT_DATE + 1, 4); -- Approved, Removed
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
ALTER TABLE Bookings DISABLE TRIGGER approval_only_for_future_meetings_trigger;
UPDATE Bookings SET approver_id = 2 WHERE start_hour = 3 OR start_hour = 4;
UPDATE Bookings SET approver_id = 1 WHERE start_hour = 6;
ALTER TABLE Bookings ENABLE TRIGGER approval_only_for_future_meetings_trigger;
INSERT INTO HealthDeclarations VALUES
    (1, CURRENT_DATE - 3, 37.0),
    (1, CURRENT_DATE - 2, 37.0),
    (1, CURRENT_DATE - 1, 37.0),
    (1, CURRENT_DATE, 37.0),
    (1, CURRENT_DATE + 1, 37.0);
-- TEST
UPDATE Employees SET resignation_date = CURRENT_DATE - 2 WHERE id = 1;
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       | start_hour | creator_id | approver_id 
-------+------+------------------+------------+------------+-------------
     1 |    1 | CURRENT_DATE - 3 |          1 |          1 |            
     1 |    1 | CURRENT_DATE - 3 |          2 |          2 |            
     1 |    1 | CURRENT_DATE - 3 |          4 |          2 |           2
     1 |    1 | CURRENT_DATE - 2 |          1 |          1 |            
     1 |    1 | CURRENT_DATE - 1 |          2 |          2 |            
     1 |    1 | CURRENT_DATE - 1 |          4 |          2 |           2
     1 |    1 | CURRENT_DATE - 1 |          6 |          2 |           1
     1 |    1 | CURRENT_DATE + 1 |          2 |          2 |            
     1 |    1 | CURRENT_DATE + 1 |          4 |          2 |           2
     1 |    1 | CURRENT_DATE + 1 |          6 |          2 |            
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       | start_hour 
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE - 3 |          1
           1 |     1 |    1 | CURRENT_DATE - 3 |          2
           2 |     1 |    1 | CURRENT_DATE - 3 |          2
           1 |     1 |    1 | CURRENT_DATE - 3 |          4
           2 |     1 |    1 | CURRENT_DATE - 3 |          4
           1 |     1 |    1 | CURRENT_DATE - 2 |          1
           2 |     1 |    1 | CURRENT_DATE - 1 |          2
           2 |     1 |    1 | CURRENT_DATE - 1 |          4
           2 |     1 |    1 | CURRENT_DATE - 1 |          6
           2 |     1 |    1 | CURRENT_DATE + 1 |          2
           2 |     1 |    1 | CURRENT_DATE + 1 |          4
           2 |     1 |    1 | CURRENT_DATE + 1 |          6
*/
SELECT * FROM HealthDeclarations ORDER BY date, id;
/*
Returns:
 id |       date       | temperature 
----+------------------+-------------
  1 | CURRENT_DATE - 3 |        37.0
  1 | CURRENT_DATE - 2 |        37.0
*/
-- AFTER TEST
CALL reset();
-- END TEST

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;
