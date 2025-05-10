SET SERVEROUTPUT ON;
GRANT CREATE SEQUENCE TO SYSTEM;
GRANT CREATE TRIGGER TO SYSTEM;

-- Тест 1: Создание таблицы test_table
DECLARE
    l_cursor SYS_REFCURSOR;
    l_message VARCHAR2(4000);
BEGIN
    l_cursor := execute_ddl('{
        "command": "CREATE",
        "table": "test_table",
        "columns": [
            { "name": "id", "type": "NUMBER", "constraints": "PRIMARY KEY" },
            { "name": "name", "type": "VARCHAR2(50)", "constraints": "NOT NULL" }
        ]
    }');
    FETCH l_cursor INTO l_message;
    DBMS_OUTPUT.PUT_LINE('Test CREATE test_table: ' || l_message);
    CLOSE l_cursor;
END;
/

INSERT INTO test_table (id, name) VALUES (NULL, 'test');
SELECT * FROM test_table;

DROP SEQUENCE test_table_seq;
DROP TRIGGER test_table_trg;

-- Тест 2: Удаление таблицы test_table
DECLARE
    l_cursor SYS_REFCURSOR;
    l_message VARCHAR2(4000);
BEGIN
    l_cursor := execute_ddl('{
        "command": "DROP",
        "table": "test_table"
    }');
    FETCH l_cursor INTO l_message;
    DBMS_OUTPUT.PUT_LINE('Test DROP test_table: ' || l_message);
    CLOSE l_cursor;
END;
/
