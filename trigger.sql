 -- trigger 34 resigned employees no longer allowed to book or approve or attend any meeting, and cannot declare temperature 
-- Meeting room booking or approval
CREATE OR REPLACE FUNCTION check_resignation_status_for_booking_creation_or_approval() RETURNS TRIGGER AS $$
DECLARE
	creator_resignation_date DATE := NULL;
	approver_resignation_date DATE := NULL;
BEGIN
	SELECT resignation_date INTO creator_resignation_date FROM Employees e WHERE e.id = NEW.creator_id;
	SELECT resignation_date INTO approver_resignation_date FROM Employees e WHERE e.id = NEW.approver_id;
	IF (creator_resignation_date IS NOT NULL AND approver_resignation_date IS NOT NULL) THEN
		RAISE NOTICE 'Both employees booking and approving the meeting have resigned.';
		RETURN NULL;
	ELSIF (creator_resignation_date IS NOT NULL) THEN
		RAISE NOTICE 'Employee attempting to book meeting has resigned.';
		RETURN NULL;
	ELSIF (approver_resignation_date IS NOT NULL) THEN
		RAISE NOTICE 'Employee attempting to approve meeting has resigned.';
		RETURN NULL;
	END IF ;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER can_create_or_approve_meeting
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW EXECUTE FUNCTION check_resignation_status_for_booking_creation_or_approval();

-- Health declaration
CREATE OR REPLACE FUNCTION check_resignation_status_for_health_declaration() RETURNS TRIGGER AS $$
DECLARE
	employee_resignation_date DATE := NULL;
BEGIN
	SELECT resignation_date INTO employee_resignation_date FROM Employees e WHERE e.id = NEW.id;
	IF (employee_resignation_date IS NOT NULL) THEN
		RAISE NOTICE 'Employee attempting to declare temperature has resigned.';
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER can_declare_health
BEFORE INSERT OR UPDATE ON HealthDeclarations
FOR EACH ROW EXECUTE FUNCTION check_resignation_status_for_health_declaration();

-- Attends meeting
CREATE OR REPLACE FUNCTION check_resignation_status_for_attendance() RETURNS TRIGGER AS $$
DECLARE
	employee_resignation_date DATE := NULL;
BEGIN
	SELECT resignation_date INTO employee_resignation_date FROM Employees e WHERE e.id = NEW.employee_id;
	IF (employee_resignation_date IS NOT NULL) THEN
		RAISE NOTICE 'Employee attempting to attend meeting has resigned.';
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER can_attend_meeting
BEFORE INSERT OR UPDATE ON Attends
FOR EACH ROW EXECUTE FUNCTION check_resignation_status_for_attendance();

-- Update meeting room capacity
CREATE OR REPLACE FUNCTION check_resignation_status_for_updates() RETURNS TRIGGER AS $$
DECLARE
	employee_resignation_date DATE := NULL;
BEGIN
	SELECT resignation_date INTO employee_resignation_date FROM Employees e WHERE e.id = NEW.manager_id;
	IF (employee_resignation_date IS NOT NULL) THEN
		RAISE NOTICE 'Employee attempting to update meeting room capacity has resigned.';
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER can_update_room
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION check_resignation_status_for_updates();