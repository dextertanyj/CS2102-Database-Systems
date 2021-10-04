DELETE FROM Updates;
DELETE FROM Attends;
DELETE FROM Bookings;
DELETE FROM HealthDeclarations;
DELETE FROM Managers;
DELETE FROM Seniors;
DELETE FROM Superiors;
DELETE FROM Juniors;
DELETE FROM MeetingRooms;
DELETE FROM Employees;
DELETE FROM Departments;

INSERT INTO Departments VALUES
(1, 'HR', NULL),
(2, 'Finance', TO_DATE('04/12/2021', 'DD/MM/YYYY'));

INSERT INTO Employees VALUES
(1, 'Adi Yoga', '88886666', 'adi@yoga.edu.sg', NULL, 1),
(2, 'Chris something', '09483240172407', 'chris@sth.sg', TO_DATE('04/11/2021', 'DD/MM/YYYY'), 2);

INSERT INTO MeetingRooms VALUES
(3, 101, 'Some floor 101', 1),
(4, 101, 'Some floor 101', 2);

INSERT INTO Juniors VALUES (1);
INSERT INTO Superiors VALUES (2);
INSERT INTO Managers VALUES (2);

INSERT INTO HealthDeclarations VALUES
(1, TO_DATE('04/10/2021', 'DD/MM/YYYY'), 35.5),
(2, TO_DATE('04/10/2021', 'DD/MM/YYYY'), 38); -- should be inserted as 38.0

INSERT INTO Bookings VALUES
(3, 101, TO_DATE('04/10/2021', 'DD/MM/YYYY'), 10, 2, 2),
(3, 101, TO_DATE('04/10/2021', 'DD/MM/YYYY'), 15, 2, 2);

INSERT INTO Attends VALUES
(1, 3, 101, TO_DATE('04/10/2021', 'DD/MM/YYYY'), 10),
(2, 3, 101, TO_DATE('04/10/2021', 'DD/MM/YYYY'), 10);

INSERT INTO Updates VALUES
(2, 4, 101, TO_DATE('04/10/2021', 'DD/MM/YYYY'), 6),
(2, 4, 101, TO_DATE('04/11/2021', 'DD/MM/YYYY'), 101);