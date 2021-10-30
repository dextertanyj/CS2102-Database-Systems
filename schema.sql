DROP TABLE IF EXISTS 
    Departments,
    Employees,
    MeetingRooms,
    Juniors,
    Superiors,
    Seniors,
    Managers,
    HealthDeclarations,
    Bookings,
    Attends,
    Updates
CASCADE;

CREATE TABLE Departments(
    id SERIAL,
    name VARCHAR(255) NOT NULL,
    removal_date DATE,
    PRIMARY KEY (id)
);

CREATE TABLE Employees(
    id SERIAL,
    name VARCHAR(255) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    resignation_date DATE,
    department_id INTEGER NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (department_id) REFERENCES Departments (id) ON DELETE NO ACTION ON UPDATE CASCADE
);

CREATE TABLE MeetingRooms(
    floor INTEGER,
    room INTEGER,
    name VARCHAR(255) NOT NULL,
    department_id INTEGER NOT NULL,
    PRIMARY KEY (floor, room),
    FOREIGN KEY (department_id) REFERENCES Departments (id) ON DELETE NO ACTION ON UPDATE CASCADE
);

CREATE TABLE Juniors(
    id INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES Employees (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Superiors(
    id INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES Employees (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Seniors(
    id INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES Superiors (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Managers(
    id INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES Superiors (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE HealthDeclarations(
    id INTEGER,
    date DATE,
    temperature NUMERIC(3, 1) NOT NULL,
    CHECK (34.0 <= temperature AND temperature <= 43.0),
    PRIMARY KEY (id, date),
    FOREIGN KEY (id) REFERENCES Employees (id) ON DELETE CASCADE ON UPDATE CASCADE
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
    FOREIGN KEY (floor, room) REFERENCES MeetingRooms (floor, room) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (creator_id) REFERENCES Superiors (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES Managers (id) ON DELETE NO ACTION ON UPDATE CASCADE
);

CREATE TABLE Attends(
    employee_id INTEGER,
    floor INTEGER,
    room INTEGER,
    date DATE,
    start_hour INTEGER,
    PRIMARY KEY (employee_id, floor, room, date, start_hour),
    UNIQUE (employee_id, date, start_hour),
    FOREIGN KEY (employee_id) REFERENCES Employees (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (floor, room , date, start_hour) REFERENCES Bookings (floor, room, date, start_hour) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE Table Updates(
    manager_id INTEGER NOT NULL,
    floor INTEGER,
    room INTEGER,
    date DATE,
    capacity INTEGER NOT NULL,
    CHECK (capacity >= 0),
    PRIMARY KEY (date, floor, room),
    FOREIGN KEY (manager_id) REFERENCES Managers (id) ON DELETE NO ACTION ON UPDATE CASCADE,
    FOREIGN KEY (floor, room) REFERENCES MeetingRooms (floor, room) ON DELETE CASCADE ON UPDATE CASCADE
);