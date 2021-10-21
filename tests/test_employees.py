import pytest
import sqlalchemy
from utils import engine, insert

def test_add_employee():
    insert('Departments', (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3'))
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
    insert('Departments', (1, 'Department 1'), (2, 'Department 2'), (3, 'Department 3'))
    insert('Employees',
        (1, 'Manager 1', 'Contact 1', 'manager1@company.com', 'NULL', 1),
        (2, 'Manager 2', 'Contact 2', 'manager2@company.com', 'NULL', 2),
        (4, 'Senior 4', 'Contact 4', 'senior4@company.com', 'NULL', 1),
        (5, 'Junior 5', 'Contact 5', 'junior5@company.com', 'NULL', 1)
    )
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
