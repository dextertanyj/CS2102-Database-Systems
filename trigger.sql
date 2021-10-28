/******************************************************************************
* E-5 Each employee must be one and only one of the three kinds of employees. *
******************************************************************************/
-- Non Overlap Constraints
-- Insert or update of Juniors -> Must not exist in Superiors
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

-- Insert or update of Superiors -> Must not exist in Juniors
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

-- Insert or update of Seniors -> Must not exist in Managers
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

-- Insert or update of Managers -> Must not exist in Seniors
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

-- Covering Constraints

-- Insert Cases

-- Insert into Employees -> Must exist in either Juniors or Superiors
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

-- Insert into Superiors -> Must exist in either Seniors or Managers
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

-- Delete Cases

-- Delete from Junior or Superior -> Must exist in either Juniors or Superiors
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

-- Delete from Manager or Senior -> Either does not exist in Superior or must exist in either Seniors or Managers
CREATE OR REPLACE FUNCTION existing_superior_covering_check() RETURNS TRIGGER AS $$
BEGIN
    -- If OLD employee is not in Superiors, then they must have been deleted from Superiors.
    -- The delete from Junior or Superior case will handle constraint checking.
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

/******************************************************************************
*                                   END E-5                                   *
******************************************************************************/

-- A-4 Once approved, there should be no more changes in the participants and the participants will definitely attend the meeting.
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

-- C-1 A manager from the same department as the meeting room may change the meeting room capacity.
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

-- C-4 A meeting room can only have its capacity updated for a date not in the past, i.e. in the present or the future.
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

-- B-12 When an employee resigns, they are no longer allowed to book any meetings.
CREATE OR REPLACE FUNCTION check_resigned_creator() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.creator_id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Unable to book meeting as employee has resigned';
	END IF ;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_creator_trigger ON Bookings;

CREATE TRIGGER check_resigned_creator_trigger
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_resigned_creator();

-- B-13 When an employee resigns, they are no longer allowed to approve any meetings.
CREATE OR REPLACE FUNCTION check_resigned_approver() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.approver_id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Unable to approve meeting as employee has resigned';
	END IF ;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_approver_trigger ON Bookings;

CREATE TRIGGER check_resigned_approver_trigger
BEFORE INSERT OR UPDATE OF approver_id ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_resigned_approver();

-- H-6 When an employee resigns, they are no longer allowed to make any health declarations.
CREATE OR REPLACE FUNCTION check_resigned_health_declaration() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Unable to declare health status as employee has resigned';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_health_delcaration_trigger ON HealthDeclarations;

CREATE TRIGGER check_resigned_health_declaration_trigger
BEFORE INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION check_resigned_health_delcaration();

-- A-5 When an employee resigns, they are no longer allowed to join any booked meetings.
CREATE OR REPLACE FUNCTION check_resigned_attends() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.employee_id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee attempting to attend meeting has resigned.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_attends_trigger ON Attends;

CREATE TRIGGER check_resigned_attends_trigger
BEFORE INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_resigned_attends();

-- C-3 When an employee resigns, they are no longer allowed to change any meeting room capacities.
CREATE OR REPLACE FUNCTION check_resigned_updates() RETURNS TRIGGER AS $$
DECLARE
	resignation_date DATE := NULL;
BEGIN
	SELECT E.resignation_date INTO resignation_date FROM Employees AS E WHERE E.id = NEW.manager_id;
	IF (resignation_date IS NOT NULL) THEN
		RAISE EXCEPTION 'Employee attempting to update meeting room capacity has resigned.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_resigned_updates_trigger ON Updates;

CREATE TRIGGER check_resigned_updates_trigger
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_resigned_updates();

-- B-5 The employee booking the room immediately joins the booked meeting.
CREATE OR REPLACE FUNCTION insert_meeting_creator()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.creator_id IS DISTINCT FROM OLD.creator_id) THEN
        IF (TG_OP = 'UPDATE') THEN
            DELETE FROM Attends WHERE employee_id = OLD.creator_id AND floor = OLD.floor AND room = OLD.room AND date = OLD.date AND start_hour = OLD.start_hour;
        END IF;
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
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insert_meeting_creator_trigger ON Bookings;

CREATE TRIGGER insert_meeting_creator_trigger
AFTER INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION insert_meeting_creator();

-- B-15 A meeting must be attended by its creator.
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

-- B-7 A manager can only approve a booked meeting if the meeting room used is in the same department as the manager.
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

-- B-4 A booking can only be made for future meetings.
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

-- B-8 An approval can only be made for future meetings.
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

-- A-2 An employee can only join future meetings.
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

-- H-7 A health declaration cannot be made for any date other than the current date.
-- H-8 Past health declarations cannot be modified.
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

-- MR-4 Each meeting room must have at least one relevant capacities entry.
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

-- C-2 If a meeting room has its capacity changed, all future meetings that exceed the new capacity will be removed.
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

-- A-6 The number of people attending a meeting should not exceed the latest past capacity declared.
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

-- B-14 A approved booked meeting can no longer have any of its details changed, except for the revocation of its approver.
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

CREATE OR REPLACE FUNCTION resigned_employee_cleanup()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.resignation_date IS NOT NULL) THEN
        DELETE FROM Bookings AS B WHERE B.date > NEW.resignation_date AND B.creator_id = NEW.id;
        DELETE FROM Attends AS A WHERE A.date > NEW.resignation_date AND A.employee_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS resigned_employee_cleanup_trigger ON Employees;

CREATE TRIGGER resigned_employee_cleanup_trigger
AFTER INSERT OR UPDATE OF resignation_date ON Employees
FOR EACH ROW EXECUTE FUNCTION resigned_employee_cleanup()

