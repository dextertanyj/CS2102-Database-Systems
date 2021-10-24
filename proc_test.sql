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

-- TEST add_department_unique_name_unique_id_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
-- TEST
CALL add_department(3, 'Department 3'); -- Success
SELECT COUNT(*) FROM departments; -- Return 3;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_department_unique_id_duplicate_name_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
-- TEST
CALL add_department(3, 'Department 1'); -- Success
SELECT COUNT(*) FROM departments; -- Return 3;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_department_duplicate_id_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
-- TEST
CALL add_department(1, 'Department 4'); -- Failure
SELECT COUNT(*) FROM departments; -- Return 2;
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_department_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
-- TEST
CALL remove_department(1, CURRENT_DATE); -- Success
SELECT removal_date FROM Departments WHERE id = 1; -- Returns CURRENT_DATE
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_department_non_existant_department_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
-- TEST
CALL remove_department(3, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_sucess
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
-- TEST
CALL add_room(2, 1, 'Room 2-1', 10, 1, CURRENT_DATE); -- Success
SELECT COUNT(*) FROM MeetingRooms; -- Returns 3
SELECT COUNT(*) FROM Updates; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_duplicate_name_sucess
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
-- TEST
CALL add_room(2, 1, 'Room 1-1', 10, 1, CURRENT_DATE); -- Success
SELECT COUNT(*) FROM MeetingRooms; -- Returns 3
SELECT COUNT(*) FROM Updates; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_duplicate_location_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
-- TEST
CALL add_room(1, 1, 'Room Unique Name', 10, 1, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_duplicate_location_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
-- TEST
CALL add_room(1, 1, 'Room Unique Name', 10, 1, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_resigned_manager_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
-- TEST
CALL add_room(2, 1, 'Room 2-1', 10, 3, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_senior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
-- TEST
CALL add_room(2, 1, 'Room 2-1', 10, 4, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_room_junior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior5@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 2);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10), (2, 1, 2, CURRENT_DATE, 10);
-- TEST
CALL add_room(2, 1, 'Room 2-1', 10, 5, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (4, 'Resigned Manager 4', 'Contact 4', 'manager4@company.com', CURRENT_DATE, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2), (3), (4);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
-- TEST
CALL change_capacity(1, 1, 20, 2, CURRENT_DATE); -- Success
SELECT capacity FROM Updates WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE; -- Returns 20
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_resigned_employee_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (4, 'Resigned Manager 4', 'Contact 4', 'manager4@company.com', CURRENT_DATE, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2), (3), (4);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
-- TEST
CALL change_capacity(1, 1, 20, 3, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_different_department_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (4, 'Resigned Manager 4', 'Contact 4', 'manager4@company.com', CURRENT_DATE, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2), (3), (4);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
-- TEST
CALL change_capacity(1, 1, 20, 2, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_senior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (4, 'Resigned Manager 4', 'Contact 4', 'manager4@company.com', CURRENT_DATE, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2), (3), (4);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
-- TEST
CALL change_capacity(1, 1, 20, 5, CURRENT_DATE); -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_junior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (4, 'Resigned Manager 4', 'Contact 4', 'manager4@company.com', CURRENT_DATE, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2), (3), (4);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
-- TEST
CALL change_capacity(1, 1, 20, 6, CURRENT_DATE); -- Success
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST change_capacity_non_existant_room_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2),
    (4, 'Resigned Manager 4', 'Contact 4', 'manager4@company.com', CURRENT_DATE, 1),
    (5, 'Senior 5', 'Contact 5', 'senior5@company.com', NULL, 1),
    (6, 'Junior 6', 'Contact 6', 'junior6@company.com', NULL, 1);
INSERT INTO Juniors VALUES (6);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Seniors VALUES (5);
INSERT INTO Managers VALUES (1), (2), (3), (4);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
-- TEST
CALL change_capacity(2, 1, 20, 1, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_manager_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'manager', 1); -- Success
SELECT * FROM Managers AS M JOIN Employees AS E ON M.id = E.id WHERE E.name = 'John Doe';
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_senior_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'manager', 1); -- Success
SELECT * FROM Managers AS M JOIN Employees AS E ON M.id = E.id WHERE E.name = 'John Doe';
SELECT add_employee('John Doe', 'Contact 1', 'senior' , 1); -- Success
SELECT * FROM Seniors AS S JOIN Employees AS E ON S.id = E.id WHERE E.name = 'John Doe';
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_junior_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'junior' , 1); -- Success
SELECT * FROM Seniors AS J JOIN Employees AS E ON J.id = E.id WHERE E.name = 'John Doe';
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_invalid_department_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'junior', 2); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_unknown_type_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'Unknown' , 1); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST add_employee_duplicate_name_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Seniors VALUES (1);
INSERT INTO Managers VALUES (1);
-- TEST
SELECT add_employee('Manager 1', 'Contact 2', 'manager' , 1); -- Success
SELECT * FROM Seniors AS J JOIN Employees AS E ON J.id = E.id WHERE E.name = 'Manager 1' AND E.contact = 'Contact 2';
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_employee_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Resigned Manager 2', 'Contact 2', 'manager2@company.com', CURRENT_DATE - 1, 1),
-- TEST
CALL remove_employee(1, CURRENT_DATE); -- Success
SELECT E.resignation_date FROM Employees AS E WHERE E.id = 1; -- Returns CURRENT_DATE
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_employee_already_resigned_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Resigned Manager 2', 'Contact 2', 'manager2@company.com', CURRENT_DATE - 1, 1),
-- TEST
CALL remove_employee(2, CURRENT_DATE); -- Failure
SELECT E.resignation_date FROM Employees AS E WHERE E.id = 2; -- Returns CURRENT_DATE - 1
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST remove_employee_non_existant_employee_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Resigned Manager 2', 'Contact 2', 'manager2@company.com', CURRENT_DATE - 1, 1),
-- TEST
CALL remove_employee(3, CURRENT_DATE); -- Failure
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST search_room
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1', 1),
    (1, 2, 'Room 2', 1),
    (2, 1, 'Room 3', 2);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE, 10),
    (1, 1, 2, CURRENT_DATE, 5),
    (1, 2, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
SELECT search_room(10, CURRENT_DATE + 1, 4, 8); -- Returns (1, 1, 1, 10), (2, 1, 2, 10)
SELECT search_room(5, CURRENT_DATE + 1, 4, 8); -- Returns (1, 2, 1, 5), (1, 1, 1, 10), (2, 1, 2, 10)
SELECT search_room(10, CURRENT_DATE + 1, 1, 4); -- Returns (2, 1, 2, 10)
SELECT search_room(10, CURRENT_DATE + 1, 3, 4); -- Returns (2, 1, 2, 10)
SELECT search_room(10, CURRENT_DATE + 1, 4, 5); -- Returns (1, 1, 1, 10), (2, 1, 2, 10)
SELECT search_room(10, CURRENT_DATE + 2, 1, 3); -- Returns (1, 1, 1, 10), (2, 1, 2, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_single_hour_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 2, 0, 1, 2);
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 2; -- Return 1
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_single_hour_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 23, 24, 2);
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 2; -- Return 1
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_multiple_hour_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 2, 4, 6, 2); -- Success
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 2; -- Return 2
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_senior_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 2, 4, 6, 4); -- Success
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 2; -- Return 2
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_invalid_end_time_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 24, 25, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_invalid_duration_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 24, 2, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_invalid_start_time_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, -1, 0, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_overlapping_periods_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 2, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_overlapping_periods_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 4, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_overlapping_periods_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 10, 1); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST book_room_junior_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Seniors VALUES (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 10, 5); -- Failure
SELECT COUNT(*) FROM Bookings WHERE floor = 1 AND room = 1 AND date = CURRENT_DATE + 1; -- Return 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_partial_batch_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 2, 1);
SELECT COUNT(*) FROM Bookings; -- Returns 2
SELECT COUNT(*) FROM Attends; -- Returns 2
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_entire_batch_success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 4, 1);
SELECT COUNT(*) FROM Bookings; -- Returns 0
SELECT COUNT(*) FROM Attends; -- Returns 0
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_different_employee_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 3, 2);
SELECT COUNT(*) FROM Bookings; -- Returns 3
SELECT COUNT(*) FROM Attends; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_non_existant_booking_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 4, 5, 1);
SELECT COUNT(*) FROM Bookings; -- Returns 3
SELECT COUNT(*) FROM Attends; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST unbook_room_non_existant_room_failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1), (2);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
INSERT INTO Attends VALUES
    (1, 1, 1, CURRENT_DATE + 1, 1),
    (1, 1, 1, CURRENT_DATE + 1, 2),
    (1, 1, 1, CURRENT_DATE + 1, 3);
-- TEST
CALL unbook_room(1, 2, CURRENT_DATE + 1, 1, 2, 1);
SELECT COUNT(*) FROM Bookings; -- Returns 3
SELECT COUNT(*) FROM Attends; -- Returns 3
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST non_compliance
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO HealthDeclarations VALUES
    (1, CURRENT_DATE - 3, 37.0),
    (1, CURRENT_DATE - 2, 37.0),
    (1, CURRENT_DATE - 1, 37.0),
    (1, CURRENT_DATE, 37.0),
    (2, CURRENT_DATE - 3, 37.0),
    (2, CURRENT_DATE - 1, 37.0),
    (2, CURRENT_DATE, 37.0),
    (3, CURRENT_DATE - 3, 37.0),
    (3, CURRENT_DATE - 1, 37.0),
    (5, CURRENT_DATE - 2, 37.0),
    (5, CURRENT_DATE - 1, 37.0);
-- TEST
SELECT * FROM non_compliance(CURRENT_DATE - 3, CURRENT_DATE); -- Expected: (4,4), (5,2), (2,1), (3,1)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST view_booking_report
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Employees VALUES 
    (1, 'Superior 1', 'Contact 1', 'superior1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (3);
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 2, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 1, 1, 3),
    (1, 1, CURRENT_DATE, 2, 2, NULL),
    (1, 1, CURRENT_DATE, 3, 2, NULL);
-- TEST
SELECT * FROM view_booking_report(CURRENT_DATE, 1); -- Expected: (1,1,2021-10-24,1,f), (1,1,2021-10-25,1,t), (1,1,2021-10-25,2,f), (1,1,2021-10-26,1,f)
-- AFTER TEST
CALL reset();
-- END TEST

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;
