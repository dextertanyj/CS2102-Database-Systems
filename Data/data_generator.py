import pandas as pd
import random
from faker import Faker
from collections import defaultdict
from sqlalchemy import create_engine
import datetime

# Set up Python to PSQL connection
username = ''
password = ''
database = 'project'
path = 'postgresql://' + username + ':' + password + '@localhost:5432/' + database
engine = create_engine(path)
fake = Faker('en_GB')

# Indicate rows generated
number_of_departments = 20
number_of_employees = 60
number_of_junior_employees = 20
number_of_senior_employees = 20
number_of_managers = 20
number_of_superiors = number_of_senior_employees + number_of_managers
number_of_meeting_rooms = 20
number_of_health_declarations = 40
number_of_bookings = 20
number_of_attendees = 40
number_of_updates = 20

# Starting ids of employees
employee_id_junior = 1
employee_id_superior = 21
employee_id_senior = 21
employee_id_manager = 41

# Generate random seed
random.seed(10)

# Generate departments table 
department_data = defaultdict(list)
for _ in range(number_of_departments):
    department_data['name'].append(fake.company())
    # Generate random removal_date with an arbitrarily chosen 10% chance
    if (random.random() < 0.1):
        department_data['removal_date'].append(fake.date_between(start_date=datetime.date(2016,1,1), end_date='today'))
    else:
        department_data['removal_date'].append(None)
df_department_data = pd.DataFrame(department_data)
# Start id from 1
df_department_data.index += 1
# Rename index to id for SQL table
df_department_data.index.names = ['id']
df_department_data.to_sql(name = 'departments', con = engine, if_exists = 'append')

# Generate employees table
employee_data = defaultdict(list)
for _ in range(number_of_employees):
    first_name = fake.first_name()
    last_name = fake.last_name()
    employee_data['name'].append(first_name + ' ' + last_name)
    employee_data['contact_number'].append(fake.phone_number())
    employee_data['email'].append((first_name.lower() + '.' + last_name.lower() + '@' + fake.free_email_domain()).replace("'", ""))
    # Generate random resignation_date with an arbitrarily chosen 10% chance
    if (random.random() < 0.1):
        employee_data['resignation_date'].append(fake.date_between(start_date=datetime.date(2016,1,1), end_date='today'))
    else:
        employee_data['resignation_date'].append(None)
    employee_data['department_id'].append(random.randint(1,number_of_departments))
df_employee_data = pd.DataFrame(employee_data)
# Start id from 1
df_employee_data.index += 1
# Rename index to id for SQL table
df_employee_data.index.names = ['id']
df_employee_data.to_sql(name = 'employees', con = engine, if_exists = 'append')

# Generate meetingrooms table
meeting_room_data = defaultdict(list)
meeting_room_pk = []
for _ in range(number_of_meeting_rooms):
    floor = random.randint(1,3)
    room = random.randint(1,9)
    while ((floor, room) in meeting_room_pk):
        floor = random.randint(1,3)
        room = random.randint(1,9)
    meeting_room_pk.append((floor, room))
    meeting_room_data['floor'].append(floor)
    meeting_room_data['room'].append(room)
    # PDF says room name may be duplicated due to legacy reasons
    meeting_room_data['name'].append(random.choice(['Database Meeting Room', 'BevSpot', 'Bynder', 'Cloud Technology Partners', 'Crayon', 'Continuum', 'InCrowd', 'MOO', 'Zaius']))
    room = room + 1
    meeting_room_data['department_id'].append(random.randint(1,number_of_departments))
# set_index removes the default incremental index
df_meeting_room_data = pd.DataFrame(meeting_room_data).set_index('floor')
df_meeting_room_data.to_sql(name = 'meetingrooms', con = engine, if_exists = 'append')

# Generate juniors table
junior_data = defaultdict(list)
employee_id_junior_copy = employee_id_junior
for _ in range(number_of_junior_employees):
    junior_data['id'].append(employee_id_junior_copy)
    employee_id_junior_copy = employee_id_junior_copy + 1
# Rename index to id for SQL table
df_junior_data = pd.DataFrame(junior_data).set_index('id')
df_junior_data.to_sql(name = 'juniors', con = engine, if_exists = 'append')

# Generate superiors table
superior_data = defaultdict(list)
employee_id_superior_copy = employee_id_superior
for _ in range(number_of_superiors):
    superior_data['id'].append(employee_id_superior_copy)
    employee_id_superior_copy = employee_id_superior_copy + 1
# Rename index to id for SQL table
df_superior_data = pd.DataFrame(superior_data).set_index('id')
df_superior_data.to_sql(name = 'superiors', con = engine, if_exists = 'append')

# Generate seniors table
senior_data = defaultdict(list)
employee_id_senior_copy = employee_id_senior
for _ in range(number_of_senior_employees):
    senior_data['id'].append(employee_id_senior_copy)
    employee_id_senior_copy = employee_id_senior_copy + 1
# Rename index to id for SQL table
df_senior_data = pd.DataFrame(senior_data).set_index('id')
df_senior_data.to_sql(name = 'seniors', con = engine, if_exists = 'append')

# Generate managers table
manager_data = defaultdict(list)
employee_id_manager_copy = employee_id_manager
for _ in range(number_of_managers):
    manager_data['id'].append(employee_id_manager_copy)
    employee_id_manager_copy = employee_id_manager_copy + 1
# Rename index to id for SQL table
df_manager_data = pd.DataFrame(manager_data).set_index('id')
df_manager_data.to_sql(name = 'managers', con = engine, if_exists = 'append')

# Generate healthdeclarations table
health_declaration_data = defaultdict(list)
health_declaration_pk = []
for _ in range(number_of_health_declarations):
    id_value = random.randint(1, number_of_employees)
    date = fake.date_between(start_date=datetime.date(2021,10,1), end_date='today')
    while ((id_value, date) in health_declaration_pk or id_value >= 45):
        id_value = random.randint(1, number_of_health_declarations)
        date = fake.date_between(start_date=datetime.date(2021,10,1), end_date='today')
    health_declaration_pk.append((id_value, date))
    health_declaration_data['id'].append(id_value)
    health_declaration_data['date'].append(date)
    temperature = None;
    if (id_value < 40):
        temperature = random.randint(340, 374) / 10
    elif (id_value >= 40 and id_value < 44):
        temperature = random.randint(375, 430) / 10
    health_declaration_data['temperature'].append(temperature)
# set_index removes the default incremental index
df_health_declaration_data = pd.DataFrame(health_declaration_data).set_index('id')
df_health_declaration_data.to_sql(name = 'healthdeclarations', con = engine, if_exists = 'append')

# Generate bookings table
booking_data = defaultdict(list)
booking_pk = []
for _ in range(number_of_bookings):
    floor_room = random.choice(meeting_room_pk)
    floor = floor_room[0]
    room = floor_room[1]
    date = fake.date_between(start_date=datetime.date(2021,10,1), end_date='today')
    start_hour = random.randint(0,23)
    while ((floor, room, date, start_hour) in booking_pk):
        floor_room = random.choice(meeting_room_pk)
        floor = floor_room[0]
        room = floor_room[1]
        date = fake.date_between(start_date=datetime.date(2021,10,1), end_date='today')
        start_hour = random.randint(0,23)
    booking_pk.append((floor, room, date, start_hour))
    booking_data['floor'].append(floor)
    booking_data['room'].append(room)
    booking_data['date'].append(date)
    booking_data['start_hour'].append(start_hour)
    # Superior ID
    booking_data['creator_id'].append(random.randint(employee_id_superior, number_of_employees))
    # Manager ID
    booking_data['approver_id'].append(random.randint(employee_id_manager, number_of_employees))
# set_index removes the default incremental index
df_booking_data = pd.DataFrame(booking_data).set_index('floor')
df_booking_data.to_sql(name = 'bookings', con = engine, if_exists = 'append')

# Generate attends table
attends_data = defaultdict(list)
attends_pk = []
for _ in range(number_of_attendees):
    floor_room_date_start_hour = random.choice(booking_pk)
    employee_id = random.randint(1, number_of_employees)
    floor = floor_room_date_start_hour[0]
    room = floor_room_date_start_hour[1]
    date = floor_room_date_start_hour[2]
    start_hour = floor_room_date_start_hour[3]
    while ((employee_id, floor, room, date, start_hour) in attends_pk):
        floor_room_date_start_hour = random.choice(booking_pk)
        employee_id = random.randint(1, number_of_employees)
        floor = floor_room_date_start_hour[0]
        room = floor_room_date_start_hour[1]
        date = floor_room_date_start_hour[2]
        start_hour = floor_room_date_start_hour[3]
    attends_pk.append((employee_id, floor, room, date, start_hour))
    attends_data['employee_id'].append(employee_id)
    attends_data['floor'].append(floor)
    attends_data['room'].append(room)
    attends_data['date'].append(date)
    attends_data['start_hour'].append(start_hour)
# set_index removes the default incremental index
df_attends_data = pd.DataFrame(attends_data).set_index('employee_id')
df_attends_data.to_sql(name = 'attends', con = engine, if_exists = 'append')

# Generate updates table
updates_data = defaultdict(list)
updates_pk = []
for _ in range(number_of_updates):
    floor_room = random.choice(meeting_room_pk)
    date = fake.date_between(start_date=datetime.date(2021,10,1), end_date='today')
    floor = floor_room[0]
    room = floor_room[1]
    while ((date, floor, room) in updates_pk):
        floor_room = random.choice(meeting_room_pk)
        date = fake.date_between(start_date=datetime.date(2021,10,1), end_date='today')
        floor = floor_room[0]
        room = floor_room[1]
    updates_pk.append((date, floor, room))
    updates_data['manager_id'].append(random.randint(employee_id_manager, number_of_employees))
    updates_data['floor'].append(floor)
    updates_data['room'].append(room)
    updates_data['date'].append(date)
    updates_data['capacity'].append(random.randint(0, 9))
# set_index removes the default incremental index
df_updates_data = pd.DataFrame(updates_data).set_index('manager_id')
df_updates_data.to_sql(name = 'updates', con = engine, if_exists = 'append')
