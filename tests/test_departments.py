import pytest
import sqlalchemy
from datetime import date
from utils import insert, call, select, count_all

@pytest.fixture(autouse=True)
def before_each():
    insert('Departments', (1, 'Department 1'), (2, 'Department 2'))


def test_add_department():
    call("add_department", 3, "Department 3")
    assert count_all("departments") == 3


def test_add_department_same_name_success():
    call("add_department", 3, "Department 1")
    assert count_all("departments") == 3


def test_add_department_same_id_failure():
    with pytest.raises(sqlalchemy.exc.IntegrityError):
        call("add_department", 1, "Department 3")


def test_remove_department():
    call("remove_department", 1, "CURRENT_DATE")
    assert select("departments", condition="id = 1").first()['removal_date'] == date.today()


def test_remove_department_invalid_id_failure():
    with pytest.raises(sqlalchemy.exc.DBAPIError) as exception:
        call("remove_department", 3, "CURRENT_DATE")
    assert str(exception.value.orig).split("\n")[0] == "Department not found"
