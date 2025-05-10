SET SERVEROUTPUT ON;

BEGIN
    INSERT INTO departments (dept_id, dept_name, created_date) VALUES (1, 'HR', SYSDATE);
    UPDATE departments SET dept_name = 'HR Updated' WHERE dept_id = 1;
    DELETE FROM departments WHERE dept_id = 1;
    COMMIT;

    FOR rec IN (SELECT audit_id, dept_id, dept_name, created_date, operation_type, operation_date FROM departments_audit ORDER BY audit_id) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.audit_id);
        DBMS_OUTPUT.PUT_LINE('Dept_ID: ' || rec.dept_id);
        DBMS_OUTPUT.PUT_LINE('Dept_Name: ' || rec.dept_name);
        DBMS_OUTPUT.PUT_LINE('Created_Date: ' || TO_CHAR(rec.created_date, 'DD.MM.YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('Op_Type: ' || rec.operation_type);
        DBMS_OUTPUT.PUT_LINE('Op_Date: ' || TO_CHAR(rec.operation_date, 'DD.MM.YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('--------------------------------');
    END LOOP;
END;
/
DELETE FROM departments_audit;


BEGIN
    INSERT INTO departments (dept_id, dept_name, created_date) VALUES (2, 'Sales', SYSDATE);
    INSERT INTO employees (emp_id, emp_name, hire_date, dept_id) VALUES (101, 'Alice', SYSDATE, 2);
    UPDATE employees SET emp_name = 'Alice Updated' WHERE emp_id = 101;
    DELETE FROM employees WHERE emp_id = 101;
    COMMIT;

    FOR rec IN (SELECT audit_id, emp_id, emp_name, hire_date, dept_id, operation_type, operation_date FROM employees_audit ORDER BY audit_id) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.audit_id);
        DBMS_OUTPUT.PUT_LINE('Emp_ID: ' || rec.emp_id);
        DBMS_OUTPUT.PUT_LINE('Emp_Name: ' || rec.emp_name);
        DBMS_OUTPUT.PUT_LINE('Hire_Date: ' || TO_CHAR(rec.hire_date, 'DD.MM.YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('Dept_ID: ' || rec.dept_id);
        DBMS_OUTPUT.PUT_LINE('Op_Type: ' || rec.operation_type);
        DBMS_OUTPUT.PUT_LINE('Op_Date: ' || TO_CHAR(rec.operation_date, 'DD.MM.YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('--------------------------------');
    END LOOP;
END;
/
DELETE FROM employees_audit;


BEGIN
    INSERT INTO departments (dept_id, dept_name, created_date) VALUES (3, 'Finance', SYSDATE);
    INSERT INTO employees (emp_id, emp_name, hire_date, dept_id) VALUES (102, 'Bob', SYSDATE, 3);
    INSERT INTO salary_history (history_id, emp_id, salary, change_date) VALUES (201, 102, 5000, SYSDATE);
    UPDATE salary_history SET salary = 5500 WHERE history_id = 201;
    DELETE FROM salary_history WHERE history_id = 201;
    COMMIT;

    FOR rec IN (SELECT audit_id, history_id, emp_id, salary, change_date, operation_type, operation_date FROM salary_history_audit ORDER BY audit_id) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.audit_id);
        DBMS_OUTPUT.PUT_LINE('History_ID: ' || rec.history_id);
        DBMS_OUTPUT.PUT_LINE('Emp_ID: ' || rec.emp_id);
        DBMS_OUTPUT.PUT_LINE('Salary: ' || rec.salary);
        DBMS_OUTPUT.PUT_LINE('Change_Date: ' || TO_CHAR(rec.change_date, 'DD.MM.YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('Op_Type: ' || rec.operation_type);
        DBMS_OUTPUT.PUT_LINE('Op_Date: ' || TO_CHAR(rec.operation_date, 'DD.MM.YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('--------------------------------');
    END LOOP;
END;
/
DELETE FROM salary_history_audit;



DELETE FROM departments;
DELETE FROM employees;
DELETE FROM salary_history;


--
-- Тест rollback для таблицы DEPARTMENTS с использованием параметра даты
DECLARE
    v_rollback_time DATE;
BEGIN
    INSERT INTO departments (dept_id, dept_name, created_date) VALUES (10, 'Initial Dept', SYSDATE);
    COMMIT;
    SELECT SYSDATE INTO v_rollback_time FROM dual;
    DBMS_LOCK.SLEEP(2);
    
    UPDATE departments SET dept_name = 'Updated Dept' WHERE dept_id = 10;
    DELETE FROM departments WHERE dept_id = 10;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Состояние таблицы DEPARTMENTS до rollback:');
    FOR rec IN (SELECT dept_id, dept_name FROM departments WHERE dept_id = 10) LOOP
        DBMS_OUTPUT.PUT_LINE('Dept: ' || rec.dept_id || ' - ' || rec.dept_name);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    DBMS_OUTPUT.PUT_LINE('*** Состояние таблицы departments_audit до rollback: ***');
    FOR rec IN (SELECT audit_id, dept_id, dept_name, created_date, operation_type, operation_date
                FROM departments_audit
                ORDER BY operation_date) LOOP
        DBMS_OUTPUT.PUT_LINE('Audit Record -> ID: ' || rec.audit_id ||
                             ', Dept ID: ' || rec.dept_id ||
                             ', Name: ' || rec.dept_name ||
                             ', Created: ' || TO_CHAR(rec.created_date, 'DD.MM.YYYY HH24:MI:SS') ||
                             ', Operation: ' || rec.operation_type ||
                             ', Date: ' || TO_CHAR(rec.operation_date, 'DD.MM.YYYY HH24:MI:SS'));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');

    rollback_pkg.rollback_changes(v_rollback_time);

    DBMS_OUTPUT.PUT_LINE('Состояние таблицы DEPARTMENTS после rollback с параметром даты:');
    FOR rec IN (SELECT dept_id, dept_name FROM departments WHERE dept_id = 10) LOOP
        DBMS_OUTPUT.PUT_LINE('Dept: ' || rec.dept_id || ' - ' || rec.dept_name);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    DBMS_OUTPUT.PUT_LINE('*** Состояние таблицы departments_audit после rollback: ***');
    FOR rec IN (SELECT audit_id, dept_id, dept_name, created_date, operation_type, operation_date
                FROM departments_audit
                ORDER BY operation_date) LOOP
        DBMS_OUTPUT.PUT_LINE('Audit Record -> ID: ' || rec.audit_id ||
                             ', Dept ID: ' || rec.dept_id ||
                             ', Name: ' || rec.dept_name ||
                             ', Created: ' || TO_CHAR(rec.created_date, 'DD.MM.YYYY HH24:MI:SS') ||
                             ', Operation: ' || rec.operation_type ||
                             ', Date: ' || TO_CHAR(rec.operation_date, 'DD.MM.YYYY HH24:MI:SS'));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
        ROLLBACK;
END;
/


DELETE FROM departments_audit;
DELETE FROM departments;

--
-- Тест удаления из аудита
DECLARE
    v_target_date DATE;
BEGIN
    INSERT INTO departments (dept_id, dept_name, created_date) VALUES (11, 'TestDept', SYSDATE);
    COMMIT;
    DBMS_LOCK.SLEEP(2);
    SELECT SYSDATE INTO v_target_date FROM dual;
    DBMS_LOCK.SLEEP(2);
    DELETE FROM departments WHERE dept_id = 11;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Состояние таблицы DEPARTMENTS до rollback:');
    FOR rec IN (SELECT dept_id, dept_name FROM departments WHERE dept_id = 11) LOOP
        DBMS_OUTPUT.PUT_LINE('Dept: ' || rec.dept_id || ' - ' || rec.dept_name);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    DBMS_OUTPUT.PUT_LINE('*** Состояние таблицы departments_audit до rollback: ***');
    FOR rec IN (SELECT audit_id, dept_id, dept_name, created_date, operation_type, operation_date
                FROM departments_audit
                ORDER BY operation_date) LOOP
        DBMS_OUTPUT.PUT_LINE('Audit Record -> ID: ' || rec.audit_id ||
                             ', Dept ID: ' || rec.dept_id ||
                             ', Name: ' || rec.dept_name ||
                             ', Created: ' || TO_CHAR(rec.created_date, 'DD.MM.YYYY HH24:MI:SS') ||
                             ', Operation: ' || rec.operation_type ||
                             ', Date: ' || TO_CHAR(rec.operation_date, 'DD.MM.YYYY HH24:MI:SS'));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');

    rollback_pkg.rollback_changes(v_target_date);
    
    DBMS_OUTPUT.PUT_LINE('Состояние таблицы DEPARTMENTS после rollback:');
    FOR rec IN (SELECT dept_id, dept_name FROM departments WHERE dept_id = 11) LOOP
        DBMS_OUTPUT.PUT_LINE('Dept: ' || rec.dept_id || ' - ' || rec.dept_name);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    DBMS_OUTPUT.PUT_LINE('*** Состояние таблицы departments_audit после rollback: ***');
    FOR rec IN (SELECT audit_id, dept_id, dept_name, created_date, operation_type, operation_date
                FROM departments_audit
                ORDER BY operation_date) LOOP
        DBMS_OUTPUT.PUT_LINE('Audit Record -> ID: ' || rec.audit_id ||
                             ', Dept ID: ' || rec.dept_id ||
                             ', Name: ' || rec.dept_name ||
                             ', Created: ' || TO_CHAR(rec.created_date, 'DD.MM.YYYY HH24:MI:SS') ||
                             ', Operation: ' || rec.operation_type ||
                             ', Date: ' || TO_CHAR(rec.operation_date, 'DD.MM.YYYY HH24:MI:SS'));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
END;
/

--
-- Тест rollback для таблицы SALARY_HISTORY (параметр интервала)
DECLARE
    v_interval_ms NUMBER := 5000;
BEGIN
    DBMS_LOCK.SLEEP(5);
    INSERT INTO departments (dept_id, dept_name, created_date) VALUES (52, 'SalHistDept', SYSDATE);
    COMMIT;

    INSERT INTO employees (emp_id, emp_name, hire_date, dept_id) VALUES (52, 'SalHist Emp', SYSDATE, 52);
    COMMIT;
    UPDATE employees SET emp_name = 'SalHist Emp Updated' WHERE emp_id = 52;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Состояние таблицы DEPARTMENTS до rollback:');
    FOR rec IN (SELECT dept_id, dept_name FROM departments WHERE dept_id = 52) LOOP
        DBMS_OUTPUT.PUT_LINE('Dept: ' || rec.dept_id || ' - ' || rec.dept_name);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Состояние таблицы EMPLOYEES до rollback:');
    FOR rec IN (SELECT emp_id, emp_name FROM employees WHERE emp_id = 52) LOOP
        DBMS_OUTPUT.PUT_LINE('Employee: ' || rec.emp_id || ' - ' || rec.emp_name);
    END LOOP;

    rollback_pkg.rollback_changes(v_interval_ms);
    
    DBMS_OUTPUT.PUT_LINE('Состояние таблицы DEPARTMENTS после rollback с параметром интервала:');
    FOR rec IN (SELECT dept_id, dept_name FROM departments WHERE dept_id = 52) LOOP
        DBMS_OUTPUT.PUT_LINE('Dept: ' || rec.dept_id || ' - ' || rec.dept_name);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Состояние таблицы EMPLOYEES после rollback с параметром интервала:');
    FOR rec IN (SELECT emp_id, emp_name FROM employees WHERE emp_id = 52) LOOP
        DBMS_OUTPUT.PUT_LINE('Employee: ' || rec.emp_id || ' - ' || rec.emp_name);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
        ROLLBACK;
END;
/   

select * from employees;
select * from departments;



-- Тест процедуры generate_audit_report
DECLARE
BEGIN
    generate_audit_report(SYSDATE - 1);
    DBMS_OUTPUT.PUT_LINE('Состояние таблицы REPORT_LOG за день до:');
    FOR rec IN (SELECT report_id, creation_date, report_content FROM report_log) LOOP
        DBMS_OUTPUT.PUT_LINE('Report (ID-TIME-CONTENT): ' || rec.report_id || ' - ' || rec.creation_date || ' - ' || rec.report_content);
    END LOOP;
END;
/

DECLARE
BEGIN
    generate_audit_report();
    DBMS_OUTPUT.PUT_LINE('Состояние таблицы REPORT_LOG с последнего отчета:');
    DBMS_OUTPUT.PUT_LINE('  ');
    FOR rec IN (SELECT report_id, creation_date, report_content FROM report_log) LOOP
        DBMS_OUTPUT.PUT_LINE('Report (ID-TIME-CONTENT): ' || rec.report_id || ' - ' || rec.creation_date || ' - ' || rec.report_content);
        DBMS_OUTPUT.PUT_LINE('--------------------------------');
    END LOOP;
END;
/


SELECT * FROM all_directories;

