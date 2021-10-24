-- TEST trigger 34 Meeting room booking or approval insert_employee_booking_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Superior 1', 'Contact 1', 'superior1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Resigned Superior 3', 'Contact 3', 'superior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Managers VALUES (4), (5), (6);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, 4); -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Meeting room booking or approval insert_resigned_employee_booking_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Superior 1', 'Contact 1', 'superior1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Resigned Superior 3', 'Contact 3', 'superior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Managers VALUES (4), (5), (6);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, 6); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 3, NULL); -- Failure
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 3, 6); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Meeting room booking or approval update_employee_booking_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Superior 1', 'Contact 1', 'superior1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Resigned Superior 3', 'Contact 3', 'superior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Managers VALUES (4), (5), (6);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, 4); -- Success
UPDATE Bookings SET creator_id = 2 where creator_id = 1; -- Success
UPDATE Bookings SET approver_id = 5 where approver_id = 4; -- Success
UPDATE Bookings SET creator_id = 1, approver_id = 4 where creator_id = 2 and approver_id = 5; -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Meeting room booking or approval update_resigned_employee_booking_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Superior 1', 'Contact 1', 'superior1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Resigned Superior 3', 'Contact 3', 'superior3@company.com', CURRENT_DATE, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Resigned Manager 6', 'Contact 6', 'manager6@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Managers VALUES (4), (5), (6);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 1, 4); -- Success
UPDATE Bookings SET creator_id = 3 WHERE creator_id = 1; -- Failure
UPDATE Bookings SET approver_id = 6 WHERE approver_id = 4; -- Failure
UPDATE Bookings SET creator_id = 3, approver_id = 6 WHERE creator_id = 1; -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration insert_employee_declaration_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1);
-- TEST
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0); -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration insert_resigned_employee_declaration_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1);
-- TEST
INSERT INTO HealthDeclarations VALUES(3, CURRENT_DATE, 37.0); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration update_employee_declaration_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1);
-- TEST
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0); -- Success
Update HealthDeclarations SET id = 2 WHERE id = 1; -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Health declaration update_resigned_employee_declaration_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1);
-- TEST
INSERT INTO HealthDeclarations VALUES(1, CURRENT_DATE, 37.0); -- Success
Update HealthDeclarations SET id = 3 WHERE id = 1; -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting insert_employee_attendance_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1),
    (4, 'Superior 4', 'Contact 4', 'superior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (4), (5);
INSERT INTO Managers VALUES (5);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, 5);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting insert_resigned_employee_attendance_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1),
    (4, 'Superior 4', 'Contact 4', 'superior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (4), (5);
INSERT INTO Managers VALUES (5);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, 5);
-- TEST
INSERT INTO Attends VALUES(3, 1, 1, CURRENT_DATE, 1); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting update_employee_attendance_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1),
    (4, 'Superior 4', 'Contact 4', 'superior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (4), (5);
INSERT INTO Managers VALUES (5);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, 5);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
UPDATE Attends SET employee_id = 2 WHERE employee_id = 1; -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Attends meeting update_resigned_employee_attendance_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Employee 1', 'Contact 1', 'employee1@company.com', NULL, 1),
    (2, 'Employee 2', 'Contact 2', 'employee2@company.com', NULL, 1),
    (3, 'Resigned Employee 3', 'Contact 3', 'employee3@company.com', CURRENT_DATE, 1),
    (4, 'Superior 4', 'Contact 4', 'superior4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (4), (5);
INSERT INTO Managers VALUES (5);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE, 1, 4, 5);
-- TEST
INSERT INTO Attends VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
UPDATE Attends SET employee_id = 3 WHERE employee_id = 1; -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity insert_employee_update_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Updates VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity insert_resigned_employee_update_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Updates VALUES(3, 1, 1, CURRENT_DATE, 1); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity update_employee_update_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Updates VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
UPDATE Updates SET manager_id = 2 WHERE manager_id = 1; -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST trigger 34 Update meeting room capacity update_resigned_employee_update_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
-- TEST
INSERT INTO Updates VALUES(1, 1, 1, CURRENT_DATE, 1); -- Success
UPDATE Updates SET manager_id = 3 WHERE manager_id = 1; -- Failure
-- AFTER TEST
CALL reset();
-- TEST END