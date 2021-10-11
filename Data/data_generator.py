import pandas as pd
import random
from faker import Faker
from collections import defaultdict
from sqlalchemy import create_engine
import datetime

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
        department_data['removal_date'].append(fake.date_between(start_date=datetime.date(2016,1,1), end_date='today'))
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
        employee_data['resignation_date'].append(fake.date_between(start_date=datetime.date(2016,1,1), end_date='today'))
    else:
        employee_data['resignation_date'].append(None)
    employee_data['department_id'].append(random.randint(0,19))
df_employee_data = pd.DataFrame(employee_data)
# Rename index to id for SQL table
df_employee_data.index.names = ['id']
df_employee_data.to_sql(name = 'employees', con = engine, if_exists = 'append')

# Generate meetingrooms table
meeting_room_data = defaultdict(list)
meeting_room_pk = []
for _ in range(30):
    floor = random.randint(1,5)
    room = random.randint(1,9)
    while ((floor, room) in meeting_room_pk):
        floor = random.randint(1,5)
        room = random.randint(1,9)
    meeting_room_pk.append((floor, room))
    meeting_room_data['floor'].append(floor)
    meeting_room_data['room'].append(room)
    # PDF says room name may be duplicated due to legacy reasons
    meeting_room_data['name'].append(random.choice(['Database Meeting Room', 'BevSpot', 'Bynder', 'Cloud Technology Partners', 'Crayon', 'Continuum', 'InCrowd', 'MOO', 'Zaius']))
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

# Generate healthdeclarations table
health_declaration_data = defaultdict(list)
health_declaration_pk = []
for _ in range(20):
    id_value = random.randint(0, 19)
    date = fake.date_between(start_date=datetime.date(2021,10,1), end_date='today')
    while ((id_value, date) in health_declaration_pk):
        id_value = random.randint(0, 19)
        date = fake.date_between(start_date=datetime.date(2021,10,1), end_date='today')
    health_declaration_pk.append((id_value, date))
    health_declaration_data['id'].append(id_value)
    health_declaration_data['date'].append(date)
    health_declaration_data['temperature'].append(random.randint(340, 430) / 10)
# set_index removes the default incremental index
df_health_declaration_data = pd.DataFrame(health_declaration_data).set_index('id')
df_health_declaration_data.to_sql(name = 'healthdeclarations', con = engine, if_exists = 'append')
