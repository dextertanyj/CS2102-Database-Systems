-------------------------- E5 -----------------------------
-- Insert and Update of Juniors -> cannot exist in Superiors
CREATE OR REPLACE FUNCTION check_junior_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Superiors) THEN
        RAISE EXCEPTION 'Employee % already exists in Superiors', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_junior ON Juniors;

CREATE TRIGGER non_overlap_junior
BEFORE INSERT OR UPDATE ON Juniors
FOR EACH ROW EXECUTE FUNCTION check_junior_overlap();

-- Insert and Update of Seniors -> must exist in Superiors, cannot exist in Managers
CREATE OR REPLACE FUNCTION check_senior_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Managers) THEN
        RAISE EXCEPTION 'Employee % already exists in Managers', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_senior ON Seniors;

CREATE TRIGGER non_overlap_senior 
BEFORE INSERT OR UPDATE ON Seniors
FOR EACH ROW EXECUTE FUNCTION check_senior_overlap();

-- Insert and Update of Managers -> must exist in Superiors, cannot exist in Seniors
CREATE OR REPLACE FUNCTION check_manager_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Seniors) THEN
        RAISE EXCEPTION 'Employee % already exists in Seniors', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_manager ON Managers;

CREATE TRIGGER non_overlap_manager
BEFORE INSERT OR UPDATE ON Managers
FOR EACH ROW EXECUTE FUNCTION check_manager_overlap();

-- Insert and Update of Superiors -> cannot exist in Juniors
CREATE OR REPLACE FUNCTION check_superior_overlap() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Juniors) THEN
        RAISE EXCEPTION 'Employee % already exists in Juniors', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_superior ON Superiors;

CREATE TRIGGER non_overlap_superior
BEFORE INSERT OR UPDATE ON Superiors
FOR EACH ROW EXECUTE FUNCTION check_superior_overlap();
-------------------Covering---------------------
--------------------INSERT CASES-------------------
-- Insert into Superior -> insert into either Senior or Manager
CREATE OR REPLACE FUNCTION check_covering_superior() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.id NOT IN (
        SELECT id FROM Seniors UNION
        SELECT id FROM Managers) THEN
		RAISE EXCEPTION 'Superior % must exist either as Senior or Manager', NEW.id;
	END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS covering_superior_constraint ON Superiors;

CREATE CONSTRAINT TRIGGER covering_superior_constraint 
AFTER INSERT ON Superiors 
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_covering_superior();

-- Insert into Employee -> insert into either Junior or Superior
CREATE OR REPLACE FUNCTION check_covering_employee() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.id NOT IN (
        SELECT id FROM Juniors UNION
        SELECT id FROM Superiors) THEN
		RAISE EXCEPTION 'Employee % must exist either as Junior, Senior or Manager', NEW.id;
	END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS covering_employee_constraint ON Employees;

CREATE CONSTRAINT TRIGGER covering_employee_constraint 
AFTER INSERT ON Employees
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_covering_employee();

------------------DELETE CASES--------------------------

-- After delete junior or superior, ensure exists in either.
CREATE OR REPLACE FUNCTION existing_employee_covering_check() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.id NOT IN (SELECT id FROM Superiors UNION SELECT id FROM Juniors) THEN
        RAISE EXCEPTION 'Employee % does not have a rank', OLD.id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_junior_trigger ON Juniors;

CREATE CONSTRAINT TRIGGER delete_junior_trigger
AFTER UPDATE OR DELETE ON Juniors
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION existing_employee_covering_check();

DROP TRIGGER IF EXISTS delete_superior_trigger ON Superiors;

CREATE CONSTRAINT TRIGGER delete_superior_trigger
AFTER UPDATE OR DELETE ON Superiors
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION existing_employee_covering_check();


-- After delete manager or senior, ensure does not exist in superior OR exists in either.
CREATE OR REPLACE FUNCTION existing_superior_covering_check() RETURNS TRIGGER AS $$
BEGIN
    -- If OLD employee is not in superiors, then he must have been deleted by superiors.
    -- The junior-superiors delete will handle the case for us.
    IF (SELECT id FROM Superiors WHERE id = OLD.id) IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    IF OLD.id NOT IN (SELECT id FROM Seniors UNION SELECT id FROM Managers) THEN
        RAISE EXCEPTION 'Employee % does not have a rank', OLD.id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_senior_trigger ON Seniors;

CREATE CONSTRAINT TRIGGER delete_senior_trigger
AFTER UPDATE OR DELETE ON Seniors 
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION existing_superior_covering_check();

DROP TRIGGER IF EXISTS delete_manager_trigger ON Managers;

CREATE CONSTRAINT TRIGGER delete_manager_trigger
AFTER DELETE ON Managers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION existing_superior_covering_check();

-------------------------- E5 -----------------------------

-- A4 no changes to attendance in already approved bookings
CREATE OR REPLACE FUNCTION check_attends_change() RETURNS TRIGGER AS $$
DECLARE
    old_approver_id INT;
    new_approver_id INT;
BEGIN
    SELECT approver_id INTO old_approver_id FROM Bookings 
    WHERE floor = OLD.floor
        AND room = OLD.room
        AND date = OLD.date
        AND start_hour = OLD.start_hour;
    SELECT approver_id INTO new_approver_id FROM Bookings
    WHERE floor = NEW.floor
        AND room = NEW.room
        AND date = NEW.date
        AND start_hour = NEW.start_hour;
    
    IF TG_OP = 'DELETE' THEN
        IF old_approver_id IS NOT NULL THEN
            IF OLD.date >= (SELECT resignation_date FROM Employees WHERE id = OLD.employee_id) THEN
                RETURN OLD;
            END IF;
            RAISE EXCEPTION 'Booking (floor: %, room: %, date: %, start_hour: %) has already been approved.', 
                OLD.floor, OLD.room, OLD.date, OLD.start_hour;
        END IF;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF old_approver_id IS NOT NULL THEN
            RAISE EXCEPTION 'Previous booking (floor: %, room: %, date: %, start_hour: %) has already been approved.', 
                OLD.floor, OLD.room, OLD.date, OLD.start_hour;
        END IF;
        IF new_approver_id IS NOT NULL THEN
            RAISE EXCEPTION 'Incoming booking (floor: %, room: %, date: %, start_hour: %) has already been approved.', 
                NEW.floor, NEW.room, NEW.date, NEW.start_hour;
        END IF;
        RETURN NEW;
    ELSE
        IF new_approver_id IS NOT NULL THEN
            RAISE EXCEPTION 'Booking (floor: %, room: %, date: %, start_hour: %) has already been approved.', 
                NEW.floor, NEW.room, NEW.date, NEW.start_hour;           
        END IF;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lock_attends ON Attends;

CREATE TRIGGER lock_attends
BEFORE DELETE OR INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_attends_change();

-- C1 Only managers in same departments have permission to change capacity
CREATE OR REPLACE FUNCTION check_update_capacity_perms() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT department_id FROM Employees WHERE id = NEW.manager_id) <>
        (SELECT department_id FROM MeetingRooms WHERE floor = NEW.floor AND room = NEW.room) THEN
        RAISE EXCEPTION 'Manager does not have permissions to update this room';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_capacity_perms ON Updates;

CREATE TRIGGER update_capacity_perms
BEFORE INSERT ON Updates
FOR EACH ROW EXECUTE FUNCTION check_update_capacity_perms();

-- C4 Meeting room can only have updates on capacity not in the past (in the present and future)
CREATE OR REPLACE FUNCTION check_update_capacity_time() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Meeting room capacity cannot be changed in the past';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_capacity_not_in_past ON Updates;

CREATE TRIGGER update_capacity_not_in_past
BEFORE INSERT ON Updates
FOR EACH ROW EXECUTE FUNCTION check_update_capacity_time();

 -- trigger 34 resigned employees no longer allowed to book or approve or attend any meeting, and cannot declare temperature 
-- Meeting room booking or approval
CREATE OR REPLACE FUNCTION check_resignation_booking_create_approve() RETURNS TRIGGER AS $$
DECLARE
	creator_resignation_date DATE := NULL;
	approver_resignation_date DATE := NULL;
BEGIN
	SELECT resignation_date INTO creator_resignation_date FROM Employees e WHERE e.id = NEW.creator_id;
	SELECT resignation_date INTO approver_resignation_date FROM Employees e WHERE e.id = NEW.approver_id;
	IF (creator_resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee attempting to book meeting has resigned.';
	ELSIF (approver_resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee attempting to approve meeting has resigned.';
	END IF ;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resignation_booking_create_approve_trigger ON Bookings;
CREATE TRIGGER check_resignation_booking_create_approve_trigger
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_resignation_booking_create_approve();

-- Health declaration
CREATE OR REPLACE FUNCTION check_resignation_health_declaration() RETURNS TRIGGER AS $$
DECLARE
	employee_resignation_date DATE := NULL;
BEGIN
	SELECT resignation_date INTO employee_resignation_date FROM Employees e WHERE e.id = NEW.id;
	IF (employee_resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee attempting to declare temperature has resigned.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resignation_health_declaration_trigger ON HealthDeclarations;
CREATE TRIGGER check_resignation_health_declaration_trigger
BEFORE INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION check_resignation_health_declaration();

-- Attends meeting
CREATE OR REPLACE FUNCTION check_resignation_attend() RETURNS TRIGGER AS $$
DECLARE
	employee_resignation_date DATE := NULL;
BEGIN
	SELECT resignation_date INTO employee_resignation_date FROM Employees e WHERE e.id = NEW.employee_id;
	IF (employee_resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee attempting to attend meeting has resigned.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resignation_attend_trigger ON Attends;
CREATE TRIGGER check_resignation_attend_trigger
BEFORE INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_resignation_attend();

-- Update meeting room capacity
CREATE OR REPLACE FUNCTION check_resignation_updates() RETURNS TRIGGER AS $$
DECLARE
	employee_resignation_date DATE := NULL;
BEGIN
	SELECT resignation_date INTO employee_resignation_date FROM Employees e WHERE e.id = NEW.manager_id;
	IF (employee_resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee attempting to update meeting room capacity has resigned.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resignation_updates_trigger ON Updates;
CREATE TRIGGER check_resignation_updates_trigger
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_resignation_updates();

CREATE OR REPLACE FUNCTION insert_meeting_creator()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM Attends WHERE employee_id = OLD.creator_id AND floor = OLD.floor AND room = OLD.room AND date = OLD.date AND start_hour = OLD.start_hour;
    IF (NOT EXISTS 
        (SELECT * 
        FROM Attends AS A 
        WHERE A.employee_id = NEW.creator_id 
            AND A.room = NEW.room 
            AND A.floor = NEW.floor 
            AND A.date = NEW.date 
            AND A.start_hour = NEW.start_hour)
    ) THEN
        INSERT INTO Attends VALUES (NEW.creator_id, NEW.floor, NEW.room, NEW.date, NEW.start_hour);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insert_meeting_creator_trigger ON Bookings;

CREATE TRIGGER insert_meeting_creator_trigger
AFTER INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION insert_meeting_creator();

CREATE OR REPLACE FUNCTION prevent_creator_removal()
RETURNS TRIGGER AS $$
BEGIN
    IF (EXISTS
        (SELECT * 
        FROM Bookings AS B 
        WHERE B.creator_id = OLD.employee_id 
            AND B.room = OLD.room 
            AND B.floor = OLD.floor 
            AND B.date = OLD.date 
            AND B.start_hour = OLD.start_hour)
    ) THEN
        RAISE EXCEPTION 'Unable to update or remove employee attendance';
    END IF;
    OLD = COALESCE(NEW, OLD);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_creator_removal_trigger ON Attends;

CREATE TRIGGER prevent_creator_removal_trigger
BEFORE DELETE OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION prevent_creator_removal();

-- Trigger B-7: A manager can only approve a booked meeting if the meeting room used is in the same department as the manager.
CREATE OR REPLACE FUNCTION meeting_approver_department_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.approver_id IS NOT NULL AND
        ((SELECT department_id FROM Employees AS E WHERE E.id = NEW.approver_id)
        IS DISTINCT FROM 
        (SELECT department_id FROM MeetingRooms AS M WHERE M.floor = NEW.floor AND M.room = NEW.room))
    ) THEN 
        RAISE EXCEPTION 'Manager does not have permissions to approve selected meeting';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS meeting_approver_department_check_trigger ON Bookings;

CREATE TRIGGER meeting_approver_department_check_trigger
BEFORE INSERT OR UPDATE OF approver_id ON Bookings
FOR EACH ROW EXECUTE FUNCTION meeting_approver_department_check();

-- Trigger B-4: A booking can only be made for future meetings.
CREATE OR REPLACE FUNCTION booking_date_check()
RETURNS TRIGGER AS $$
BEGIN
    IF ((NEW.date < CURRENT_DATE) OR (NEW.date = CURRENT_DATE AND NEW.start_hour <= extract(HOUR FROM CURRENT_TIME))) THEN
        RAISE EXCEPTION 'Booking date and time must be in the future';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS booking_date_check_trigger ON Bookings;

CREATE TRIGGER booking_date_check_trigger
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION booking_date_check();

-- Trigger B-8: An approval can only be made for future meetings.
CREATE OR REPLACE FUNCTION approval_only_for_future_meetings_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_hours_into_the_day INT := DATE_PART('HOUR', CURRENT_TIMESTAMP);
BEGIN
    IF (NEW.approver_id IS NOT NULL AND (NEW.date < CURRENT_DATE OR (NEW.date = CURRENT_DATE AND NEW.start_hour <= current_hours_into_the_day))) THEN
        RAISE EXCEPTION 'Cannot approve or update meetings of the past';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS approval_only_for_future_meetings_trigger ON Bookings;

CREATE TRIGGER approval_only_for_future_meetings_trigger
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION approval_only_for_future_meetings_trigger();

-- Trigger A-2: an employee can only join future meetings.
CREATE OR REPLACE FUNCTION employee_join_only_future_meetings_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_hours_into_the_day INT := DATE_PART('HOUR', CURRENT_TIMESTAMP);
BEGIN
    IF (NEW.date < CURRENT_DATE OR (NEW.date = CURRENT_DATE AND NEW.start_hour <= current_hours_into_the_day)) THEN
        RAISE EXCEPTION 'Cannot join meetings in the past';
END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS employee_join_only_future_meetings_trigger ON Attends;

CREATE TRIGGER employee_join_only_future_meetings_trigger
BEFORE INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION employee_join_only_future_meetings_trigger();


CREATE OR REPLACE FUNCTION health_declaration_date_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.date <> CURRENT_DATE) THEN
        RAISE EXCEPTION 'Health declaration must be for today';
    END IF;
    IF (TG_OP = 'UPDATE' AND OLD.date <> CURRENT_DATE) THEN
        RAISE EXCEPTION 'Unable to ammend past health declaration records';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS health_declaration_date_check_trigger ON HealthDeclarations;

CREATE TRIGGER health_declaration_date_check_trigger
BEFORE INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION health_declaration_date_check();

CREATE OR REPLACE FUNCTION check_meeting_room_updates()
RETURNS TRIGGER AS $$
BEGIN
    IF(NOT EXISTS(SELECT * FROM Updates AS U WHERE U.floor = NEW.floor AND U.room = NEW.room)) THEN
        RAISE EXCEPTION 'Meeting room must have an assigned capacity';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_meeting_room_updates_trigger ON MeetingRooms;

CREATE CONSTRAINT TRIGGER check_meeting_room_updates_trigger 
AFTER INSERT OR UPDATE ON MeetingRooms
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_meeting_room_updates();

-- Trigger C-2: If a meeting room has its capacity changed, all future meetings that exceed the new capacity will be removed.
CREATE OR REPLACE FUNCTION check_future_meetings_on_capacity_change_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_hours_into_the_day INT := DATE_PART('HOUR', CURRENT_TIMESTAMP);
BEGIN
    DELETE FROM Bookings 
    WHERE ROW(floor, room, date, start_hour) IN 
    (SELECT a.floor, a.room, a.date, a.start_hour
        FROM Attends a
        WHERE a.date > NEW.date OR (a.date = NEW.date AND a.start_hour > current_hours_into_the_day)
        GROUP BY a.floor, a.room, a.date, a.start_hour
        HAVING count(a.employee_id) > NEW.capacity);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_future_meetings_on_capacity_change_trigger ON Updates;

CREATE TRIGGER check_future_meetings_on_capacity_change_trigger
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_future_meetings_on_capacity_change_trigger();

-- Trigger A-6: The number of people attending a meeting should not exceed the latest past capacity declared.
CREATE OR REPLACE FUNCTION check_meeting_capacity_trigger()
RETURNS TRIGGER AS $$
DECLARE 
    room_capacity INT := (SELECT capacity 
                            FROM RoomCapacities(NEW.date)
                            WHERE floor = NEW.floor
                            AND room = NEW.room);
                            
    current_room_count INT := (SELECT COUNT(*)
                                FROM Attends 
                                WHERE floor = NEW.floor
                                AND room = NEW.room
                                AND date = NEW.date
                                AND start_hour = NEW.start_hour);
BEGIN
    IF TG_OP = 'INSERT' AND current_room_count >= room_capacity THEN
        RAISE EXCEPTION 'Cannot attend booking due to meeting room capacity limit reached';
    ELSIF TG_OP = 'UPDATE' AND current_room_count >= room_capacity AND (NEW.floor <> OLD.floor OR NEW.room <> OLD.room OR NEW.date <> OLD.date OR NEW.start_hour <> OLD.start_hour) THEN
        RAISE EXCEPTION 'Cannot attend booking due to meeting room capacity limit reached';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_meeting_capacity_trigger ON Attends;

CREATE TRIGGER check_meeting_capacity_trigger
BEFORE INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_meeting_capacity_trigger();

CREATE OR REPLACE FUNCTION lock_details_approved_bookings()
RETURNS TRIGGER AS $$
DECLARE
    resignation_date DATE := NULL;
BEGIN
    IF (OLD.approver_id IS NULL) THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = OLD.approver_id;
    IF (resignation_date < OLD.date AND OLD.approver_id IS DISTINCT FROM NEW.approver_id) THEN
        RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Unable to modify approved booking';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lock_details_approved_bookings_trigger ON Bookings;

CREATE TRIGGER lock_details_approved_bookings_trigger
BEFORE UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION lock_details_approved_bookings();

-- E-11 When a department has been removed, employees cannot be added to it.
-- MR-5 When a department has been removed, meeting rooms cannot be added to it.
CREATE OR REPLACE FUNCTION lock_removed_department()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.department_id IS NOT DISTINCT FROM OLD.department_id) THEN
        RETURN NEW;
    END IF;
    IF ((SELECT removal_date FROM Departments AS D WHERE D.id = NEW.department_id) IS NOT NULL) THEN
        RAISE EXCEPTION 'Department % has already been removed', NEW.department_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS lock_removed_department_employees_trigger ON Employees;

CREATE TRIGGER lock_removed_department_employees_trigger
BEFORE INSERT OR UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION lock_removed_department();

DROP TRIGGER IF EXISTS lock_removed_department_meeting_rooms_trigger ON MeetingRooms;

CREATE TRIGGER lock_removed_department_meeting_rooms_trigger
BEFORE INSERT OR UPDATE ON MeetingRooms
FOR EACH ROW EXECUTE FUNCTION lock_removed_department();
