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
    'SELECT * FROM contact_tracing(33);' -> 
    Senior 33 bookings from day D to day D+7 are removed, junior 4 and senior 33 attendance from day D to day D+7 are removed.
    Senior 33 bookings and attends past D+7 days are removed, bookings and attends of senior 34 are not removed past D+7
*/
INSERT INTO Departments VALUES
(3, 'Department 3', NULL);

INSERT INTO Employees VALUES
(33, 'Senior 33', 'Contact 33', 'senior33@company.com', NULL, 3),
(34, 'Senior 34', 'Contact 34', 'senior34@company.com', NULL, 3),
(63, 'Manager 63', 'Contact 63', 'manager63@company.com', NULL, 3);

INSERT INTO Superiors VALUES
(33), (34), (63);

INSERT INTO Seniors VALUES
(33), (34);

INSERT INTO Managers VALUES
(63);

INSERT INTO MeetingRooms VALUES
(1, 3, 'Room 1-3', 3);

INSERT INTO Updates VALUES
(63, 1, 3, CURRENT_DATE - 4, 5);

INSERT INTO HealthDeclarations VALUES
(33, CURRENT_DATE, 37.6),
(34, CURRENT_DATE, 37.0);

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
(1, 3, CURRENT_DATE + 7, 1, 33, 63),
(1, 3, CURRENT_DATE + 8, 1, 33, 63),
(1, 3, CURRENT_DATE + 8, 2, 34, 63);

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
(33, 1, 3, CURRENT_DATE + 8, 1),
(34, 1, 3, CURRENT_DATE + 8, 2),
-- Insert participants
(34, 1, 3, CURRENT_DATE - 3, 1),
(34, 1, 3, CURRENT_DATE - 2, 1),
(34, 1, 3, CURRENT_DATE - 1, 1),
(34, 1, 3, CURRENT_DATE, 1),
(34, 1, 3, CURRENT_DATE + 1, 1),
(34, 1, 3, CURRENT_DATE + 2, 1),
(34, 1, 3, CURRENT_DATE + 3, 1),
(34, 1, 3, CURRENT_DATE + 4, 1),
(34, 1, 3, CURRENT_DATE + 5, 1),
(34, 1, 3, CURRENT_DATE + 6, 1),
(34, 1, 3, CURRENT_DATE + 7, 1),
(34, 1, 3, CURRENT_DATE + 8, 1);

-- contact_tracing
-- Employees in the same unapproved booking as an employee with fever do not get removed from their future Bookings or Attends
/* 
    'SELECT * FROM contact_tracing(35);' -> Senior 36 future bookings and attends are not removed.
*/
INSERT INTO Departments VALUES
(4, 'Department 4', NULL);

INSERT INTO Employees VALUES
(35, 'Senior 35', 'Contact 35', 'senior35@company.com', NULL, 4),
(36, 'Senior 36', 'Contact 36', 'senior36@company.com', NULL, 4),
(64, 'Manager 64', 'Contact 64', 'manager64@company.com', NULL, 4);

INSERT INTO Superiors VALUES
(35), (36), (64);

INSERT INTO Seniors VALUES
(35), (36);

INSERT INTO Managers VALUES
(64);

INSERT INTO MeetingRooms VALUES
(1, 4, 'Room 1-4', 4);

INSERT INTO Updates VALUES
(64, 1, 4, CURRENT_DATE - 4, 5);

INSERT INTO HealthDeclarations VALUES
(35, CURRENT_DATE, 37.6),
(36, CURRENT_DATE, 37.0);

INSERT INTO Bookings VALUES
(1, 4, CURRENT_DATE + 1, 1, 35, NULL),
(1, 4, CURRENT_DATE + 2, 1, 36, 64),
(1, 4, CURRENT_DATE + 3, 1, 36, 64);

INSERT INTO Attends VALUES
-- Insert creators
(35, 1, 4, CURRENT_DATE + 1, 1),
(36, 1, 4, CURRENT_DATE + 2, 1),
(36, 1, 4, CURRENT_DATE + 3, 1),
-- Insert participants
(36, 1, 4, CURRENT_DATE + 1, 1);

-- change_capacity
-- This routine is used to change the capacity of the room.
/*
    'CALL change_capacity(1, 5, 2, 65, CURRENT_DATE);' -> Changes room capacity of 'Room 1-5' from 4 to 2, bookings with more/less than 2 people attending are deleted
*/
INSERT INTO Departments VALUES
(5, 'Department 5', NULL);

INSERT INTO Employees VALUES
(4, 'Junior 4', 'Contact 4', 'junior4@company.com', NULL, 5),
(5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 5),
(6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 5),
(65, 'Manager 65', 'Contact 65', 'manager65@company.com', NULL, 5),
(66, 'Manager 66', 'Contact 66', 'manager66@company.com', NULL, 5);

INSERT INTO Juniors VALUES
(4), (5), (6);

INSERT INTO Superiors VALUES
(65), (66);

INSERT INTO Managers VALUES
(65), (66);

INSERT INTO MeetingRooms VALUES
(1, 5, 'Room 1-5', 5);

INSERT INTO Updates VALUES
(65, 1, 5, CURRENT_DATE, 4);

INSERT INTO Bookings VALUES
(1, 5, CURRENT_DATE + 1, 1, 65, 66),
(1, 5, CURRENT_DATE + 1, 2, 65, 66),
(1, 5, CURRENT_DATE + 1, 3, 65, 66),
(1, 5, CURRENT_DATE + 1, 4, 65, 66);

INSERT INTO Attends VALUES
-- Insert creators
(65, 1, 5, CURRENT_DATE + 1, 1),
(65, 1, 5, CURRENT_DATE + 1, 2),
(65, 1, 5, CURRENT_DATE + 1, 3),
(65, 1, 5, CURRENT_DATE + 1, 4),
-- Insert participants
(4, 1, 5, CURRENT_DATE + 1, 1),
(5, 1, 5, CURRENT_DATE + 1, 1),
(6, 1, 5, CURRENT_DATE + 1, 1),
(4, 1, 5, CURRENT_DATE + 1, 2),
(5, 1, 5, CURRENT_DATE + 1, 2),
(4, 1, 5, CURRENT_DATE + 1, 3);

-- Resignation
-- they are no longer allowed to book or approve any meetings rooms.
/*
    'INSERT INTO Bookings VALUES (1, 5, CURRENT_DATE + 1, 1, 69, NULL);' -> Resigned manager 69 unable to book meeting room
    'INSERT INTO Bookings VALUES (1, 5, CURRENT_DATE + 1, 1, 65, 69);' -> Resigned manager 69 unable to approve meeting room
    'INSERT INTO Updates VALUES (69, 1, 5, CURRENT_DATE + 1, 10);' -> Resigned manager 69 unable to update room capacity
    'INSERT INTO Attends VALUES (69, 1, 5, CURRENT_DATE, 1);' -> Resigned manager 69 unable to join meeting
    'INSERT INTO HealthDeclarations VALUES (69, CURRENT_DATE, 37.0);' -> Resigned manager 69 unable to declare temperature
*/
INSERT INTO Departments VALUES
(6, 'Department 6', NULL);

INSERT INTO Employees VALUES
(67, 'Manager 67', 'Contact 67', 'manager67@company.com', NULL, 6),
(68, 'Manager 68', 'Contact 68', 'manager68@company.com', NULL, 6),
(69, 'Manager 69', 'Contact 69', 'manager69@company.com', CURRENT_DATE, 6);

INSERT INTO Superiors VALUES
(67), (68), (69);

INSERT INTO Managers VALUES
(67), (68), (69);

INSERT INTO MeetingRooms VALUES
(1, 6, 'Room 1-6', 6);

INSERT INTO Updates VALUES
(67, 1, 6, CURRENT_DATE, 5);

INSERT INTO Bookings VALUES
(1, 6, CURRENT_DATE, 1, 67, 68);

INSERT INTO Attends VALUES
-- Insert creators
(67, 1, 6, CURRENT_DATE, 1);

-- Resignation
-- Additionally, any future records (e.g., future meetings) are removed.
/*
    'CALL remove_employee(70, CURRENT_DATE);' -> Future bookings, attendances, healthdeclarations and approvals >= resignation_date of resigned manager 70 are removed
*/
INSERT INTO Departments VALUES
(7, 'Department 7', NULL);

INSERT INTO Employees VALUES
(70, 'Manager 70', 'Contact 70', 'manager70@company.com', NULL, 7),
(71, 'Manager 71', 'Contact 71', 'manager71@company.com', NULL, 7);

INSERT INTO Superiors VALUES
(70), (71);

INSERT INTO Managers VALUES
(70), (71);

INSERT INTO MeetingRooms VALUES
(1, 7, 'Room 1-7', 7);

INSERT INTO Updates VALUES
(70, 1, 7, CURRENT_DATE, 5);

INSERT INTO HealthDeclarations VALUES 
(70, CURRENT_DATE, 37.0),
(70, CURRENT_DATE + 1, 37.0),
(70, CURRENT_DATE + 2, 37.0),
(70, CURRENT_DATE + 3, 37.0),
(70, CURRENT_DATE + 4, 37.0),
(70, CURRENT_DATE + 5, 37.0);

INSERT INTO Bookings VALUES
(1, 7, CURRENT_DATE + 1, 1, 70, 71),
(1, 7, CURRENT_DATE + 2, 1, 70, 71),
(1, 7, CURRENT_DATE + 3, 1, 70, 71),
(1, 7, CURRENT_DATE + 4, 1, 70, 71),
(1, 7, CURRENT_DATE + 5, 1, 70, 71),
(1, 7, CURRENT_DATE + 1, 2, 71, 70),
(1, 7, CURRENT_DATE + 2, 2, 71, 70),
(1, 7, CURRENT_DATE + 3, 2, 71, 70),
(1, 7, CURRENT_DATE + 4, 2, 71, 70),
(1, 7, CURRENT_DATE + 5, 2, 71, 70);

INSERT INTO Attends VALUES
-- Insert creators
(70, 1, 7, CURRENT_DATE + 1, 1),
(70, 1, 7, CURRENT_DATE + 2, 1),
(70, 1, 7, CURRENT_DATE + 3, 1),
(70, 1, 7, CURRENT_DATE + 4, 1),
(70, 1, 7, CURRENT_DATE + 5, 1),
(71, 1, 7, CURRENT_DATE + 1, 2),
(71, 1, 7, CURRENT_DATE + 2, 2),
(71, 1, 7, CURRENT_DATE + 3, 2),
(71, 1, 7, CURRENT_DATE + 4, 2),
(71, 1, 7, CURRENT_DATE + 5, 2);

-- Add more dummy data to fulfil minimum 10 records requirement, and generate some new tuples to isolate dummy data for tables requiring foreign key
INSERT INTO Departments VALUES
(8, 'Department 8', NULL),
(9, 'Department 9', NULL),
(10, 'Department 10', NULL);

INSERT INTO MeetingRooms VALUES
(1, 8, 'Room 1-8', 8),
(1, 9, 'Room 1-9', 8),
(1, 10, 'Room 1-10', 8);

INSERT INTO Employees VALUES
(7, 'Junior 7', 'Contact 7', 'junior7@company.com', NULL, 8),
(8, 'Junior 8', 'Contact 8', 'junior8@company.com', NULL, 8),
(9, 'Junior 9', 'Contact 9', 'junior9@company.com', NULL, 8),
(10, 'Junior 10', 'Contact 10', 'junior10@company.com', NULL, 8),
(37, 'Senior 37', 'Contact 37', 'senior37@company.com', NULL, 8),
(38, 'Senior 38', 'Contact 38', 'senior38@company.com', NULL, 8),
(39, 'Senior 39', 'Contact 39', 'senior39@company.com', NULL, 8),
(40, 'Senior 40', 'Contact 40', 'senior40@company.com', NULL, 8),
(72, 'Manager 72', 'Contact 72', 'manager72@company.com', NULL, 8);

INSERT INTO Juniors VALUES
(7), (8), (9), (10);

INSERT INTO Superiors VALUES
(37), (38), (39), (40), (72);

INSERT INTO Seniors VALUES
(37), (38), (39), (40);

INSERT INTO Managers VALUES
(72);

INSERT INTO Updates VALUES
(72, 1, 8, CURRENT_DATE, 0),
(72, 1, 8, CURRENT_DATE + 1, 0),
(72, 1, 8, CURRENT_DATE + 2, 0);