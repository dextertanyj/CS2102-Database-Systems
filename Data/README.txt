=== Guide to running data generator ===

1. Install Python 3

2. Run command "pip install -r requirements.txt"

3. Add your PSQL username and password to the "# Set up Python to PSQL connection" portion of the script to configure Python connection to PSQL

4. Remove all existing PSQL database table before running data_generator.py using "truncate attends, bookings, departments, employees, healthdeclarations, juniors, managers, meetingrooms,seniors, superiors, updates cascade;"

5. Run data_generator_py.