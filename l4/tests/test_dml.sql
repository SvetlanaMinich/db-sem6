-- Тестовый скрипт для демонстрации DML-операций с использованием JSON

SET SERVEROUTPUT ON;

-- Очистка и пересоздание тестовых таблиц
BEGIN
    -- Удаляем таблицы, если они существуют
    FOR i IN (SELECT table_name FROM user_tables WHERE table_name IN ('PROJECTS', 'TASKS')) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || i.table_name;
    END LOOP;
    
    -- Создаем новые таблицы для тестирования
    EXECUTE IMMEDIATE '
        CREATE TABLE projects (
            project_id NUMBER PRIMARY KEY,
            project_name VARCHAR2(100),
            department_id NUMBER,
            budget NUMBER,
            start_date DATE
        )
    ';
    
    EXECUTE IMMEDIATE '
        CREATE TABLE tasks (
            task_id NUMBER PRIMARY KEY,
            task_name VARCHAR2(100),
            project_id NUMBER,
            employee_id NUMBER,
            status VARCHAR2(20),
            deadline DATE
        )
    ';
    
    -- Добавляем несколько проектов
    EXECUTE IMMEDIATE '
        INSERT INTO projects VALUES (1, ''Разработка веб-сайта'', 10, 100000, TO_DATE(''2023-01-15'', ''YYYY-MM-DD''))
    ';
    EXECUTE IMMEDIATE '
        INSERT INTO projects VALUES (2, ''Мобильное приложение'', 10, 150000, TO_DATE(''2023-02-20'', ''YYYY-MM-DD''))
    ';
    EXECUTE IMMEDIATE '
        INSERT INTO projects VALUES (3, ''Аналитика данных'', 30, 80000, TO_DATE(''2023-03-10'', ''YYYY-MM-DD''))
    ';
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Тестовые таблицы созданы и заполнены начальными данными.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при создании тестовых таблиц: ' || SQLERRM);
END;
/

-- Тестирование DML-операций
DECLARE
    v_json CLOB;
    v_rows_affected NUMBER;
BEGIN
    -- Тест 1: INSERT с простыми значениями
    v_json := '{
        "type": "INSERT",
        "table": "tasks",
        "columns": ["task_id", "task_name", "project_id", "employee_id", "status", "deadline"],
        "values": [1, "Дизайн главной страницы", 1, 1, "В процессе", "2023-02-28"]
    }';
    
    DBMS_OUTPUT.PUT_LINE('Тест 1: INSERT с простыми значениями');
    v_rows_affected := execute_dml(v_json);
    DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows_affected);
    
    -- Тест 2: INSERT с подзапросом
    v_json := '{
        "type": "INSERT",
        "table": "tasks",
        "columns": ["task_id", "task_name", "project_id", "employee_id", "status", "deadline"],
        "select": {
            "type": "SELECT",
            "columns": ["2", "''Разработка функционала''", "1", "3", "''Не начато''", "''2023-03-15''"],
            "tables": ["dual"]
        }
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 2: INSERT с подзапросом');
    v_rows_affected := execute_dml(v_json);
    DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows_affected);
    
    -- Тест 3: UPDATE с простым условием
    v_json := '{
        "type": "UPDATE",
        "table": "tasks",
        "set": [
            {"column": "status", "value": "Завершено"}
        ],
        "where": [
            {"condition": "task_id = 1"}
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 3: UPDATE с простым условием');
    v_rows_affected := execute_dml(v_json);
    DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows_affected);
    
    -- Тест 4: UPDATE с подзапросом в WHERE
    v_json := '{
        "type": "UPDATE",
        "table": "tasks",
        "set": [
            {"column": "status", "value": "Приоритетно"}
        ],
        "where": [
            {
                "subquery": {
                    "type": "SELECT",
                    "columns": ["project_id"],
                    "tables": ["projects"],
                    "where": [
                        {"condition": "budget > 100000"}
                    ]
                },
                "subquery_type": "IN",
                "field": "project_id"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 4: UPDATE с подзапросом в WHERE');
    v_rows_affected := execute_dml(v_json);
    DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows_affected);
    
    -- Тест 5: UPDATE с подзапросом в SET
    v_json := '{
        "type": "UPDATE",
        "table": "tasks",
        "set": [
            {
                "column": "employee_id",
                "subquery": {
                    "type": "SELECT",
                    "columns": ["4"],
                    "tables": ["dual"]
                }
            }
        ],
        "where": [
            {"condition": "task_id = 2"}
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 5: UPDATE с подзапросом в SET');
    v_rows_affected := execute_dml(v_json);
    DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows_affected);
    
    -- Тест 6: DELETE с простым условием
    v_json := '{
        "type": "DELETE",
        "table": "tasks",
        "where": [
            {"condition": "task_id = 1"}
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 6: DELETE с простым условием');
    v_rows_affected := execute_dml(v_json);
    DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows_affected);
    
    -- Тест 7: DELETE с подзапросом
    v_json := '{
        "type": "DELETE",
        "table": "tasks",
        "where": [
            {
                "subquery": {
                    "type": "SELECT",
                    "columns": ["project_id"],
                    "tables": ["projects"],
                    "where": [
                        {"condition": "department_id = 30"}
                    ]
                },
                "subquery_type": "IN",
                "field": "project_id"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Тест 7: DELETE с подзапросом');
    v_rows_affected := execute_dml(v_json);
    DBMS_OUTPUT.PUT_LINE('Затронуто строк: ' || v_rows_affected);
    
    -- Показываем результаты
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Результаты:');
    
    -- Выводим все записи из таблицы tasks
    FOR rec IN (SELECT task_id, task_name, project_id, employee_id, status FROM tasks ORDER BY task_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Task ID: ' || rec.task_id || 
                            ', Name: ' || rec.task_name || 
                            ', Project: ' || rec.project_id || 
                            ', Employee: ' || rec.employee_id || 
                            ', Status: ' || rec.status);
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении тестов: ' || SQLERRM);
END;
/ 