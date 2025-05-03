-- Тестовый скрипт для демонстрации работы с DDL-операциями через JSON

SET SERVEROUTPUT ON;

-- Очистка тестовых таблиц перед началом
BEGIN
    FOR i IN (SELECT table_name 
              FROM user_tables 
              WHERE table_name IN ('TEST_EMPLOYEES', 'TEST_DEPARTMENTS', 'TEST_PRODUCTS')) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || i.table_name || ' CASCADE CONSTRAINTS PURGE';
        DBMS_OUTPUT.PUT_LINE('Таблица ' || i.table_name || ' удалена.');
    END LOOP;
    
    -- Удаляем тестовые последовательности
    FOR i IN (SELECT sequence_name 
              FROM user_sequences 
              WHERE sequence_name IN ('SEQ_TEST_PRODUCTS')) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || i.sequence_name;
        DBMS_OUTPUT.PUT_LINE('Последовательность ' || i.sequence_name || ' удалена.');
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при удалении таблиц/последовательностей: ' || SQLERRM);
END;
/

-- Тестирование DDL-операций
DECLARE
    v_json CLOB;
    v_cursor SYS_REFCURSOR;
    v_operation_type VARCHAR2(50);
    v_table_name VARCHAR2(100);
    v_result VARCHAR2(4000);
BEGIN
    -- Тест 1: Создание простой таблицы
    v_json := '{
        "type": "CREATE_TABLE",
        "table_name": "TEST_DEPARTMENTS",
        "columns": [
            {
                "name": "DEPARTMENT_ID",
                "type": "NUMBER",
                "nullable": false,
                "primary_key": true
            },
            {
                "name": "DEPARTMENT_NAME",
                "type": "VARCHAR2(100)",
                "nullable": false
            },
            {
                "name": "LOCATION_ID",
                "type": "NUMBER",
                "nullable": true
            },
            {
                "name": "CREATED_DATE",
                "type": "DATE",
                "default": "SYSDATE"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('Тест 1: Создание простой таблицы TEST_DEPARTMENTS');
    v_cursor := execute_ddl(v_json);
    
    FETCH v_cursor INTO v_operation_type, v_table_name, v_result;
    DBMS_OUTPUT.PUT_LINE('Результат: ' || v_result);
    CLOSE v_cursor;
    
    -- Тест 2: Создание таблицы с ограничениями
    v_json := '{
        "type": "CREATE_TABLE",
        "table_name": "TEST_EMPLOYEES",
        "columns": [
            {
                "name": "EMPLOYEE_ID",
                "type": "NUMBER",
                "nullable": false
            },
            {
                "name": "FIRST_NAME",
                "type": "VARCHAR2(50)",
                "nullable": true
            },
            {
                "name": "LAST_NAME",
                "type": "VARCHAR2(50)",
                "nullable": false
            },
            {
                "name": "EMAIL",
                "type": "VARCHAR2(100)",
                "nullable": false
            },
            {
                "name": "PHONE",
                "type": "VARCHAR2(20)",
                "nullable": true
            },
            {
                "name": "HIRE_DATE",
                "type": "DATE",
                "default": "SYSDATE"
            },
            {
                "name": "DEPARTMENT_ID",
                "type": "NUMBER",
                "nullable": true
            },
            {
                "name": "SALARY",
                "type": "NUMBER(10,2)",
                "default": "0"
            }
        ],
        "constraints": [
            {
                "name": "PK_TEST_EMPLOYEES",
                "type": "PRIMARY_KEY",
                "columns": "EMPLOYEE_ID"
            },
            {
                "name": "UK_TEST_EMPLOYEES_EMAIL",
                "type": "UNIQUE",
                "columns": "EMAIL"
            },
            {
                "name": "FK_TEST_EMPLOYEES_DEPT",
                "type": "FOREIGN_KEY",
                "columns": "DEPARTMENT_ID",
                "references_table": "TEST_DEPARTMENTS",
                "references_columns": "DEPARTMENT_ID",
                "on_delete": "SET NULL"
            },
            {
                "name": "CK_TEST_EMPLOYEES_SALARY",
                "type": "CHECK",
                "condition": "SALARY >= 0"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 2: Создание таблицы TEST_EMPLOYEES с ограничениями');
    v_cursor := execute_ddl(v_json);
    
    FETCH v_cursor INTO v_operation_type, v_table_name, v_result;
    DBMS_OUTPUT.PUT_LINE('Результат: ' || v_result);
    CLOSE v_cursor;
    
    -- Тест 3: Добавление данных в таблицы для проверки
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 3: Добавление тестовых данных для проверки');
    
    -- Добавляем данные в TEST_DEPARTMENTS
    EXECUTE IMMEDIATE 'INSERT INTO TEST_DEPARTMENTS (DEPARTMENT_ID, DEPARTMENT_NAME, LOCATION_ID) VALUES (10, ''IT'', 1000)';
    EXECUTE IMMEDIATE 'INSERT INTO TEST_DEPARTMENTS (DEPARTMENT_ID, DEPARTMENT_NAME, LOCATION_ID) VALUES (20, ''HR'', 1001)';
    
    -- Добавляем данные в TEST_EMPLOYEES
    EXECUTE IMMEDIATE 'INSERT INTO TEST_EMPLOYEES (EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, DEPARTMENT_ID, SALARY) 
                       VALUES (1, ''John'', ''Doe'', ''john.doe@example.com'', 10, 5000)';
    EXECUTE IMMEDIATE 'INSERT INTO TEST_EMPLOYEES (EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, DEPARTMENT_ID, SALARY) 
                       VALUES (2, ''Jane'', ''Smith'', ''jane.smith@example.com'', 20, 6000)';
    
    DBMS_OUTPUT.PUT_LINE('Тестовые данные добавлены успешно.');
    
    -- Тест 4: Попробуем добавить запись, нарушающую ограничение внешнего ключа
    BEGIN
        EXECUTE IMMEDIATE 'INSERT INTO TEST_EMPLOYEES (EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, DEPARTMENT_ID, SALARY) 
                          VALUES (3, ''Bob'', ''Johnson'', ''bob.johnson@example.com'', 30, 5500)';
        DBMS_OUTPUT.PUT_LINE('ОШИБКА: Нарушение ограничения внешнего ключа не вызвало исключение!');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ожидаемая ошибка: Нарушение ограничения внешнего ключа.');
    END;
    
    -- Тест 5: Удаление таблицы TEST_EMPLOYEES
    v_json := '{
        "type": "DROP_TABLE",
        "table_name": "TEST_EMPLOYEES",
        "cascade_constraints": true
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 5: Удаление таблицы TEST_EMPLOYEES');
    v_cursor := execute_ddl(v_json);
    
    FETCH v_cursor INTO v_operation_type, v_table_name, v_result;
    DBMS_OUTPUT.PUT_LINE('Результат: ' || v_result);
    CLOSE v_cursor;
    
    -- Тест 6: Удаление таблицы TEST_DEPARTMENTS
    v_json := '{
        "type": "DROP_TABLE",
        "table_name": "TEST_DEPARTMENTS"
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 6: Удаление таблицы TEST_DEPARTMENTS');
    v_cursor := execute_ddl(v_json);
    
    FETCH v_cursor INTO v_operation_type, v_table_name, v_result;
    DBMS_OUTPUT.PUT_LINE('Результат: ' || v_result);
    CLOSE v_cursor;
    
    -- Тест 7: Создание таблицы с автоматическим генератором первичного ключа
    v_json := '{
        "type": "CREATE_TABLE",
        "table_name": "TEST_PRODUCTS",
        "auto_pk_trigger": true,
        "columns": [
            {
                "name": "PRODUCT_ID",
                "type": "NUMBER",
                "nullable": false,
                "primary_key": true
            },
            {
                "name": "PRODUCT_NAME",
                "type": "VARCHAR2(100)",
                "nullable": false
            },
            {
                "name": "PRICE",
                "type": "NUMBER(10,2)",
                "nullable": false,
                "default": "0"
            },
            {
                "name": "CREATED_AT",
                "type": "DATE",
                "default": "SYSDATE"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 7: Создание таблицы TEST_PRODUCTS с автоматическим генератором первичного ключа');
    v_cursor := execute_ddl(v_json);
    
    FETCH v_cursor INTO v_operation_type, v_table_name, v_result;
    DBMS_OUTPUT.PUT_LINE('Результат: ' || v_result);
    CLOSE v_cursor;
    
    -- Тест 8: Проверка работы триггера для первичного ключа
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 8: Проверка работы автоматического триггера для первичного ключа');
    
    BEGIN
        -- Добавляем запись без указания ID (должен сработать триггер)
        EXECUTE IMMEDIATE 'INSERT INTO TEST_PRODUCTS (PRODUCT_NAME, PRICE) VALUES (''Тестовый продукт 1'', 100.50)';
        EXECUTE IMMEDIATE 'INSERT INTO TEST_PRODUCTS (PRODUCT_NAME, PRICE) VALUES (''Тестовый продукт 2'', 200.75)';
        
        -- Проверяем, что ID были автоматически сгенерированы
        FOR product_rec IN (SELECT product_id, product_name, price FROM TEST_PRODUCTS ORDER BY product_id) LOOP
            DBMS_OUTPUT.PUT_LINE('ID: ' || product_rec.product_id || ', Название: ' || product_rec.product_name || 
                                ', Цена: ' || product_rec.price);
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('Триггер для генерации первичного ключа работает корректно.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка при тестировании триггера: ' || SQLERRM);
    END;
    
    -- Тест 9: Удаление таблицы TEST_PRODUCTS
    v_json := '{
        "type": "DROP_TABLE",
        "table_name": "TEST_PRODUCTS",
        "cascade_constraints": true,
        "purge": true
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 9: Удаление таблицы TEST_PRODUCTS');
    v_cursor := execute_ddl(v_json);
    
    FETCH v_cursor INTO v_operation_type, v_table_name, v_result;
    DBMS_OUTPUT.PUT_LINE('Результат: ' || v_result);
    CLOSE v_cursor;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении тестов: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/ 