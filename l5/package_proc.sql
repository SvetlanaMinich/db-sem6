CREATE OR REPLACE PACKAGE rollback_pkg AS
  PROCEDURE rollback_changes(v_target_date IN DATE);
  PROCEDURE rollback_changes(v_interval_ms IN NUMBER);
END rollback_pkg;
/

CREATE OR REPLACE PACKAGE BODY rollback_pkg AS
    PROCEDURE rollback_changes(v_target_date IN DATE) IS
    BEGIN
        FOR rec IN (SELECT * FROM salary_history_audit
                    WHERE operation_date > v_target_date
                    ORDER BY operation_date DESC) LOOP
            IF rec.operation_type = 'INSERT' THEN
                DELETE FROM salary_history WHERE history_id = rec.history_id;
            ELSIF rec.operation_type = 'UPDATE' THEN
                UPDATE salary_history SET emp_id = rec.emp_id, salary = rec.salary, change_date = rec.change_date
                WHERE history_id = rec.history_id;
            ELSIF rec.operation_type = 'DELETE' THEN
                INSERT INTO salary_history(history_id, emp_id, salary, change_date)
                VALUES (rec.history_id, rec.emp_id, rec.salary, rec.change_date);
            END IF;
        END LOOP;

        FOR rec IN (SELECT * FROM employees_audit
                    WHERE operation_date > v_target_date
                    ORDER BY operation_date DESC) LOOP
            IF rec.operation_type = 'INSERT' THEN
                DELETE FROM employees WHERE emp_id = rec.emp_id;
            ELSIF rec.operation_type = 'UPDATE' THEN
                UPDATE employees SET emp_name = rec.emp_name, hire_date = rec.hire_date, dept_id = rec.dept_id
                WHERE emp_id = rec.emp_id;
            ELSIF rec.operation_type = 'DELETE' THEN
                INSERT INTO employees(emp_id, emp_name, hire_date, dept_id)
                VALUES (rec.emp_id, rec.emp_name, rec.hire_date, rec.dept_id);
            END IF;
        END LOOP;

        FOR rec IN (SELECT * FROM departments_audit
                    WHERE operation_date > v_target_date
                    ORDER BY operation_date DESC) LOOP
            IF rec.operation_type = 'INSERT' THEN
                DELETE FROM departments WHERE dept_id = rec.dept_id;
            ELSIF rec.operation_type = 'UPDATE' THEN
                UPDATE departments SET dept_name = rec.dept_name, created_date = rec.created_date
                WHERE dept_id = rec.dept_id;
            ELSIF rec.operation_type = 'DELETE' THEN
                INSERT INTO departments(dept_id, dept_name, created_date)
                VALUES (rec.dept_id, rec.dept_name, rec.created_date);
            END IF;
        END LOOP;       

        DELETE FROM salary_history_audit WHERE operation_date > v_target_date;
        DELETE FROM employees_audit WHERE operation_date > v_target_date;
        DELETE FROM departments_audit WHERE operation_date > v_target_date;

        COMMIT;
    END rollback_changes;

    PROCEDURE rollback_changes(v_interval_ms IN NUMBER) IS
        v_target_date DATE;
    BEGIN
        -- 1 day = 86400000 ms
        v_target_date := SYSDATE - (v_interval_ms / 86400000);
        rollback_changes(v_target_date);
    END rollback_changes;

END rollback_pkg;
/
