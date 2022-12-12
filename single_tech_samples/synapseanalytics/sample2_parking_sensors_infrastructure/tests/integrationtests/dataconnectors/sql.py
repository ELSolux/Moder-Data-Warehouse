import pytest
import pyodbc


@pytest.fixture(scope="module")
def sql_connection(config):
    """Create a Connection Object object"""
    driver = "{ODBC Driver 17 for SQL Server}"
    server_name = config["AZ_SYNAPSE_DEDICATED_SQLPOOL_NAME"]
    server_uri = config["AZ_SYNAPSE_DEDICATED_SQLPOOL_URI"]
    database = config["AZ_SYNAPSE_DEDICATED_SQLPOOL_DATABASE_NAME"]
    username = config["AZ_SYNAPSE_SQLPOOL_ADMIN_USERNAME"]
    password = config["AZ_SYNAPSE_SQLPOOL_ADMIN_PASSWORD"]

    connection_string = (
        f"Driver={driver};"
        f"Server=tcp:{server_name}.{server_uri},1433;"
        f"Database={database};"
        f"Uid={username};"
        f"Pwd={password};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
        # "MARS_Connection=Yes"
    )

    cnxn = pyodbc.connect(connection_string)
    yield cnxn
    cnxn.close()
