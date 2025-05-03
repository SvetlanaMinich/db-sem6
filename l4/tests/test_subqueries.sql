-- Тестовый скрипт для демонстрации работы с вложенными запросами

-- Добавляем больше тестовых данных для демонстрации вложенных запросов
BEGIN
    -- Проверяем, существуют ли таблицы
    FOR i IN (SELECT table_name FROM user_tables WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS')) LOOP
        IF i.table_name = 'EMPLOYEES' THEN
            -- Добавим еще сотрудников
            INSERT INTO employees VALUES (5, 'Дмитрий', 'Козлов', 10, 48000);
            INSERT INTO employees VALUES (6, 'Анна', 'Морозова', 20, 52000);
            INSERT INTO employees VALUES (7, 'Сергей', 'Белов', 30, 47000);
            INSERT INTO employees VALUES (8, 'Ольга', 'Новикова', 20, 41000);
        END IF;
    END LOOP;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END;
/

-- Пример использования функции execute_select с вложенными запросами
DECLARE
    v_json CLOB;
    v_cursor SYS_REFCURSOR;
    v_employee_id employees.employee_id%TYPE;
    v_first_name employees.first_name%TYPE;
    v_last_name employees.last_name%TYPE;
    v_department_name departments.department_name%TYPE;
    v_salary employees.salary%TYPE;
BEGIN
    -- Пример 1: Использование IN с подзапросом
    -- Сотрудники, которые работают в отделах с зарплатой выше 50000
    v_json := '{
        "type": "SELECT",
        "columns": ["e.employee_id", "e.first_name", "e.last_name", "e.salary", "d.department_name"],
        "tables": ["employees e"],
        "joins": [
            {
                "type": "INNER JOIN",
                "table": "departments d",
                "condition": "e.department_id = d.department_id"
            }
        ],
        "where": [
            {
                "subquery": {
                    "type": "SELECT",
                    "columns": ["department_id"],
                    "tables": ["employees"],
                    "where": [
                        {"condition": "salary > 50000"}
                    ]
                },
                "subquery_type": "IN",
                "field": "e.department_id"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('Пример 1: IN с подзапросом');
    v_cursor := execute_select(v_json);
    
    LOOP
        FETCH v_cursor INTO v_employee_id, v_first_name, v_last_name, v_salary, v_department_name;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee_id || ', Имя: ' || v_first_name || 
                            ', Фамилия: ' || v_last_name || ', Зарплата: ' || v_salary ||
                            ', Отдел: ' || v_department_name);
    END LOOP;
    CLOSE v_cursor;
    
    -- Пример 2: Использование NOT IN с подзапросом
    -- Сотрудники, которые не работают в IT отделе
    v_json := '{
        "type": "SELECT",
        "columns": ["employee_id", "first_name", "last_name", "salary"],
        "tables": ["employees"],
        "where": [
            {
                "subquery": {
                    "type": "SELECT",
                    "columns": ["department_id"],
                    "tables": ["departments"],
                    "where": [
                        {"condition": "department_name = ''IT''"}
                    ]
                },
                "subquery_type": "NOT IN",
                "field": "department_id"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Пример 2: NOT IN с подзапросом');
    v_cursor := execute_select(v_json);
    
    LOOP
        FETCH v_cursor INTO v_employee_id, v_first_name, v_last_name, v_salary;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee_id || ', Имя: ' || v_first_name || 
                            ', Фамилия: ' || v_last_name || ', Зарплата: ' || v_salary);
    END LOOP;
    CLOSE v_cursor;
    
    -- Пример 3: Использование EXISTS с подзапросом
    -- Отделы, в которых есть сотрудники с зарплатой выше 50000
    -- columns: ["1"] используется как заглушка, что запрос не должен возвращать никакие столбцы
    v_json := '{
        "type": "SELECT",
        "columns": ["d.department_id", "d.department_name"],
        "tables": ["departments d"],
        "where": [
            {
                "subquery": {
                    "type": "SELECT",
                    "columns": ["1"],
                    "tables": ["employees e"],
                    "where": [
                        {"condition": "e.department_id = d.department_id"},
                        {"connector": "AND", "condition": "e.salary > 50000"}
                    ]
                },
                "subquery_type": "EXISTS"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Пример 3: EXISTS с подзапросом');
    v_cursor := execute_select(v_json);
    
    LOOP
        FETCH v_cursor INTO v_employee_id, v_department_name;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID отдела: ' || v_employee_id || ', Название: ' || v_department_name);
    END LOOP;
    CLOSE v_cursor;
    
    -- Пример 4: Использование NOT EXISTS с подзапросом
    -- Отделы, в которых нет сотрудников с зарплатой ниже 45000
    v_json := '{
        "type": "SELECT",
        "columns": ["d.department_id", "d.department_name"],
        "tables": ["departments d"],
        "where": [
            {
                "subquery": {
                    "type": "SELECT",
                    "columns": ["1"],
                    "tables": ["employees e"],
                    "where": [
                        {"condition": "e.department_id = d.department_id"},
                        {"connector": "AND", "condition": "e.salary < 45000"}
                    ]
                },
                "subquery_type": "NOT EXISTS"
            }
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Пример 4: NOT EXISTS с подзапросом');
    v_cursor := execute_select(v_json);
    
    LOOP
        FETCH v_cursor INTO v_employee_id, v_department_name;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID отдела: ' || v_employee_id || ', Название: ' || v_department_name);
    END LOOP;
    CLOSE v_cursor;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/ 