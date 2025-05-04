SET SERVEROUTPUT ON;

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

-- Проверка существования таблицы test_table
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = UPPER('test_table');
    DBMS_OUTPUT.PUT_LINE('Table test_table exists: ' || v_count);
END;
/

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

-- Проверка удаления таблицы test_table
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = UPPER('test_table');
    DBMS_OUTPUT.PUT_LINE('Table test_table exists after DROP: ' || v_count);
END;
/

-- Тест 3: Создание таблицы test_table2 c параметром cascade FALSE (просто для проверки)
DECLARE
    l_cursor SYS_REFCURSOR;
    l_message VARCHAR2(4000);
BEGIN
    l_cursor := execute_ddl('{
        "command": "CREATE",
        "table": "test_table2",
        "columns": [
            { "name": "id", "type": "NUMBER", "constraints": "PRIMARY KEY" },
            { "name": "description", "type": "VARCHAR2(100)" }
        ],
        "cascade": "FALSE"
    }');
    FETCH l_cursor INTO l_message;
    DBMS_OUTPUT.PUT_LINE('Test CREATE test_table2: ' || l_message);
    CLOSE l_cursor;
END;
/

-- Проверка существования таблицы test_table2
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = UPPER('test_table2');
    DBMS_OUTPUT.PUT_LINE('Table test_table2 exists: ' || v_count);
END;
/

-- Тест 4: Удаление таблицы test_table2 с опцией CASCADE CONSTRAINTS
DECLARE
    l_cursor SYS_REFCURSOR;
    l_message VARCHAR2(4000);
BEGIN
    l_cursor := execute_ddl('{
        "command": "DROP",
        "table": "test_table2",
        "cascade": "TRUE"
    }');
    FETCH l_cursor INTO l_message;
    DBMS_OUTPUT.PUT_LINE('Test DROP test_table2 with cascade: ' || l_message);
    CLOSE l_cursor;
END;
/

-- Проверка удаления таблицы test_table2
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = UPPER('test_table2');
    DBMS_OUTPUT.PUT_LINE('Table test_table2 exists after DROP: ' || v_count);
END;
/

-- Тест 5: Создание таблиц parent_table и child_table с внешним ключом
DECLARE
    l_cursor SYS_REFCURSOR;
    l_message VARCHAR2(4000);
BEGIN
    -- Создаем родительскую таблицу
    l_cursor := execute_ddl('{
        "command": "CREATE",
        "table": "parent_table",
        "columns": [
            { "name": "id", "type": "NUMBER", "constraints": "PRIMARY KEY" },
            { "name": "description", "type": "VARCHAR2(50)" }
        ]
    }');
    FETCH l_cursor INTO l_message;
    DBMS_OUTPUT.PUT_LINE('Test CREATE parent_table: ' || l_message);
    CLOSE l_cursor;
    
    -- Создаем дочернюю таблицу
    l_cursor := execute_ddl('{
        "command": "CREATE",
        "table": "child_table",
        "columns": [
            { "name": "id", "type": "NUMBER", "constraints": "PRIMARY KEY" },
            { "name": "parent_id", "type": "NUMBER", "constraints": "NOT NULL" }
        ]
    }');
    FETCH l_cursor INTO l_message;
    DBMS_OUTPUT.PUT_LINE('Test CREATE child_table: ' || l_message);
    CLOSE l_cursor;
    
    -- Добавляем внешний ключ в дочернюю таблицу
    EXECUTE IMMEDIATE 'ALTER TABLE child_table ADD CONSTRAINT fk_parent FOREIGN KEY (parent_id) REFERENCES parent_table(id)';
    DBMS_OUTPUT.PUT_LINE('Foreign key constraint fk_parent added to child_table.');
END;
/

-- Проверка существования таблиц parent_table и child_table
DECLARE
    v_count_parent NUMBER;
    v_count_child NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_parent FROM user_tables WHERE table_name = UPPER('parent_table');
    SELECT COUNT(*) INTO v_count_child FROM user_tables WHERE table_name = UPPER('child_table');
    DBMS_OUTPUT.PUT_LINE('Table parent_table exists: ' || v_count_parent);
    DBMS_OUTPUT.PUT_LINE('Table child_table exists: ' || v_count_child);
END;
/

-- Тест 6: Удаление таблицы parent_table с опцией CASCADE CONSTRAINTS
DECLARE
    l_cursor SYS_REFCURSOR;
    l_message VARCHAR2(4000);
BEGIN
    l_cursor := execute_ddl('{
        "command": "DROP",
        "table": "parent_table",
        "cascade": "TRUE"
    }');
    FETCH l_cursor INTO l_message;
    DBMS_OUTPUT.PUT_LINE('Test DROP parent_table with cascade: ' || l_message);
    CLOSE l_cursor;
END;
/

-- Проверка удаления таблицы parent_table и внешнего ключа в child_table
DECLARE
    v_count_parent NUMBER;
    v_fk_count NUMBER;
BEGIN
    -- Проверяем, что родительская таблица удалена
    SELECT COUNT(*) INTO v_count_parent FROM user_tables WHERE table_name = UPPER('parent_table');
    DBMS_OUTPUT.PUT_LINE('Table parent_table exists after DROP: ' || v_count_parent);
    
    -- Проверяем, что внешний ключ в дочерней таблице отсутствует
    SELECT COUNT(*) INTO v_fk_count FROM user_constraints WHERE table_name = UPPER('child_table') AND constraint_type = 'R';
    DBMS_OUTPUT.PUT_LINE('Foreign key constraints in child_table: ' || v_fk_count);
END;
/

-- Тест 7: Удаление таблицы child_table (cleanup)
DECLARE
    l_cursor SYS_REFCURSOR;
    l_message VARCHAR2(4000);
BEGIN
    l_cursor := execute_ddl('{
        "command": "DROP",
        "table": "child_table"
    }');
    FETCH l_cursor INTO l_message;
    DBMS_OUTPUT.PUT_LINE('Test DROP child_table: ' || l_message);
    CLOSE l_cursor;
END;
/