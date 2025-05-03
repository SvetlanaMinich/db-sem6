-- Тестовый скрипт

CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    department_id NUMBER,
    salary NUMBER
);

CREATE TABLE departments (
    department_id NUMBER PRIMARY KEY,
    department_name VARCHAR2(100),
    location_id NUMBER
);


INSERT INTO departments VALUES (10, 'IT', 1000);
INSERT INTO departments VALUES (20, 'HR', 1001);
INSERT INTO departments VALUES (30, 'Finance', 1002);

INSERT INTO employees VALUES (1, 'Иван', 'Иванов', 10, 50000);
INSERT INTO employees VALUES (2, 'Мария', 'Петрова', 20, 45000);
INSERT INTO employees VALUES (3, 'Алексей', 'Сидоров', 10, 55000);
INSERT INTO employees VALUES (4, 'Елена', 'Смирнова', 30, 60000);
COMMIT;


DECLARE
    v_json CLOB;
    v_cursor SYS_REFCURSOR;
    v_employee_id employees.employee_id%TYPE;
    v_first_name employees.first_name%TYPE;
    v_last_name employees.last_name%TYPE;
    v_department_name departments.department_name%TYPE;
    v_salary employees.salary%TYPE;
BEGIN
    -- Пример 1
    v_json := '{ 
        "type": "SELECT",
        "columns": ["employee_id", "first_name", "last_name"],
        "tables": ["employees"],
        "where": [
            {"condition": "department_id = 10"}
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('Пример 1: Простой SELECT');
    v_cursor := execute_select(v_json);
    
    LOOP
        FETCH v_cursor INTO v_employee_id, v_first_name, v_last_name;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee_id || ', Имя: ' || v_first_name || ', Фамилия: ' || v_last_name);
    END LOOP;
    CLOSE v_cursor;
    
    -- Пример 2
    v_json := '{
        "type": "SELECT",
        "columns": ["e.employee_id", "e.first_name", "e.last_name", "d.department_name"],
        "tables": ["employees e"],
        "joins": [
            {
                "type": "INNER JOIN",
                "table": "departments d",
                "condition": "e.department_id = d.department_id"
            }
        ],
        "where": [
            {"condition": "e.salary > 45000"}
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Пример 2: JOIN');
    v_cursor := execute_select(v_json);
    
    LOOP
        FETCH v_cursor INTO v_employee_id, v_first_name, v_last_name, v_department_name;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee_id || ', Имя: ' || v_first_name || 
                            ', Фамилия: ' || v_last_name || ', Отдел: ' || v_department_name);
    END LOOP;
    CLOSE v_cursor;
    
    -- Пример 3
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
            {"condition": "e.salary > 40000"},
            {"connector": "AND", "condition": "(d.department_id = 10 OR d.department_id = 30)"}
        ]
    }';
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Пример 3: Сложный WHERE');
    v_cursor := execute_select(v_json);
    
    LOOP
        FETCH v_cursor INTO v_employee_id, v_first_name, v_last_name, v_salary, v_department_name;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee_id || ', Имя: ' || v_first_name || 
                            ', Фамилия: ' || v_last_name || ', Зарплата: ' || v_salary ||
                            ', Отдел: ' || v_department_name);
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

-- Очистка тестовых данных (раскомментировать, если нужно удалить тестовые таблицы)
DROP TABLE employees;
DROP TABLE departments; 