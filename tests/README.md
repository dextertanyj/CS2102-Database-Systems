# Test instructions

1. Use root of the repo directory (not `tests` dir)
1. Configure username, password, database in `test_sql.py`
1. Install all dependencies
    ```sh
    pip install -r requirements.txt
    ```
1. Run test:
    ```sh
    pytest
    ```
    To run with console output (i.e print statements)
    ```sh
    pytest -s
    ```