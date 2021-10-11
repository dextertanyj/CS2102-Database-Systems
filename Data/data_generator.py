import pandas as pd
import random
from faker import Faker
from collections import defaultdict
from sqlalchemy import create_engine

# Set up Python to PSQL connection
username = 'postgres'
password = 'rlps2008'
database = 'project'
path = 'postgresql://' + username + ':' + password + '@localhost:5432/' + database
engine = create_engine(path)
fake = Faker('en_GB')

# Generate departments table 
department_data = defaultdict(list)
for _ in range(20):
    department_data['name'].append(fake.company())
    # Generate random removal_date with an arbitrarily chosen 10% chance
    if (random.random() < 0.1):
        department_data['removal_date'].append(fake.date_between(start_date='-5y', end_date='today'))
    else:
        department_data['removal_date'].append(None)
df_department_data = pd.DataFrame(department_data)
# Rename index to id for SQL table
df_department_data.index.names = ['id']
df_department_data.to_sql(name = 'departments', con = engine, if_exists = 'append')

# Generate employees table
employee_data = defaultdict(list)
for _ in range(20):
    first_name = fake.first_name()
    last_name = fake.last_name()
    employee_data['name'].append(first_name + ' ' + last_name)
    employee_data['contact_number'].append(fake.phone_number())
    employee_data['email'].append(first_name.lower() + '.' + last_name.lower() + '@' + fake.free_email_domain())
    # Generate random resignation_date with an arbitrarily chosen 10% chance
    if (random.random() < 0.1):
        employee_data['resignation_date'].append(fake.date_between(start_date='-5y', end_date='today'))
    else:
        employee_data['resignation_date'].append(None)
    employee_data['department_id'].append(random.randint(0,19))
df_employee_data = pd.DataFrame(employee_data)
# Rename index to id for SQL table
df_employee_data.index.names = ['id']
df_employee_data.to_sql(name = 'employees', con = engine, if_exists = 'append')

# Generate meetingrooms table
meeting_room_data = defaultdict(list)
floor = 1
room = 1
for _ in range(20):
    if (room == 10):
        room = 1
        floor = floor + 1
    meeting_room_data['floor'].append(floor)
    meeting_room_data['room'].append(room)
    meeting_room_data['name'].append('#0' + str(floor) + '-0' + str(room))
    room = room + 1
    meeting_room_data['department_id'].append(random.randint(0,19))
# set_index removes the default incremental index
df_meeting_room_data = pd.DataFrame(meeting_room_data).set_index('floor')
df_meeting_room_data.to_sql(name = 'meetingrooms', con = engine, if_exists = 'append')

# Generate juniors table
junior_data = defaultdict(list)
employee_id_junior = 0
for _ in range(10):
    junior_data['id'].append(employee_id_junior)
    employee_id_junior = employee_id_junior + 1
# Rename index to id for SQL table
df_junior_data = pd.DataFrame(junior_data).set_index('id')
df_junior_data.to_sql(name = 'juniors', con = engine, if_exists = 'append')

# Generate superiors table
superior_data = defaultdict(list)
employee_id_superior = 10
for _ in range(10):
    superior_data['id'].append(employee_id_superior)
    employee_id_superior = employee_id_superior + 1
# Rename index to id for SQL table
df_superior_data = pd.DataFrame(superior_data).set_index('id')
df_superior_data.to_sql(name = 'superiors', con = engine, if_exists = 'append')

# Generate seniors table
senior_data = defaultdict(list)
employee_id_senior = 10
for _ in range(5):
    senior_data['id'].append(employee_id_senior)
    employee_id_senior = employee_id_senior + 1
# Rename index to id for SQL table
df_senior_data = pd.DataFrame(senior_data).set_index('id')
df_senior_data.to_sql(name = 'seniors', con = engine, if_exists = 'append')

# Generate managers table
manager_data = defaultdict(list)
employee_id_manager = 15
for _ in range(5):
    manager_data['id'].append(employee_id_manager)
    employee_id_manager = employee_id_manager + 1
# Rename index to id for SQL table
df_manager_data = pd.DataFrame(manager_data).set_index('id')
df_manager_data.to_sql(name = 'managers', con = engine, if_exists = 'append')
