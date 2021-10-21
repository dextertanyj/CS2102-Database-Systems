import pytest
import sqlalchemy
from utils import engine, insert

def test_add_room():
    insert('Departments', (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3'))
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
    insert('Departments', (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3'))
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
