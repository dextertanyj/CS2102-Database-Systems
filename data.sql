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

-- contact_tracing
-- The employee is removed from all future meeting room booking, approved or not.
/* 
    'SELECT * FROM contact_tracing(1);' -> junior 1 remains in 'SELECT * FROM attends;'
    'SELECT * FROM contact_tracing(2);' -> junior 2 is removed from 'SELECT * FROM attends;'
*/
INSERT INTO Departments VALUES
(1, 'Department 1', NULL);

INSERT INTO Employees VALUES
(1, 'Junior 1', 'Contact 1', 'junior1@company.com', NULL, 1),
(2, 'Junior 2', 'Contact 2', 'junior2@company.com', NULL, 1),
(31, 'Senior 31', 'Contact 31', 'senior31@company.com', NULL, 1),
(61, 'Manager 61', 'Contact 61', 'manager61@company.com', NULL, 1);

INSERT INTO Juniors VALUES
(1), (2);

INSERT INTO Superiors VALUES
(31), (61);

INSERT INTO Seniors VALUES
(31);

INSERT INTO Managers VALUES
(61);

INSERT INTO MeetingRooms VALUES
(1, 1, 'Room 1-1', 1);

INSERT INTO Updates VALUES
(61, 1, 1, CURRENT_DATE, 5);

INSERT INTO HealthDeclarations VALUES 
(1, CURRENT_DATE, 37.0),
(2, CURRENT_DATE, 37.6),
(31, CURRENT_DATE, 37.0);

INSERT INTO Bookings VALUES
(1, 1, CURRENT_DATE + 1, 1, 31, 61);

INSERT INTO Attends VALUES
-- Insert creators
(31, 1, 1, CURRENT_DATE + 1, 1),
-- Insert participants
(1, 1, 1, CURRENT_DATE + 1, 1),
(2, 1, 1, CURRENT_DATE + 1, 1);

-- contact_tracing
-- If the employee is the one booking the room, the booking is cancelled, approved or not.
-- This employee cannot book a room until they are no longer having fever.
/* 
    'SELECT * FROM contact_tracing(32);' -> Booking for floor 1 room 2 @ start_hour = 1 is cancelled, junior 3 and senior 32 removed from attends
    'INSERT INTO Bookings VALUES (1, 2, CURRENT_DATE + 1, 1, 32, 62);' -> Senior 32 unable to book because he has a fever
*/
INSERT INTO Departments VALUES
(2, 'Department 2', NULL);

INSERT INTO Employees VALUES
(3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 2),
(32, 'Senior 32', 'Contact 32', 'senior32@company.com', NULL, 2),
(62, 'Manager 62', 'Contact 62', 'manager62@company.com', NULL, 2);

INSERT INTO Juniors VALUES
(3);

INSERT INTO Superiors VALUES
(32), (62);

INSERT INTO Seniors VALUES
(32);

INSERT INTO Managers VALUES
(62);

INSERT INTO MeetingRooms VALUES
(1, 2, 'Room 1-2', 2);

INSERT INTO Updates VALUES
(62, 1, 2, CURRENT_DATE, 5);

INSERT INTO HealthDeclarations VALUES
(3, CURRENT_DATE, 37.0),
(32, CURRENT_DATE, 37.6);

INSERT INTO Bookings VALUES
(1, 2, CURRENT_DATE + 1, 1, 32, 62);

INSERT INTO Attends VALUES
-- Insert creators
(32, 1, 2, CURRENT_DATE + 1, 1),
-- Insert participants
(3, 1, 2, CURRENT_DATE + 1, 1);

-- contact_tracing
-- All employees in the same approved meeting room from the past 3 (i.e., from day D-3 to day D) days are contacted.
-- These employees are removed from future meeting in the next 7 days (i.e., from day D to day D+7).
/* 
    'SELECT * FROM contact_tracing(33);' -> Senior 33 bookings from day D to day D+7 are removed, junior 4 and senior 33 attendance from day D to day D+7 are removed
*/
INSERT INTO Departments VALUES
(3, 'Department 3', NULL);

INSERT INTO Employees VALUES
(4, 'Junior 4', 'Contact 4', 'junior4@company.com', NULL, 3),
(33, 'Senior 33', 'Contact 33', 'senior33@company.com', NULL, 3),
(63, 'Manager 63', 'Contact 63', 'manager63@company.com', NULL, 3);

INSERT INTO Juniors VALUES
(4);

INSERT INTO Superiors VALUES
(33), (63);

INSERT INTO Seniors VALUES
(33);

INSERT INTO Managers VALUES
(63);

INSERT INTO MeetingRooms VALUES
(1, 3, 'Room 1-3', 3);

INSERT INTO Updates VALUES
(63, 1, 3, CURRENT_DATE - 4, 5);

INSERT INTO HealthDeclarations VALUES
(4, CURRENT_DATE, 37.0),
(33, CURRENT_DATE, 37.6);

INSERT INTO Bookings VALUES
(1, 3, CURRENT_DATE - 3, 1, 33, 63),
(1, 3, CURRENT_DATE - 2, 1, 33, 63),
(1, 3, CURRENT_DATE - 1, 1, 33, 63),
(1, 3, CURRENT_DATE, 1, 33, 63),
(1, 3, CURRENT_DATE + 1, 1, 33, 63),
(1, 3, CURRENT_DATE + 2, 1, 33, 63),
(1, 3, CURRENT_DATE + 3, 1, 33, 63),
(1, 3, CURRENT_DATE + 4, 1, 33, 63),
(1, 3, CURRENT_DATE + 5, 1, 33, 63),
(1, 3, CURRENT_DATE + 6, 1, 33, 63),
(1, 3, CURRENT_DATE + 7, 1, 33, 63);

INSERT INTO Attends VALUES
-- Insert creators
(33, 1, 3, CURRENT_DATE - 3, 1),
(33, 1, 3, CURRENT_DATE - 2, 1),
(33, 1, 3, CURRENT_DATE - 1, 1),
(33, 1, 3, CURRENT_DATE, 1),
(33, 1, 3, CURRENT_DATE + 1, 1),
(33, 1, 3, CURRENT_DATE + 2, 1),
(33, 1, 3, CURRENT_DATE + 3, 1),
(33, 1, 3, CURRENT_DATE + 4, 1),
(33, 1, 3, CURRENT_DATE + 5, 1),
(33, 1, 3, CURRENT_DATE + 6, 1),
(33, 1, 3, CURRENT_DATE + 7, 1),
-- Insert participants
(4, 1, 3, CURRENT_DATE - 3, 1),
(4, 1, 3, CURRENT_DATE - 2, 1),
(4, 1, 3, CURRENT_DATE - 1, 1),
(4, 1, 3, CURRENT_DATE, 1),
(4, 1, 3, CURRENT_DATE + 1, 1),
(4, 1, 3, CURRENT_DATE + 2, 1),
(4, 1, 3, CURRENT_DATE + 3, 1),
(4, 1, 3, CURRENT_DATE + 4, 1),
(4, 1, 3, CURRENT_DATE + 5, 1),
(4, 1, 3, CURRENT_DATE + 6, 1),
(4, 1, 3, CURRENT_DATE + 7, 1);

-- change_capacity
-- This routine is used to change the capacity of the room.
/*
    'CALL change_capacity(1, 4, 5, 64, CURRENT_DATE);' -> Changes room capacity of 'Room 1-4' from 0 to 5
*/
INSERT INTO Departments VALUES
(4, 'Department 4', NULL);

INSERT INTO Employees VALUES
(64, 'Manager 64', 'Contact 64', 'manager64@company.com', NULL, 4);

INSERT INTO Superiors VALUES
(64);

INSERT INTO Managers VALUES
(64);

INSERT INTO MeetingRooms VALUES
(1, 4, 'Room 1-4', 4);

INSERT INTO Updates VALUES
(64, 1, 4, CURRENT_DATE, 0);

-- Resignation
-- they are no longer allowed to book or approve any meetings rooms.
/*
    'INSERT INTO Bookings VALUES (1, 5, CURRENT_DATE + 1, 1, 67, NULL);' -> Resigned manager 67 unable to book meeting room
    'INSERT INTO Bookings VALUES (1, 5, CURRENT_DATE + 1, 1, 65, 67);' -> Resigned manager 67 unable to approve meeting room
    'INSERT INTO Updates VALUES (67, 1, 5, CURRENT_DATE + 1, 10);' -> Resigned manager 67 unable to update room capacity
    'INSERT INTO Attends VALUES (67, 1, 5, CURRENT_DATE, 1);' -> Resigned manager 67 unable to join meeting
    'INSERT INTO HealthDeclarations VALUES (67, CURRENT_DATE, 37.0);' -> Resigned manager 67 unable to declare temperature
*/
INSERT INTO Departments VALUES
(5, 'Department 5', NULL);

INSERT INTO Employees VALUES
(65, 'Manager 65', 'Contact 65', 'manager65@company.com', NULL, 5),
(66, 'Manager 66', 'Contact 66', 'manager66@company.com', NULL, 5),
(67, 'Manager 67', 'Contact 67', 'manager67@company.com', CURRENT_DATE, 5);

INSERT INTO Superiors VALUES
(65), (66), (67);

INSERT INTO Managers VALUES
(65), (66), (67);

INSERT INTO MeetingRooms VALUES
(1, 5, 'Room 1-5', 5);

INSERT INTO Updates VALUES
(65, 1, 5, CURRENT_DATE, 5);

INSERT INTO Bookings VALUES
(1, 5, CURRENT_DATE, 1, 65, 66);

INSERT INTO Attends VALUES
-- Insert creators
(65, 1, 5, CURRENT_DATE, 1);


-- Resignation
-- Additionally, any future records (e.g., future meetings) are removed.
/*
    'UPDATE Employees SET resignation_date = CURRENT_DATE WHERE id = 68;' -> Future bookings, attendances, and healthdeclarations >= resignation_date of resigned manager 68 are removed
*/
INSERT INTO Departments VALUES
(6, 'Department 6', NULL);

INSERT INTO Employees VALUES
(68, 'Manager 68', 'Contact 68', 'manager68@company.com', NULL, 6),
(69, 'Manager 69', 'Contact 69', 'manager69@company.com', NULL, 6);

INSERT INTO Superiors VALUES
(68), (69);

INSERT INTO Managers VALUES
(68), (69);

INSERT INTO MeetingRooms VALUES
(1, 6, 'Room 1-6', 6);

INSERT INTO Updates VALUES
(68, 1, 6, CURRENT_DATE, 5);

INSERT INTO HealthDeclarations VALUES 
(68, CURRENT_DATE, 37.0),
(68, CURRENT_DATE + 1, 37.0),
(68, CURRENT_DATE + 2, 37.0),
(68, CURRENT_DATE + 3, 37.0),
(68, CURRENT_DATE + 4, 37.0),
(68, CURRENT_DATE + 5, 37.0);

INSERT INTO Bookings VALUES
(1, 6, CURRENT_DATE + 1, 1, 68, 69),
(1, 6, CURRENT_DATE + 2, 1, 68, 69),
(1, 6, CURRENT_DATE + 3, 1, 68, 69),
(1, 6, CURRENT_DATE + 4, 1, 68, 69),
(1, 6, CURRENT_DATE + 5, 1, 68, 69);

INSERT INTO Attends VALUES
-- Insert creators
(68, 1, 6, CURRENT_DATE + 1, 1),
(68, 1, 6, CURRENT_DATE + 2, 1),
(68, 1, 6, CURRENT_DATE + 3, 1),
(68, 1, 6, CURRENT_DATE + 4, 1),
(68, 1, 6, CURRENT_DATE + 5, 1);