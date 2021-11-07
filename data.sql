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
(31, 'Senior 31', 'Contact 31', 'senior31@company.com', NULL, 1),
(32, 'Senior 32', 'Contact 32', 'senior32@company.com', NULL, 1),
(61, 'Manager 61', 'Contact 61', 'manager61@company.com', NULL, 1);

INSERT INTO Superiors VALUES
(31), (32), (61);

INSERT INTO Seniors VALUES
(31), (32);

INSERT INTO Managers VALUES
(61);

INSERT INTO MeetingRooms VALUES
(1, 1, 'Room 1-1', 1);

INSERT INTO Updates VALUES
(61, 1, 1, CURRENT_DATE - 3, 5);

INSERT INTO HealthDeclarations VALUES 
(31, CURRENT_DATE, 37.0),
(32, CURRENT_DATE, 37.6);

INSERT INTO Bookings VALUES
(1, 1, CURRENT_DATE - 2, 1, 32, 61),
(1, 1, CURRENT_DATE + 1, 1, 31, 61),
(1, 1, CURRENT_DATE + 8, 1, 31, 61),
(1, 1, CURRENT_DATE + 9, 1, 32, NULL),
(1, 1, CURRENT_DATE + 10, 1, 32, 61);

INSERT INTO Attends VALUES
-- Insert creators
(32, 1, 1, CURRENT_DATE - 2, 1),
(31, 1, 1, CURRENT_DATE + 1, 1),
(31, 1, 1, CURRENT_DATE + 8, 1),
(32, 1, 1, CURRENT_DATE + 9, 1),
(32, 1, 1, CURRENT_DATE + 10, 1),
-- Insert participants
(32, 1, 1, CURRENT_DATE + 1, 1),
(32, 1, 1, CURRENT_DATE + 8, 1);

-- contact_tracing
-- All employees in the same approved meeting room from the past 3 (i.e., from day D-3 to day D) days are contacted.
-- These employees are removed from future meeting in the next 7 days (i.e., from day D to day D+7).
/* 
    'SELECT * FROM contact_tracing(33);' -> 
    Senior 33 bookings from day D to day D+7 are removed, junior 4 and senior 33 attendance from day D to day D+7 are removed.
    Senior 33 bookings and attends past D+7 days are removed, bookings and attends of senior 34 are not removed past D+7
*/
INSERT INTO Departments VALUES
(2, 'Department 2', NULL);

INSERT INTO Employees VALUES
(1, 'Junior 1', 'Contact 1', 'junior1@company.com', NULL, 2),
(2, 'Junior 2', 'Contact 2', 'junior2@company.com', NULL, 2),
(3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 2),
(33, 'Senior 33', 'Contact 33', 'senior33@company.com', NULL, 2),
(34, 'Senior 34', 'Contact 34', 'senior34@company.com', NULL, 2),
(35, 'Senior 35', 'Contact 35', 'senior35@company.com', NULL, 2),
(36, 'Senior 36', 'Contact 36', 'senior36@company.com', NULL, 2),
(37, 'Senior 37', 'Contact 37', 'senior37@company.com', NULL, 2),
(62, 'Manager 62', 'Contact 62', 'manager62@company.com', NULL, 2);

INSERT INTO Juniors VALUES
(1), (2), (3);

INSERT INTO Superiors VALUES
(33), (34), (35), (36), (37), (62);

INSERT INTO Seniors VALUES
(33), (34), (35), (36), (37);

INSERT INTO Managers VALUES
(62);

INSERT INTO MeetingRooms VALUES
(1, 2, 'Room 1-2', 2);

INSERT INTO Updates VALUES
(62, 1, 2, CURRENT_DATE - 4, 5);

INSERT INTO HealthDeclarations VALUES
(33, CURRENT_DATE, 37.6);

INSERT INTO Bookings VALUES
(1, 2, CURRENT_DATE - 4, 7, 33, 62), -- Everyone attends 
(1, 2, CURRENT_DATE - 2, 1, 33, 62), -- Attended by 2
(1, 2, CURRENT_DATE - 2, 2, 33, NULL), -- Attended by 3
(1, 2, CURRENT_DATE - 1, 1, 34, 62), -- Attended by 33, 4
(1, 2, CURRENT_DATE - 1, 2, 35, NULL), -- Attended by 33
(1, 2, CURRENT_DATE - 1, 3, 36, 62), -- Attended by 34
(1, 2, CURRENT_DATE - 1, 4, 37, NULL), -- Attended by 34
(1, 2, CURRENT_DATE + 7, 1, 34, 62),
(1, 2, CURRENT_DATE + 7, 2, 35, 62),
(1, 2, CURRENT_DATE + 7, 3, 36, 62),
(1, 2, CURRENT_DATE + 7, 4, 37, 62),
(1, 2, CURRENT_DATE + 8, 1, 34, NULL); -- Attended by all.

INSERT INTO Attends VALUES
-- Insert creators
(33, 1, 2, CURRENT_DATE - 4, 7),
(33, 1, 2, CURRENT_DATE - 2, 1),
(33, 1, 2, CURRENT_DATE - 2, 2),
(34, 1, 2, CURRENT_DATE - 1, 1),
(35, 1, 2, CURRENT_DATE - 1, 2),
(36, 1, 2, CURRENT_DATE - 1, 3),
(37, 1, 2, CURRENT_DATE - 1, 4),
(34, 1, 2, CURRENT_DATE + 7, 1),
(35, 1, 2, CURRENT_DATE + 7, 2),
(36, 1, 2, CURRENT_DATE + 7, 3),
(37, 1, 2, CURRENT_DATE + 7, 4),
(34, 1, 2, CURRENT_DATE + 8, 1),
-- Insert participants
(1, 1, 2, CURRENT_DATE - 4, 7),
(2, 1, 2, CURRENT_DATE - 4, 7),
(3, 1, 2, CURRENT_DATE - 4, 7),
(34, 1, 2, CURRENT_DATE - 4, 7),
(35, 1, 2, CURRENT_DATE - 4, 7),
(36, 1, 2, CURRENT_DATE - 4, 7),
(37, 1, 2, CURRENT_DATE - 4, 7),
(62, 1, 2, CURRENT_DATE - 4, 7),
(1, 1, 2, CURRENT_DATE - 2, 1),
(2, 1, 2, CURRENT_DATE - 2, 2),
(3, 1, 2, CURRENT_DATE - 1, 1),
(33, 1, 2, CURRENT_DATE - 1, 1),
(62, 1, 2, CURRENT_DATE - 1, 1),
(33, 1, 2, CURRENT_DATE - 1, 2),
(34, 1, 2, CURRENT_DATE - 1, 3),
(34, 1, 2, CURRENT_DATE - 1, 4),
(1, 1, 2, CURRENT_DATE + 7, 2),
(2, 1, 2, CURRENT_DATE + 7, 3),
(3, 1, 2, CURRENT_DATE + 7, 4),
(1, 1, 2, CURRENT_DATE + 8, 1),
(2, 1, 2, CURRENT_DATE + 8, 1),
(3, 1, 2, CURRENT_DATE + 8, 1),
(33, 1, 2, CURRENT_DATE + 8, 1),
(35, 1, 2, CURRENT_DATE + 8, 1),
(36, 1, 2, CURRENT_DATE + 8, 1),
(37, 1, 2, CURRENT_DATE + 8, 1),
(62, 1, 2, CURRENT_DATE + 8, 1);

-- change_capacity
-- This routine is used to change the capacity of the room.
/*
    'CALL change_capacity(1, 5, 2, 63, CURRENT_DATE);' -> Changes room capacity of 'Room 1-5' from 4 to 2, bookings with more/less than 2 people attending are deleted
*/
INSERT INTO Departments VALUES
(3, 'Department 3', NULL);

INSERT INTO Employees VALUES
(4, 'Junior 4', 'Contact 4', 'junior4@company.com', NULL, 3),
(5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 3),
(6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 3),
(63, 'Manager 63', 'Contact 63', 'manager63@company.com', NULL, 3),
(64, 'Manager 64', 'Contact 64', 'manager64@company.com', NULL, 3);

INSERT INTO Juniors VALUES
(4), (5), (6);

INSERT INTO Superiors VALUES
(63), (64);

INSERT INTO Managers VALUES
(63), (64);

INSERT INTO MeetingRooms VALUES
(1, 3, 'Room 1-3', 3);

INSERT INTO Updates VALUES
(63, 1, 3, CURRENT_DATE, 4);

INSERT INTO Bookings VALUES
(1, 3, CURRENT_DATE + 2, 1, 63, 64),
(1, 3, CURRENT_DATE + 2, 2, 63, 64),
(1, 3, CURRENT_DATE + 2, 3, 63, 64),
(1, 3, CURRENT_DATE + 2, 4, 63, 64);

INSERT INTO Attends VALUES
-- Insert creators
(63, 1, 3, CURRENT_DATE + 2, 1),
(63, 1, 3, CURRENT_DATE + 2, 2),
(63, 1, 3, CURRENT_DATE + 2, 3),
(63, 1, 3, CURRENT_DATE + 2, 4),
-- Insert participants
(4, 1, 3, CURRENT_DATE + 2, 2),
(4, 1, 3, CURRENT_DATE + 2, 3),
(5, 1, 3, CURRENT_DATE + 2, 3),
(4, 1, 3, CURRENT_DATE + 2, 4),
(5, 1, 3, CURRENT_DATE + 2, 4),
(6, 1, 3, CURRENT_DATE + 2, 4);

-- Resignation
-- Additionally, any future records (e.g., future meetings) are removed.
/*
    'CALL remove_employee(70, CURRENT_DATE - 2);' -> Future bookings, attendances, healthdeclarations and approvals >= resignation_date of resigned manager 70 are removed
*/
INSERT INTO Departments VALUES
(4, 'Department 4', NULL);

INSERT INTO Employees VALUES
(65, 'Manager 65', 'Contact 65', 'manager65@company.com', NULL, 4),
(66, 'Manager 66', 'Contact 66', 'manager66@company.com', NULL, 4);

INSERT INTO Superiors VALUES
(65), (66);

INSERT INTO Managers VALUES
(65), (66);

INSERT INTO MeetingRooms VALUES
(1, 4, 'Room 1-4', 4);

INSERT INTO Updates VALUES
(66, 1, 4, CURRENT_DATE - 5, 5);

INSERT INTO HealthDeclarations VALUES 
(65, CURRENT_DATE - 3, 37.1),
(65, CURRENT_DATE - 2, 37.2),
(65, CURRENT_DATE - 1, 37.3),
(65, CURRENT_DATE, 37.4),
(65, CURRENT_DATE + 1, 37.5);

INSERT INTO Bookings VALUES
(1, 4, CURRENT_DATE - 3, 1, 65, 66),
(1, 4, CURRENT_DATE - 2, 1, 65, 66),
(1, 4, CURRENT_DATE - 1, 1, 65, 66),
(1, 4, CURRENT_DATE - 1, 2, 66, 65),
(1, 4, CURRENT_DATE + 1, 2, 66, 65);

INSERT INTO Attends VALUES
-- Insert creators
(65, 1, 4, CURRENT_DATE - 3, 1), 
(65, 1, 4, CURRENT_DATE - 2, 1), 
(65, 1, 4, CURRENT_DATE - 1, 1), 
(66, 1, 4, CURRENT_DATE - 1, 2), 
(66, 1, 4, CURRENT_DATE + 1, 2),
(65, 1, 4, CURRENT_DATE - 1, 2);

-- Add more dummy data to fulfil minimum 10 records requirement, and generate some new tuples to isolate dummy data for tables requiring foreign key
INSERT INTO Departments VALUES
(5, 'Department 5', NULL),
(6, 'Department 6', NULL),
(7, 'Department 7', NULL),
(8, 'Department 8', NULL),
(9, 'Department 9', NULL),
(10, 'Department 10', NULL);

INSERT INTO MeetingRooms VALUES
(1, 5, 'Room 1-8', 5),
(2, 1, 'Room 2-1', 6),
(2, 2, 'Room 2-2', 7),
(2, 3, 'Room 2-3', 8),
(2, 4, 'Room 2-4', 9),
(2, 5, 'Room 2-5', 10);

INSERT INTO Employees VALUES
(7, 'Junior 7', 'Contact 7', 'junior7@company.com', NULL, 5),
(8, 'Junior 8', 'Contact 8', 'junior8@company.com', NULL, 5),
(9, 'Junior 9', 'Contact 9', 'junior9@company.com', NULL, 5),
(10, 'Junior 10', 'Contact 10', 'junior10@company.com', NULL, 6),
(11, 'Junior 11', 'Contact 11', 'junior11@company.com', NULL, 6),
(12, 'Junior 12', 'Contact 12', 'junior12@company.com', NULL, 6),
(13, 'Junior 13', 'Contact 13', 'junior13@company.com', NULL, 6),
(14, 'Junior 14', 'Contact 14', 'junior14@company.com', NULL, 6),
(15, 'Junior 15', 'Contact 15', 'junior15@company.com', NULL, 7),
(16, 'Junior 16', 'Contact 16', 'junior16@company.com', NULL, 7),
(17, 'Junior 17', 'Contact 17', 'junior17@company.com', NULL, 7),
(18, 'Junior 18', 'Contact 18', 'junior18@company.com', NULL, 7),
(19, 'Junior 19', 'Contact 19', 'junior19@company.com', NULL, 7),
(20, 'Junior 20', 'Contact 20', 'junior20@company.com', NULL, 8),
(21, 'Junior 21', 'Contact 21', 'junior21@company.com', NULL, 8),
(22, 'Junior 22', 'Contact 22', 'junior22@company.com', NULL, 8),
(23, 'Junior 23', 'Contact 23', 'junior23@company.com', NULL, 8),
(24, 'Junior 24', 'Contact 24', 'junior24@company.com', NULL, 8),
(25, 'Junior 25', 'Contact 25', 'junior25@company.com', NULL, 9),
(26, 'Junior 26', 'Contact 26', 'junior26@company.com', NULL, 9),
(27, 'Junior 27', 'Contact 27', 'junior27@company.com', NULL, 9),
(28, 'Junior 28', 'Contact 28', 'junior28@company.com', NULL, 9),
(29, 'Junior 29', 'Contact 29', 'junior29@company.com', NULL, 9),
(30, 'Junior 30', 'Contact 30', 'junior30@company.com', NULL, 10),

(38, 'Senior 38', 'Contact 38', 'senior38@company.com', NULL, 5),
(39, 'Senior 39', 'Contact 39', 'senior39@company.com', NULL, 5),
(40, 'Senior 40', 'Contact 40', 'senior40@company.com', NULL, 5),
(41, 'Senior 41', 'Contact 41', 'senior41@company.com', NULL, 6),
(42, 'Senior 42', 'Contact 42', 'senior42@company.com', NULL, 6),
(43, 'Senior 43', 'Contact 43', 'senior43@company.com', NULL, 6),
(44, 'Senior 44', 'Contact 44', 'senior44@company.com', NULL, 6),
(45, 'Senior 45', 'Contact 45', 'senior45@company.com', NULL, 7),
(46, 'Senior 46', 'Contact 46', 'senior46@company.com', NULL, 7),
(47, 'Senior 47', 'Contact 47', 'senior47@company.com', NULL, 7),
(48, 'Senior 48', 'Contact 48', 'senior48@company.com', NULL, 7),
(49, 'Senior 49', 'Contact 49', 'senior49@company.com', NULL, 7),
(50, 'Senior 50', 'Contact 50', 'senior50@company.com', NULL, 8),
(51, 'Senior 51', 'Contact 51', 'senior51@company.com', NULL, 8),
(52, 'Senior 52', 'Contact 52', 'senior52@company.com', NULL, 8),
(53, 'Senior 53', 'Contact 53', 'senior53@company.com', NULL, 8),
(54, 'Senior 54', 'Contact 54', 'senior54@company.com', NULL, 9),
(55, 'Senior 55', 'Contact 55', 'senior55@company.com', NULL, 9),
(56, 'Senior 56', 'Contact 56', 'senior56@company.com', NULL, 9),
(57, 'Senior 57', 'Contact 57', 'senior57@company.com', NULL, 9),
(58, 'Senior 58', 'Contact 58', 'senior58@company.com', NULL, 10),
(59, 'Senior 59', 'Contact 59', 'senior59@company.com', NULL, 10),
(60, 'Senior 60', 'Contact 60', 'senior60@company.com', NULL, 10),

(67, 'Manager 67', 'Contact 67', 'manager67@company.com', NULL, 5),
(68, 'Manager 68', 'Contact 68', 'manager68@company.com', NULL, 6),
(69, 'Manager 69', 'Contact 69', 'manager69@company.com', NULL, 7),
(70, 'Manager 70', 'Contact 70', 'manager70@company.com', NULL, 8),
(71, 'Manager 71', 'Contact 71', 'manager71@company.com', NULL, 9),
(72, 'Manager 72', 'Contact 72', 'manager72@company.com', NULL, 10);

INSERT INTO Juniors VALUES
(7), (8), (9), (10), 
(11), (12), (13), (14), (15), (16), (17), (18), (19), (20),
(21), (22), (23), (24), (25), (26), (27), (28), (29), (30);

INSERT INTO Superiors VALUES
(38), (39), (40),
(41), (42), (43), (44), (45), (46), (47), (48), (49), (50),
(51), (52), (53), (54), (55), (56), (57), (58), (59), (60),
(67), (68), (69), (70), (71), (72);

INSERT INTO Seniors VALUES
(38), (39), (40),
(41), (42), (43), (44), (45), (46), (47), (48), (49), (50),
(51), (52), (53), (54), (55), (56), (57), (58), (59), (60);

INSERT INTO Managers VALUES
(67), (68), (69), (70), (71), (72);

INSERT INTO Updates VALUES
(67, 1, 5, CURRENT_DATE, 5),
(68, 2, 1, CURRENT_DATE, 5),
(69, 2, 2, CURRENT_DATE, 5),
(70, 2, 3, CURRENT_DATE, 5),
(71, 2, 4, CURRENT_DATE, 5),
(72, 2, 5, CURRENT_DATE, 5);

INSERT INTO HealthDeclarations VALUES
(11, CURRENT_DATE, 37.0),
(12, CURRENT_DATE, 37.0),
(13, CURRENT_DATE, 37.0),
(14, CURRENT_DATE, 37.0),
(15, CURRENT_DATE, 37.0),
(41, CURRENT_DATE, 37.0),
(42, CURRENT_DATE, 37.0),
(43, CURRENT_DATE, 37.0),
(44, CURRENT_DATE, 37.0),
(45, CURRENT_DATE, 37.0),
(67, CURRENT_DATE, 37.0),
(68, CURRENT_DATE, 37.0),
(69, CURRENT_DATE, 37.0),
(70, CURRENT_DATE, 37.0);