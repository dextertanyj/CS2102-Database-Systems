import pytest
import config
from sqlalchemy import create_engine

url = 'postgresql://{username}:{password}@localhost:5432/{database}'\
    .format(username=config.username, password=config.password, database=config.database)
engine = create_engine(url)
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


def call(procedure, *args):
    arguments = ", ".join([stringify(v) for v in args])
    statement = "CALL {procedure}({arguments});".format(procedure=procedure, arguments=arguments)
    with engine.begin() as connection:
        connection.execute(statement)


def apply(function, *args):
    arguments = ", ".join([stringify(v) for v in args])
    statement = "SELECT * FROM {function}({arguments});".format(function=function, arguments=arguments)
    with engine.begin() as connection:
        result_set = connection.execute(statement)
        return result_set


def select(tablename, condition=None):
    criteria = ""
    if (condition is not None):
        criteria = "WHERE {condition}".format(condition=condition)
    statement = "SELECT * FROM {tablename} {criteria};".format(tablename=tablename, criteria=criteria)
    with engine.connect() as connection:
        return connection.execute(statement)


def select_all(tablename):
    return select(tablename)


def count(tablename, condition=None):
    return select(tablename, condition).rowcount


def count_all(tablename):
    return select_all(tablename).rowcount


def insert(tablename, *values):
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
