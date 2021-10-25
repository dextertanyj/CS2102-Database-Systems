-- trigger 12 non-overlapping junior
CREATE OR REPLACE FUNCTION check_junior_insertion() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IN (SELECT id FROM Superiors) THEN
        RAISE EXCEPTION 'Employee % already exists in Superiors', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_junior ON Juniors;

CREATE TRIGGER non_overlap_junior
BEFORE INSERT ON Juniors
FOR EACH ROW EXECUTE FUNCTION check_junior_insertion();

-- trigger 12 non-overlapping senior
CREATE OR REPLACE FUNCTION check_senior_insertion() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id NOT IN (SELECT id FROM Superiors) THEN
        RAISE EXCEPTION 'Employee % does not exist in Superiors', NEW.id;
    ELSIF NEW.id IN (SELECT id FROM Managers) THEN
        RAISE EXCEPTION 'Employee % already exists in Managers', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_senior ON Seniors;

CREATE TRIGGER non_overlap_senior 
BEFORE INSERT ON Seniors
FOR EACH ROW EXECUTE FUNCTION check_senior_insertion();

-- trigger 12 non-overlapping manager
CREATE OR REPLACE FUNCTION check_manager_insertion() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id NOT IN (SELECT id FROM Superiors) THEN
        RAISE EXCEPTION 'Employee % does not exist in Superiors', NEW.id;
    ELSIF NEW.id IN (SELECT id FROM Seniors) THEN
        RAISE EXCEPTION 'Employee % already exists in Seniors', NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS non_overlap_manager ON Managers;

CREATE TRIGGER non_overlap_manager
BEFORE INSERT ON Managers
FOR EACH ROW EXECUTE FUNCTION check_manager_insertion();

-- trigger 12 insert into Employee -> insert into either Junior, Senior, Manager
CREATE OR REPLACE FUNCTION check_covering_employee() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.id NOT IN (
        SELECT id FROM Juniors UNION
        SELECT id FROM Seniors UNION
        SELECT id FROM Managers) THEN
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

-- trigger 22 only 1 approval per booking
CREATE OR REPLACE FUNCTION check_booking_approval() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.approver_id IS NOT NULL THEN
        RAISE EXCEPTION 'Booking (floor: %, room: %, date: %, start_hour: %) has already been approved', 
            OLD.floor, OLD.room, OLD.date, OLD.start_hour;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS booking_approval ON Bookings;

CREATE TRIGGER booking_approval
BEFORE UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_booking_approval();

-- trigger 23 no changes to attendance in already approved bookings
CREATE OR REPLACE FUNCTION check_attends_change() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN
        IF (SELECT approver_id FROM Bookings 
            WHERE floor = OLD.floor
                AND room = OLD.room
                AND date = OLD.date
                AND start_hour = OLD.start_hour) IS NOT NULL THEN
            RAISE EXCEPTION 'Booking (floor: %, room: %, date: %, start_hour: %) has already been approved.', 
                OLD.floor, OLD.room, OLD.date, OLD.start_hour;
        END IF;
        RETURN OLD;
    ELSE
        IF (SELECT approver_id FROM Bookings
            WHERE floor = NEW.floor
                AND room = NEW.room
                AND date = NEW.date
                AND start_hour = NEW.start_hour) IS NOT NULL THEN
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

-- trigger 24 Only managers in same departments have permission to change capacity
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
        RAISE EXCEPTION 'Unable to update or remove employee attendance'
    END IF;
    OLD = COALESCE(NEW, OLD);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_creator_removal_trigger ON Attends;

CREATE TRIGGER prevent_creator_removal_trigger
BEFORE DELETE OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION prevent_creator_removal();

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

CREATE OR REPLACE FUNCTION booking_date_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.date < CURRENT_DATE) THEN
        RAISE EXCEPTION 'Selected meeting date is in the past';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS booking_date_check_trigger ON Bookings;

CREATE TRIGGER booking_date_check_trigger
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION booking_date_check();
