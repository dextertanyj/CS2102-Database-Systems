import pytest
import os
import config
import utils

@pytest.fixture(scope='session', autouse=True)
def global_before_all():
    os.environ['PGPASSWORD'] = config.password
    os.system('psql -h localhost -U {username} -d {database} -f proc.sql'.format(username=config.username, database=config.database))


@pytest.fixture(autouse=True)
def global_before_each():
    utils.reset()
