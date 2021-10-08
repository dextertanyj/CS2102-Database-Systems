DROP TABLE IF EXISTS Departments, Employees, MeetingRooms,
Juniors, Superiors, Seniors, Managers, HealthDeclarations,
Bookings, Attends, Updates;

CREATE TABLE Departments(
    id INTEGER,
    name VARCHAR(255) NOT NULL,
    removal_date DATE,
    PRIMARY KEY (did)
);

CREATE TABLE Employees(
    eid INTEGER,
    name VARCHAR(255) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    resignation_date DATE,
    department_id INTEGER NOT NULL,
    PRIMARY KEY (eid),
    FOREIGN KEY (did) REFERENCES Departments (did)
);

CREATE TABLE MeetingRooms(
    floor INTEGER,
    room INTEGER,
    name VARCHAR(255),
    did INTEGER NOT NULL,
    PRIMARY KEY (floor, room),
    FOREIGN KEY (did) REFERENCES Departments (did)
);

CREATE TABLE Juniors(
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Employees (eid) ON DELETE CASCADE
);

CREATE TABLE Superiors(
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Employees (eid) ON DELETE CASCADE
);

CREATE TABLE Seniors(
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Superiors (eid) ON DELETE CASCADE
);

CREATE TABLE Managers(
    eid INTEGER,
    PRIMARY KEY (eid),
    FOREIGN KEY (eid) REFERENCES Superiors (eid) ON DELETE CASCADE
);

CREATE TABLE HealthDeclarations(
    eid INTEGER,
    date DATE,
    temperature NUMERIC(3, 1) NOT NULL,
    CHECK (temperature > 0),
    PRIMARY KEY (eid, date),
    FOREIGN KEY (eid) REFERENCES Employees (eid) ON DELETE CASCADE
);

CREATE TABLE Bookings(
    floor INTEGER,
    room INTEGER,
    date DATE,
    start_hour INTEGER,
    creator_id INTEGER NOT NULL, -- superior
    approver_id INTEGER, -- manager
    CHECK (0 <= start_hour AND start_hour <= 23),
    PRIMARY KEY (floor, room, date, start_hour),
    FOREIGN KEY (floor, room) REFERENCES MeetingRooms (floor, room) ON DELETE CASCADE,
    FOREIGN KEY (creator_id) REFERENCES Superiors (eid),
    FOREIGN KEY (approver_id) REFERENCES Managers (eid)
);

CREATE TABLE Attends(
    employee_id INTEGER,
    floor INTEGER,
    room INTEGER,
    date DATE,
    start_hour INTEGER,
    PRIMARY KEY (eid, floor, room, date, start_hour),
    FOREIGN KEY (eid) REFERENCES Employees (eid),
    FOREIGN KEY (floor, room , date, start_hour) REFERENCES Bookings (floor, room, date, start_hour)
);

CREATE Table Updates(
    manager_id INTEGER,
    floor INTEGER,
    room INTEGER,
    date DATE,
    capacity INTEGER NOT NULL,
    CHECK (capacity >= 0),
    PRIMARY KEY (eid, date, floor, room),
    FOREIGN KEY (eid) REFERENCES Managers (eid),
    FOREIGN KEY (floor, room) REFERENCES MeetingRooms (floor, room)
);