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

/*****************
* ADD DEPARTMENT *
*****************/

-- TEST Unique Name & ID Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
CALL add_department(2, 'Department 2');
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', NULL), (2, 'Department 2', NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Duplicate Name Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
CALL add_department(2, 'Department 1');
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', NULL), (2, 'Department 1', NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Duplicate ID Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
CALL add_department(1, 'Department 2'); -- Exception
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', NULL)
-- AFTER TEST
CALL reset();
-- TEST END

/********************
* REMOVE DEPARTMENT *
********************/

-- TEST Existing Department Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
CALL remove_department(1); -- Success
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', CURRENT_DATE)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Missing Department Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
CALL remove_department(2); -- Exception
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Removed Department Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', CURRENT_DATE - 1);
-- TEST
CALL remove_department(1); -- Exception
SELECT * FROM Departments ORDER BY id; -- Returns (1, 'Department 1', CURRENT_DATE - 1)
-- AFTER TEST
CALL reset();
-- TEST END

/***********
* ADD ROOM *
***********/

-- TEST Success
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
CALL add_room(1, 1, 'Room 1-1', 10, 1, CURRENT_DATE);
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (1, 1, 'Room 1-1', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Duplicate Name Success
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
INSERT INTO MeetingRooms VALUES (1, 1, 'Room Name', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(2, 2, 'Room Name', 10, 1, CURRENT_DATE);
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (1, 1, 'Room Name', 1), (2, 2, 'Room Name', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10), (1, 2, 2, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Duplicate Location Failure
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
INSERT INTO MeetingRooms VALUES (1, 1, 'Room Name', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL add_room(1, 1, 'Another Name', 10, 1, CURRENT_DATE + 1); -- Exception
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (1, 1, 'Room Name', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Same Floor Number Success
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
CALL add_room(1, 2, 'Room 1-2', 10, 1, CURRENT_DATE);
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (1, 1, 'Room 1-1', 1), (1, 2, 'Room 1-2', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10), (1, 1, 2, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Same Room Number Success
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
CALL add_room(2, 1, 'Room 2-1', 10, 1, CURRENT_DATE);
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns (1, 1, 'Room 1-1', 1), (2, 1, 'Room 2-1', 1)
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10), (1, 2, 1, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Resigned Manager Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
CALL add_room(1, 1, 'Room 1-1', 10, 1, CURRENT_DATE); -- Exception
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Senior Failure
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
CALL add_room(1, 1, 'Room 1-1', 10, 1, CURRENT_DATE); -- Exception
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Junior Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Junior 1', 'Contact 1', 'junior1@company.com', NULL, 1);
INSERT INTO Juniors VALUES (1);
COMMIT;
-- TEST
CALL add_room(1, 1, 'Room 1-1', 10, 1, CURRENT_DATE); -- Exception
SELECT * FROM MeetingRooms ORDER BY floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

/******************
* CHANGE CAPACITY *
******************/

-- TEST Different Date Success
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
CALL change_capacity(1, 1, 20, 1, CURRENT_DATE + 1);
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10), (1, 1, 1, CURRENT_DATE + 1, 20)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Same Date Success
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
CALL change_capacity(1, 1, 20, 1, CURRENT_DATE); -- Success
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 20)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Resigned Employee Failure
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
CALL change_capacity(1, 1, 20, 1, CURRENT_DATE); -- Exception
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Different Department Failure
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
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL change_capacity(1, 1, 20, 2, CURRENT_DATE); -- Exception
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Senior Failure
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
-- TEST
CALL change_capacity(1, 1, 20, 2, CURRENT_DATE); -- Exception
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Junior Failure
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL change_capacity(1, 1, 20, 2, CURRENT_DATE); -- Exception
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns (1, 1, 1, CURRENT_DATE, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Missing Room Failure
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
CALL change_capacity(1, 1, 10, 1, CURRENT_DATE); -- Exception
SELECT * FROM Updates ORDER BY date, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

/***************
* ADD EMPLOYEE *
***************/

-- TEST Manager Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'manager', 1);
SELECT * FROM Employees NATURAL JOIN Managers ORDER BY id; -- Returns (*, 'John Doe', 'Contact 1', 'johndoe@company.com', NULL, 1);
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Senior Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'senior', 1);
SELECT * FROM Employees NATURAL JOIN Seniors ORDER BY id; -- Returns (*, 'John Doe', 'Contact 1', 'johndoe@company.com', NULL, 1);
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Junior Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'junior', 1);
SELECT * FROM Employees NATURAL JOIN Juniors ORDER BY id; -- Returns (*, 'John Doe', 'Contact 1', 'johndoe@company.com', NULL, 1);
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Duplicate Name Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'John Doe', 'Contact 1', 'johndoe@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
SELECT add_employee('John Doe', 'Contact 2', 'manager' , 1);
SELECT * FROM Employees NATURAL JOIN Managers ORDER BY id; -- Returns (*, 'John Doe', 'Contact 1', 'johndoe@company.com', NULL, 1), (*, 'John Doe', 'Contact 2', 'johndoe_1@company.com', NULL, 1);
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Invalid Department Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'manager', 2); -- Exception
SELECT * FROM Employees ORDER BY id; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Removed Department Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', CURRENT_DATE);
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'manager', 2);
SELECT * FROM Employees ORDER BY id; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Unknown Type Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1', CURRENT_DATE);
-- TEST
SELECT add_employee('John Doe', 'Contact 1', 'unknown', 1);
SELECT * FROM Employees ORDER BY id; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

/******************
* REMOVE EMPLOYEE *
******************/

-- TEST Success
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
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 1, 1);
-- TEST
CALL remove_employee(1, CURRENT_DATE);
SELECT * FROM Employees ORDER BY id; -- Returns (1, 'Manager 1', 'Contact 1', 'manager1@company.com', CURRENT_DATE, 1)
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL; 
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Resigned Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', CURRENT_DATE - 1, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
CALL remove_employee(1, CURRENT_DATE); -- Exception
SELECT * FROM Employees ORDER BY id; -- Returns (1, 'Manager 1', 'Contact 1', 'manager1@company.com', CURRENT_DATE - 1, 1)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Missing Employee Failure
-- BEFORE TEST
CALL reset();
-- TEST
CALL remove_employee(1, CURRENT_DATE); -- Exception
-- AFTER TEST
CALL reset();
-- TEST END

/**************
* SEARCH ROOM *
**************/

-- TEST
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
    (1, 1, 'Room 1', 1),
    (1, 2, 'Room 2', 1),
    (2, 1, 'Room 3', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE, 10),
    (1, 1, 2, CURRENT_DATE, 5),
    (1, 2, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
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

-- TEST No Effective Capacity
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
    (1, 1, 'Room 1', 1),
    (1, 2, 'Room 2', 1),
    (2, 1, 'Room 3', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE, 10),
    (1, 1, 2, CURRENT_DATE, 5),
    (1, 2, 1, CURRENT_DATE + 5, 10);
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
-- TEST
SELECT search_room(5, CURRENT_DATE + 1, 4, 8); -- Returns (1, 1, 1, 10), (2, 1, 2, 10)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Multiple Capacities
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
    (1, 1, 'Room 1', 1);
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 10, 20),
    (1, 1, 1, CURRENT_DATE, 10),
    (1, 1, 1, CURRENT_DATE + 2, 5);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
COMMIT;
-- TEST
SELECT search_room(25, CURRENT_DATE - 1, 1, 2); -- Returns NULL
SELECT search_room(15, CURRENT_DATE - 1, 1, 2); -- Returns (1, 1, 1, 20)
SELECT search_room(15, CURRENT_DATE + 1, 1, 2); -- Returns NULL
SELECT search_room(10, CURRENT_DATE + 1, 1, 2); -- Returns (1, 1, 1, 10)
SELECT search_room(10, CURRENT_DATE + 3, 1, 2); -- Returns NULL
SELECT search_room(5, CURRENT_DATE + 3, 1, 2); -- Returns (1, 1, 1, 5)
-- AFTER TEST
CALL reset();
-- TEST END

/************
* BOOK ROOM *
************/

-- TEST Single Hour Success
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
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 2, 1);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Multiple Hour Success
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
CALL book_room(1, 1, CURRENT_DATE + 1, 0, 24, 1);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room LIMIT 2; -- Returns (1, 1, CURRENT_DATE + 1, 0, 1, NULL), (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
SELECT COUNT(*) FROM Bookings; -- Returns 24
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Senior Success
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
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 2, 2);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 2, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Invalid End Time Failure
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
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 25, 1); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Invalid Duration Failure
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
CALL book_room(1, 1, CURRENT_DATE + 1, 3, 2, 1); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Invalid Start Time Failure
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
CALL book_room(1, 1, CURRENT_DATE + 1, -1, 2, 1); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Complete Overlap Failure
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
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 2, 3, 1); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, NULL), (1, 1, CURRENT_DATE + 1, 3, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Partial Overlap Failure
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
CALL book_room(1, 1, CURRENT_DATE + 1, 0, 2, 1); -- Failure
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Junior Failure
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
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 10);
COMMIT;
-- TEST
CALL book_room(1, 1, CURRENT_DATE + 1, 1, 10, 2); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

/**************
* UNBOOK ROOM *
**************/

-- TEST Partial Booking Success
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
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 2, 3, 1);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 3, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Complete Booking Success
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
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 4, 1);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Approved Booking Success
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
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
UPDATE Bookings SET approver_id = 1;
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 4, 1);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns NULL
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Different Creator Failure
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
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 2, 3, 2);
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, NULL), (1, 1, CURRENT_DATE + 1, 3, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Missing Booking Failure
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
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 2, 1); -- Exception
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Missing Room Failure
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
CALL unbook_room(1, 1, CURRENT_DATE + 1, 1, 2, 1); -- Exception
-- AFTER TEST
CALL reset();
-- TEST END

-- TEST Invalid Duration Failure 
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
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 1, NULL);
-- TEST
CALL unbook_room(1, 1, CURRENT_DATE + 1, 3, 2, 1); -- Exception
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room; -- Returns (1, 1, CURRENT_DATE + 1, 1, 1, NULL), (1, 1, CURRENT_DATE + 1, 2, 1, NULL), (1, 1, CURRENT_DATE + 1, 3, 1, NULL)
-- AFTER TEST
CALL reset();
-- TEST END

/***************
* JOIN MEETING *
***************/

/****************
* LEAVE MEETING *
****************/

/******************
* APPROVE MEETING *
******************/

/*****************
* NON COMPLIANCE *
*****************/

-- TEST non_compliance
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 2),
    (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1),
    (4, 'Senior 4', 'Contact 4', 'senior4@company.com', NULL, 1),
    (5, 'Junior 5', 'Contact 5', 'junior5@company.com', NULL, 1);
INSERT INTO Juniors VALUES (5);
INSERT INTO Superiors VALUES (1), (2), (3), (4);
INSERT INTO Managers VALUES (1), (2), (3);
INSERT INTO Seniors VALUES (4);
COMMIT;
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
-- Set Manager 3 to Resigned after declaring temperature (Otherwise temperature declaration is not allowed by trigger)
UPDATE Employees SET resignation_date = CURRENT_DATE - 1 WHERE id = 3;
-- TEST
SELECT * FROM non_compliance(CURRENT_DATE - 3, CURRENT_DATE); -- Expected: (4,4), (5,2), (2,1), (3,1)
-- AFTER TEST
CALL reset();
-- TEST END

/**********************
* VIEW BOOKING REPORT *
**********************/

-- TEST view_booking_report
-- BEFORE TEST
CALL reset();
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER lock_attends;
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES 
    (1, 'Senior 1', 'Contact 1', 'senior1@company.com', NULL, 1),
    (2, 'Senior 2', 'Contact 2', 'senior2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Seniors VALUES (1), (2);
INSERT INTO Managers VALUES (3);
COMMIT;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (3, 1, 1, CURRENT_DATE, 10);
COMMIT;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 2, 1, NULL),
    (1, 1, CURRENT_DATE + 2, 1, 1, NULL),
    (1, 1, CURRENT_DATE + 3, 1, 1, 3);
-- TEST
SELECT * FROM view_booking_report(CURRENT_DATE, 1); -- Expected: (1,1,CURRENT_DATE,1,f), (1,1,CURRENT_DATE + 1,2,f), (1,1,CURRENT_DATE + 2,1,f), (1,1,CURRENT_DATE + 3, 1, t)
-- AFTER TEST
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER lock_attends;
CALL reset();
-- TEST END

/**********************
* VIEW FUTURE MEETING *
**********************/

/**********************
* VIEW MANAGER REPORT *
**********************/

/*****************
* DECLARE HEALTH *
*****************/

-- TEST Success
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
CALL declare_health(1, CURRENT_DATE, 37.5);
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns (1, CURRENT_DATE, 37.5);
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Repeat Declaration Successful
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.0);
-- TEST
CALL declare_health(1, CURRENT_DATE, 37.5);
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns (1, CURRENT_DATE, 37.5)
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Retired Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', CURRENT_DATE, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
CALL declare_health(1, CURRENT_DATE, 37.5); -- Exception
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Missing Employee Failure
-- BEFORE TEST
CALL reset();
-- TEST
CALL declare_health(1, CURRENT_DATE, 37.5); -- Exception
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Past Date Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
CALL declare_health(1, CURRENT_DATE - 1, 37.5); -- Exception
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Future Date Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
CALL declare_health(1, CURRENT_DATE + 1, 37.5); -- Exception
SELECT * FROM HealthDeclarations ORDER BY date, id; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Low Temperature Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
CALL declare_health(1, CURRENT_DATE, 33.0); -- Exception
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST High Temperature Failure
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1);
INSERT INTO Managers VALUES (1);
COMMIT;
-- TEST
CALL declare_health(1, CURRENT_DATE, 45.0); -- Exception
SELECT * FROM HealthDeclarations ORDER BY id, date; -- Returns NULL
-- AFTER TEST
CALL reset();
-- END TEST

/******************
* CONTACT TRACING *
******************/

-- TEST No Fever
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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10);
COMMIT;
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1),
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1),
    (2, 1, 1, CURRENT_DATE + 1, 1);
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
ALTER TABLE Bookings DISABLE TRIGGER approval_only_for_future_meetings_trigger;
UPDATE Bookings SET approver_id = 2 WHERE date = CURRENT_DATE - 2 OR date = CURRENT_DATE + 1;
ALTER TABLE Bookings ENABLE TRIGGER approval_only_for_future_meetings_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.0);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns NULL
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |            
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |            
     1 |    1 | CURRENT_DATE + 1 |                1 |          1 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 2 |                1 
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 
           1 |     1 |    1 | CURRENT_DATE + 1 |                1
           2 |     1 |    1 | CURRENT_DATE + 1 |                1
*/
-- TEST
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST No Declaration
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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10);
COMMIT;
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL),
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1),
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1),
    (2, 1, 1, CURRENT_DATE + 1, 1);
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
ALTER TABLE Bookings DISABLE TRIGGER approval_only_for_future_meetings_trigger;
UPDATE Bookings SET approver_id = 2 WHERE date = CURRENT_DATE - 2 OR date = CURRENT_DATE + 1;
ALTER TABLE Bookings ENABLE TRIGGER approval_only_for_future_meetings_trigger;
-- TEST
SELECT * FROM contact_tracing(1); -- Throws error
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |            
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |            
     1 |    1 | CURRENT_DATE + 1 |                1 |          1 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 
           1 |     1 |    1 | CURRENT_DATE + 1 |                1
           2 |     1 |    1 | CURRENT_DATE + 1 |                1
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Fever With Future Bookings Without Close Contacts
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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (1, 2, 'Room 1-2', 1),
    (2, 1, 'Room 2-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10),
    (1, 1, 2, CURRENT_DATE - 5, 10),
    (1, 2, 1, CURRENT_DATE - 5, 10);
COMMIT;
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 4, 1, 1, NULL), -- Attended by ALL
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL), -- Not Approved, Attended by ALL
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL),
    (1, 2, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 2, NULL),
    (2, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 3, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 1, NULL), -- Deleted
    (1, 1, CURRENT_DATE + 1, 1, 1, NULL), -- Attended by ALL, Deleted
    (1, 1, CURRENT_DATE + 1, 2, 2, NULL),
    (1, 1, CURRENT_DATE + 1, 3, 3, NULL),
    (1, 1, CURRENT_DATE + 8, 1, 1, NULL); -- Attended by 2
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 4, 1),
    (3, 1, 1, CURRENT_DATE - 4, 1),
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (3, 1, 1, CURRENT_DATE - 2, 1),
    (2, 1, 1, CURRENT_DATE + 1, 1),
    (3, 1, 1, CURRENT_DATE + 1, 1),
    (2, 1, 1, CURRENT_DATE + 8, 1);
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
ALTER TABLE Bookings DISABLE TRIGGER approval_only_for_future_meetings_trigger;
UPDATE Bookings SET approver_id = 2 WHERE date = CURRENT_DATE - 4 OR date = CURRENT_DATE OR date = CURRENT_DATE + 1;
ALTER TABLE Bookings ENABLE TRIGGER approval_only_for_future_meetings_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns NULL
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 4 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |            
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |           2
     1 |    2 | CURRENT_DATE     | CURRENT_HOUR - 1 |          2 |           2
     2 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          3 |           2
     1 |    1 | CURRENT_DATE + 1 |                2 |          2 |           2
     1 |    1 | CURRENT_DATE + 1 |                3 |          3 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 4 |                1
           2 |     1 |    1 | CURRENT_DATE - 4 |                1
           3 |     1 |    1 | CURRENT_DATE - 4 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           3 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    2 | CURRENT_DATE     | CURRENT_HOUR - 1
           3 |     2 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    1 | CURRENT_DATE + 1 |                2
           3 |     1 |    1 | CURRENT_DATE + 1 |                3
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Fever With Future Attendance Without Close Contacts
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
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (1, 2, 'Room 1-2', 1),
    (2, 1, 'Room 2-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10),
    (1, 1, 2, CURRENT_DATE - 5, 10),
    (1, 2, 1, CURRENT_DATE - 5, 10);
COMMIT;
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 4, 1, 1, NULL), -- Attended by ALL
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL), -- Not Approved, Attended by ALL
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL),
    (1, 2, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 2, NULL),
    (2, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 3, NULL),
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 2, NULL), -- Attended By 1
    (1, 1, CURRENT_DATE + 1, 2, 2, NULL), -- Attended by 1
    (1, 1, CURRENT_DATE + 1, 3, 3, NULL),
    (1, 1, CURRENT_DATE + 8, 2, 2, NULL);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 4, 1),
    (3, 1, 1, CURRENT_DATE - 4, 1),
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (3, 1, 1, CURRENT_DATE - 2, 1),
    (1, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (1, 1, 1, CURRENT_DATE + 1, 2), -- Removed
    (1, 1, 1, CURRENT_DATE + 8, 2);
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
ALTER TABLE Bookings DISABLE TRIGGER approval_only_for_future_meetings_trigger;
UPDATE Bookings SET approver_id = 2 WHERE date = CURRENT_DATE - 4 OR date = CURRENT_DATE OR date = CURRENT_DATE + 1;
ALTER TABLE Bookings ENABLE TRIGGER approval_only_for_future_meetings_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns NULL
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 4 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |            
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |           2
     1 |    2 | CURRENT_DATE     | CURRENT_HOUR - 1 |          2 |           2
     2 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          3 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 |          2 |           2
     1 |    1 | CURRENT_DATE + 1 |                2 |          2 |           2
     1 |    1 | CURRENT_DATE + 1 |                3 |          3 |           2
     1 |    1 | CURRENT_DATE + 8 |                2 |          2 |            
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 4 |                1
           2 |     1 |    1 | CURRENT_DATE - 4 |                1
           3 |     1 |    1 | CURRENT_DATE - 4 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           3 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    2 | CURRENT_DATE     | CURRENT_HOUR - 1
           3 |     2 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1
           2 |     1 |    1 | CURRENT_DATE + 1 |                2
           3 |     1 |    1 | CURRENT_DATE + 1 |                3
           2 |     1 |    1 | CURRENT_DATE + 8 |                2
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Fever With Close Contacts With Future Attendances
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1),
    (6, 'Manager 6', 'Contact 6', 'manager6@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5), (6);
INSERT INTO Managers VALUES (1), (2), (3), (4), (5), (6);
COMMIT;
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (1, 2, 'Room 1-2', 1),
    (2, 1, 'Room 2-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10),
    (1, 1, 2, CURRENT_DATE - 5, 10),
    (1, 2, 1, CURRENT_DATE - 5, 10);
COMMIT;
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 4, 1, 1, NULL), -- Attended by 6
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL), -- Attended by 2
    (1, 1, CURRENT_DATE - 2, 2, 2, NULL), -- Attended by 1 and 3
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2, 4, NULL), -- Attended by 1 and 5
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL), -- Attended by 4
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 6, NULL), -- Attended by all
    (1, 1, CURRENT_DATE + 7, 6, 6, NULL),
    (1, 1, CURRENT_DATE + 8, 2, 2, NULL); -- Attended by all
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (6, 1, 1, CURRENT_DATE - 4, 1),
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (1, 1, 1, CURRENT_DATE - 2, 2),
    (3, 1, 1, CURRENT_DATE - 2, 2),
    (1, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2),
    (5, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2),
    (4, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1),
    (1, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (2, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (3, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (4, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (5, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1), -- Removed
    (1, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (2, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (3, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (4, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (5, 1, 1, CURRENT_DATE + 7, 6), -- Removed
    (1, 1, 1, CURRENT_DATE + 8, 2), -- Removed
    (3, 1, 1, CURRENT_DATE + 8, 2),
    (4, 1, 1, CURRENT_DATE + 8, 2),
    (5, 1, 1, CURRENT_DATE + 8, 2),
    (6, 1, 1, CURRENT_DATE + 8, 2);
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
ALTER TABLE Bookings DISABLE TRIGGER approval_only_for_future_meetings_trigger;
UPDATE Bookings SET approver_id = 2;
ALTER TABLE Bookings ENABLE TRIGGER approval_only_for_future_meetings_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns (2), (3), (4), (5)
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 4 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                2 |          2 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2 |          4 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1 |          6 |           2
     1 |    1 | CURRENT_DATE + 7 |                6 |          6 |           2
     1 |    1 | CURRENT_DATE + 8 |                2 |          2 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 4 |                1
           6 |     1 |    1 | CURRENT_DATE - 4 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                2
           2 |     1 |    1 | CURRENT_DATE - 2 |                2
           3 |     1 |    1 | CURRENT_DATE - 2 |                2
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           4 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           5 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           4 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           6 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR + 1
           6 |     1 |    1 | CURRENT_DATE + 7 |                6
           2 |     1 |    1 | CURRENT_DATE + 8 |                2
           3 |     1 |    1 | CURRENT_DATE + 8 |                2
           4 |     1 |    1 | CURRENT_DATE + 8 |                2
           5 |     1 |    1 | CURRENT_DATE + 8 |                2
           6 |     1 |    1 | CURRENT_DATE + 8 |                2
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST Fever With Close Contacts With Future Bookings
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Manager 2', 'Contact 2', 'manager2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 1),
    (4, 'Manager 4', 'Contact 4', 'manager4@company.com', NULL, 1),
    (5, 'Manager 5', 'Contact 5', 'manager5@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2), (3), (4), (5);
INSERT INTO Managers VALUES (1), (2), (3), (4), (5);
COMMIT;
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
BEGIN TRANSACTION;
INSERT INTO MeetingRooms VALUES
    (1, 1, 'Room 1-1', 1),
    (1, 2, 'Room 1-2', 1),
    (2, 1, 'Room 2-1', 1);
INSERT INTO Updates VALUES
    (1, 1, 1, CURRENT_DATE - 5, 10),
    (1, 1, 2, CURRENT_DATE - 5, 10),
    (1, 2, 1, CURRENT_DATE - 5, 10);
COMMIT;
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE - 2, 1, 1, NULL), -- Attended by 2
    (1, 1, CURRENT_DATE - 2, 2, 2, NULL), -- Attended by 1 and 3
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2, 4, NULL), -- Attended by 1 and 5
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1, 1, NULL), -- Attended by 4
    (1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) + 1, 2, NULL), -- Removed
    (1, 1, CURRENT_DATE + 7, 3, 3, NULL), -- Removed
    (1, 1, CURRENT_DATE + 7, 4, 4, NULL), -- Removed
    (1, 1, CURRENT_DATE + 7, 5, 5, NULL), -- Removed
    (1, 1, CURRENT_DATE + 8, 2, 2, NULL);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE - 2, 1),
    (1, 1, 1, CURRENT_DATE - 2, 2),
    (3, 1, 1, CURRENT_DATE - 2, 2),
    (1, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2),
    (5, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 2),
    (4, 1, 1, CURRENT_DATE, extract(HOUR FROM CURRENT_TIME) - 1);
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
ALTER TABLE Bookings DISABLE TRIGGER approval_only_for_future_meetings_trigger;
UPDATE Bookings SET approver_id = 2;
ALTER TABLE Bookings ENABLE TRIGGER approval_only_for_future_meetings_trigger;
INSERT INTO HealthDeclarations VALUES (1, CURRENT_DATE, 37.6);
-- TEST
SELECT * FROM contact_tracing(1); -- Returns (2), (3), (4), (5)
SELECT * FROM Bookings ORDER BY date, start_hour, floor, room;
/*
Returns:
 floor | room |       date       |    start_hour    | creator_id | approver_id 
-------+------+------------------+------------------+------------+-------------
     1 |    1 | CURRENT_DATE - 2 |                1 |          1 |           2
     1 |    1 | CURRENT_DATE - 2 |                2 |          2 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2 |          4 |           2
     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1 |          1 |           2
     1 |    1 | CURRENT_DATE + 8 |                2 |          2 |           2
*/
SELECT * FROM Attends ORDER BY date, start_hour, floor, room, employee_id;
/*
Returns:
 employee_id | floor | room |       date       |    start_hour    
-------------+-------+------+------------------+------------------
           1 |     1 |    1 | CURRENT_DATE - 2 |                1
           2 |     1 |    1 | CURRENT_DATE - 2 |                1
           1 |     1 |    1 | CURRENT_DATE - 2 |                2
           2 |     1 |    1 | CURRENT_DATE - 2 |                2
           3 |     1 |    1 | CURRENT_DATE - 2 |                2
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           4 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           5 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 2
           1 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           4 |     1 |    1 | CURRENT_DATE     | CURRENT_HOUR - 1
           2 |     1 |    1 | CURRENT_DATE + 8 |                2
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST join_meeting
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
INSERT INTO Juniors VALUES (3);
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 2);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 10, 2),
    (1, 1, CURRENT_DATE + 1, 11, 2);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 10, 2);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
-- TEST
/* All tests below should return the tables below unless otherwise mentioned:

 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE + 1 |         10
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
(2 rows)

 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE + 1 |         11
           2 |     1 |    1 | CURRENT_DATE + 1 |         11
(2 rows)
*/
---- success
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 1);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting full
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 3);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: already joined
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE, 5);
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 1);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting non existent
CALL join_meeting(2, 2, CURRENT_DATE + 1, 10, 12, 3);    
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: cannot join meeting in the past
CALL join_meeting(1, 1, CURRENT_DATE - 1, 10, 11, 3);  
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE - 1, 10);
/* Expected table:
 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
(1 row)
*/
---- failure: non existent employee
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 100);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting approved
UPDATE Bookings SET approver_id = 1 WHERE ROW (floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
CALL join_meeting(1, 1, CURRENT_DATE + 1, 10, 11, 3);  
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST leave_meeting
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Junior 3', 'Contact 3', 'junior3@company.com', NULL, 1),
    (4, 'Junior 4', 'Contact 4', 'junior4@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Managers VALUES (1);
INSERT INTO Seniors VALUES (2);
INSERT INTO Juniors VALUES (3), (4);
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
COMMIT;
INSERT INTO Bookings VALUES 
    (1, 1, CURRENT_DATE + 1, 10, 2),
    (1, 1, CURRENT_DATE + 1, 11, 2);
INSERT INTO Attends VALUES 
    (3, 1, 1, CURRENT_DATE + 1, 10),
    (3, 1, 1, CURRENT_DATE + 1, 11),
    (4, 1, 1, CURRENT_DATE + 1, 10),
    (4, 1, 1, CURRENT_DATE + 1, 11),
    (1, 1, 1, CURRENT_DATE + 1, 10),
    (1, 1, 1, CURRENT_DATE + 1, 11);
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 10, 2);
INSERT INTO Attends VALUES (4, 1, 1, CURRENT_DATE - 1, 10);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
-- TEST
/* All tests below should return the tables below unless otherwise mentioned:
 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE + 1 |         10
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
           3 |     1 |    1 | CURRENT_DATE + 1 |         10
(3 rows)
 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           1 |     1 |    1 | CURRENT_DATE + 1 |         11
           2 |     1 |    1 | CURRENT_DATE + 1 |         11
           3 |     1 |    1 | CURRENT_DATE + 1 |         11
*/
---- success
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 4);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: employee trying to leave does not attend meeting
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 4);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting non existent
CALL leave_meeting(2, 2, CURRENT_DATE + 1, 10, 12, 3);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: non existent employee
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 100);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: meeting creator cannot leave
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 2);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
---- failure: cannot leave approve meeting
UPDATE Bookings SET approver_id = 1 WHERE ROW (floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
CALL leave_meeting(1, 1, CURRENT_DATE + 1, 10, 11, 3);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 10);
SELECT * FROM Attends WHERE ROW(floor, room, date, start_hour) = (1, 1, CURRENT_DATE + 1, 11);
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST approve_meeting_manager
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
INSERT INTO Departments VALUES (2, 'Department 2');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1),
    (3, 'Manager 3', 'Contact 3', 'manager3@company.com', NULL, 2);
INSERT INTO Superiors VALUES (1), (2), (3);
INSERT INTO Managers VALUES (1), (3);
INSERT INTO Seniors VALUES (2);
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
COMMIT;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 10, 2);
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE + 1, 11, 2);
-- TEST
/* All tests below should return the tables below unless otherwise mentioned:
 floor | room | date | start_hour | creator_id | approver_id
-------+------+------+------------+------------+-------------
(0 rows)
*/
---- failure: approver from different department
CALL approve_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 3); 
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
---- failure: approver does not exist
CALL approve_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 5); 
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
---- failure: approver is not a manager
CALL approve_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 2); 
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
---- failure: approving meeting that does not exist
CALL approve_meeting(2, 2, CURRENT_DATE + 1, 10, 12, 1); -- CALL still goes through
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
---- success
CALL approve_meeting(1, 1, CURRENT_DATE + 1, 10, 12, 1); 
SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
/*
cs2102_project=# SELECT * FROM Bookings WHERE approver_id IS NOT NULL;
 floor | room |       date       | start_hour | creator_id | approver_id
-------+------+------------------+------------+------------+-------------
     1 |    1 | CURRENT_DATE + 1 |         10 |          2 |           1
     1 |    1 | CURRENT_DATE + 1 |         11 |          2 |           1
(2 rows)
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST view_future_meeting
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Seniors VALUES (2);
INSERT INTO Managers VALUES (1);
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
COMMIT;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 10, 2);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 11, 1),
    (1, 1, CURRENT_DATE + 1, 10, 1),
    (1, 1, CURRENT_DATE + 2, 10, 2),
    (1, 1, CURRENT_DATE + 2, 11, 2);
INSERT INTO Attends VALUES
    (2, 1, 1, CURRENT_DATE + 1, 11),
    (2, 1, 1, CURRENT_DATE + 1, 10);
UPDATE Bookings SET approver_id = 1 WHERE date = CURRENT_DATE + 1;
-- TEST
SELECT * FROM Attends WHERE employee_id = 2;
/* Expected: 
 employee_id | floor | room |       date       | start_hour
-------------+-------+------+------------------+------------
           2 |     1 |    1 | CURRENT_DATE - 1 |         10
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
           2 |     1 |    1 | CURRENT_DATE + 1 |         11
           2 |     1 |    1 | CURRENT_DATE + 1 |         11
           2 |     1 |    1 | CURRENT_DATE + 1 |         10
(4 rows)
*/
SELECT * FROM view_future_meeting(CURRENT_DATE, 2);
/* Expected: 
 floor | room |       date       | start_hour
-------+------+------------------+------------
     1 |    1 | CURRENT_DATE + 1 |         10
     1 |    1 | CURRENT_DATE + 1 |         11
(2 rows)
*/
-- AFTER TEST
CALL reset();
-- END TEST

-- TEST view_manager_report
-- BEFORE TEST
CALL reset();
INSERT INTO Departments VALUES (1, 'Department 1');
BEGIN TRANSACTION;
INSERT INTO Employees VALUES
    (1, 'Manager 1', 'Contact 1', 'manager1@company.com', NULL, 1),
    (2, 'Superior 2', 'Contact 2', 'superior2@company.com', NULL, 1);
INSERT INTO Superiors VALUES (1), (2);
INSERT INTO Seniors VALUES (2);
INSERT INTO Managers VALUES (1);
ALTER TABLE Updates DISABLE TRIGGER update_capacity_not_in_past;
INSERT INTO MeetingRooms VALUES (1, 1, 'Room 1-1', 1);
INSERT INTO Updates VALUES (1, 1, 1, CURRENT_DATE - 1, 10);
ALTER TABLE Updates ENABLE TRIGGER update_capacity_not_in_past;
COMMIT;
ALTER TABLE Bookings DISABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends DISABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES (1, 1, CURRENT_DATE - 1, 10, 2);
ALTER TABLE Bookings ENABLE TRIGGER booking_date_check_trigger;
ALTER TABLE Attends ENABLE TRIGGER employee_join_only_future_meetings_trigger;
INSERT INTO Bookings VALUES
    (1, 1, CURRENT_DATE + 1, 11, 1),
    (1, 1, CURRENT_DATE + 1, 10, 1),
    (1, 1, CURRENT_DATE + 2, 10, 2),
    (1, 1, CURRENT_DATE + 2, 11, 2);
UPDATE Bookings SET approver_id = 1 WHERE ROW(date, start_hour) = (CURRENT_DATE + 2, 11);
-- TEST
SELECT * FROM Bookings;
/* Expected:
 floor | room |       date       | start_hour | creator_id | approver_id
-------+------+------------------+------------+------------+-------------
     1 |    1 | CURRENT_DATE - 1 |         10 |          2 |
     1 |    1 | CURRENT_DATE + 1 |         11 |          1 |
     1 |    1 | CURRENT_DATE + 1 |         10 |          1 |
     1 |    1 | CURRENT_DATE + 2 |         10 |          2 |
     1 |    1 | CURRENT_DATE + 2 |         11 |          2 |           1
(5 rows)
*/
SELECT * FROM view_manager_report(CURRENT_DATE, 1);
/* Expected:
 floor | room |       date       | start_hour | creator_id | approver_id
-------+------+------------------+------------+------------+-------------
     1 |    1 | CURRENT_DATE + 1 |         10 |          1 |
     1 |    1 | CURRENT_DATE + 1 |         11 |          1 |
     1 |    1 | CURRENT_DATE + 2 |         10 |          2 |
(3 rows)
*/
-- AFTER TEST
CALL reset();
-- END TEST

--
DROP PROCEDURE IF EXISTS reset();
SET client_min_messages TO NOTICE;
