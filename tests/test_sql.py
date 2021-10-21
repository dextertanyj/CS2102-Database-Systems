import pytest
import sqlalchemy
from sqlalchemy import create_engine
import os


########### Configure these ############
username = 'postgres'
password = 'postgres'
database = 'project'
########################################

sql_url = 'postgresql://{username}:{password}@localhost:5432/{database}'\
    .format(username=username, password=password, database=database)
engine = create_engine(sql_url)
no_quote_set = set(['NULL', 'CURRENT_DATE'])


def reset():
    with engine.connect() as con:
        con.execute("""
            TRUNCATE Departments CASCADE;
            TRUNCATE Employees CASCADE;
            TRUNCATE Juniors CASCADE;
            TRUNCATE Superiors CASCADE;
            TRUNCATE Seniors CASCADE;
            TRUNCATE Managers CASCADE;
            TRUNCATE HealthDeclarations CASCADE;
            TRUNCATE MeetingRooms CASCADE;
            TRUNCATE Bookings CASCADE;
            TRUNCATE Attends CASCADE;
            TRUNCATE Updates CASCADE;
        """)


def stringify(s):
    if s in no_quote_set:
        return s
    elif not isinstance(s, str):
        return str(s)
    else:
        return "'{0}'".format(s) 


def insert(tablename, values):
    """Create SQL Insert statements

    Attributes
    ----------
    tablename : str
        Name of table to be inserted into
    values : list of lists
        Values to be inserted
    """

    values_string_arr = []
    for value in values:
        value_string = '({string})'.format(string=', '.join([stringify(v) for v in value]))
        values_string_arr.append(value_string)
    values_string = ', '.join([v for v in values_string_arr])

    with engine.connect() as con:
        con.execute("""
            INSERT INTO {tablename} VALUES {values};
        """.format(tablename=tablename, values=values_string))


@pytest.fixture(scope='session', autouse=True)
def before_all():
    os.environ['PGPASSWORD'] = password
    os.system('psql -h localhost -U {username} -d {database} -f proc.sql'.format(username=username, database=database))


@pytest.fixture(autouse=True)
def before_each():
    reset()


def test_add_department():
    with engine.connect() as con:
        con.execute("CALL add_department(1, 'Department 1');")
        for r in con.execute("SELECT COUNT(*) FROM departments;"):
            assert r[0] == 1

        con.execute("CALL add_department(2, 'Department 1');")
        for r in con.execute("SELECT COUNT(*) FROM departments;"):
            assert r[0] == 2

        with pytest.raises(sqlalchemy.exc.IntegrityError):
            assert con.execute("CALL add_department(1, 'Department 1');") is not None


def test_remove_department():
    insert('Departments', [(1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3')])
    with engine.connect() as con:
        con.execute("""
            CALL remove_department(1, CURRENT_DATE);
            SELECT removal_date FROM Departments WHERE id = 1;
        """)
        with pytest.raises(sqlalchemy.exc.InternalError):
            assert con.execute("CALL remove_department(0, CURRENT_DATE);") is not None


def test_add_room():
    insert('Departments', [(1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3')])
    with engine.connect() as con:
        con.execute("""
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
        """)
        con.execute("""
            CALL add_room(1, 1, 'Room 1', 10, 1, CURRENT_DATE);
            CALL add_room(2, 1, 'Room 2', 10, 3, CURRENT_DATE);
        """)
        with pytest.raises(sqlalchemy.exc.IntegrityError):
            assert con.execute("""
                CALL add_room(1, 1, 'Room 3', 10, 1, CURRENT_DATE);
                CALL add_room(1, 1, 'Room 4', 10, 3, CURRENT_DATE);
                CALL add_room(3, 1, 'Room 5', 10, 4, CURRENT_DATE);
                CALL add_room(4, 1, 'Room 6', 10, 5, CURRENT_DATE);
                CALL add_room(5, 1, 'Room 7', 10, 6, CURRENT_DATE);
            """) is not None


def test_change_capacity():
    insert('Departments', [(1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3')])
    with engine.connect() as con:
        con.execute("""
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
        """)
        con.execute("""
            CALL change_capacity(1, 1, 20, 1, CURRENT_DATE);
            CALL change_capacity(1, 1, 30, 2, CURRENT_DATE);
        """)
        with pytest.raises(sqlalchemy.exc.InternalError):
            assert con.execute("""
                CALL change_capacity(1, 1, 40, 3, CURRENT_DATE);
                CALL change_capacity(2, 1, 50, 2, CURRENT_DATE);
            """) is not None


def test_add_employee():
    insert('Departments', [(1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3')])
    with engine.connect() as con:
        con.execute("""
            SELECT add_employee('John Doe', 'Contact 1', 'manager', 1);
            SELECT * FROM Managers AS M JOIN Employees AS E ON M.id = E.id WHERE M.id = 1;
            SELECT add_employee('John Doe', 'Contact 2', 'senior' , 1);
            SELECT * FROM Seniors AS S JOIN Employees AS E ON S.id = E.id WHERE S.id = 2;
            SELECT add_employee('Jane Doe', 'Contact 3', 'junior' , 1);
            SELECT * FROM Seniors AS J JOIN Employees AS E ON J.id = E.id WHERE J.id = 3;
        """)

        with pytest.raises(sqlalchemy.exc.IntegrityError):
            assert con.execute("""
                SELECT add_employee('John Doe', 'Contact 4', 'junior' , 4);
                SELECT add_employee('John Doe', 'Contact 5', 'Unknown' , 4);
            """) is not None


def test_remove_employees():
    insert('Departments', [(1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3')])
    insert('Employees', [
        (1, 'Manager 1', 'Contact 1', 'manager1@company.com', 'NULL', 1),
        (2, 'Manager 2', 'Contact 2', 'manager2@company.com', 'NULL', 2),
        (4, 'Senior 4', 'Contact 4', 'senior4@company.com', 'NULL', 1),
        (5, 'Junior 5', 'Contact 5', 'junior5@company.com', 'NULL', 1)
    ])
    with engine.connect() as con:
        con.execute("""INSERT INTO Employees VALUES 
            (3, 'Resigned Manager 3', 'Contact 3', 'manager3@company.com', CURRENT_DATE - 1, 1);
        """)
        con.execute("""
            CALL remove_employee(1, CURRENT_DATE); 
            SELECT E.resignation_date FROM Employees AS E WHERE E.id = 1; -- Returns CURRENT_DATE
            CALL remove_employee(3, CURRENT_DATE);
            SELECT E.resignation_date FROM Employees AS E WHERE E.id = 3; -- Returns CURRENT_DATE
        """)
        with pytest.raises(sqlalchemy.exc.InternalError):
            assert con.execute("CALL remove_employee(10, CURRENT_DATE);") is not None


if __name__ == '__main__':
    print("Something")
