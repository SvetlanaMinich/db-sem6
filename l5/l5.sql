CREATE TABLE departments (
    dept_id NUMBER PRIMARY KEY,
    dept_name VARCHAR2(100) NOT NULL,
    created_date DATE NOT NULL
);
DROP TABLE departments;

CREATE TABLE employees (
    emp_id NUMBER PRIMARY KEY,
    emp_name VARCHAR2(100) NOT NULL,
    hire_date DATE NOT NULL,
    dept_id NUMBER NOT NULL,
    CONSTRAINT fk_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
DROP TABLE employees;

CREATE TABLE salary_history (
    history_id NUMBER PRIMARY KEY,
    emp_id NUMBER NOT NULL,
    salary NUMBER NOT NULL,
    change_date DATE NOT NULL,
    CONSTRAINT fk_employee FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);
DROP TABLE salary_history;



CREATE SEQUENCE audit_seq START WITH 1 INCREMENT BY 1;

-- таблицы для хранения историй DML операций на каждой таблице
CREATE TABLE departments_audit (
    audit_id NUMBER PRIMARY KEY,
    dept_id NUMBER,
    dept_name VARCHAR2(100),
    created_date DATE,
    operation_type VARCHAR2(10),
    operation_date DATE
);

CREATE TABLE employees_audit (
    audit_id NUMBER PRIMARY KEY,
    emp_id NUMBER,
    emp_name VARCHAR2(100),
    hire_date DATE,
    dept_id NUMBER,
    operation_type VARCHAR2(10),
    operation_date DATE
);

CREATE TABLE salary_history_audit (
    audit_id NUMBER PRIMARY KEY,
    history_id NUMBER,
    emp_id NUMBER,
    salary NUMBER,
    change_date DATE,
    operation_type VARCHAR2(10),
    operation_date DATE
);

CREATE OR REPLACE TRIGGER trg_departments_audit
AFTER INSERT OR UPDATE OR DELETE ON departments
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO departments_audit (audit_id, dept_id, dept_name, created_date, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :NEW.dept_id, :NEW.dept_name, :NEW.created_date, 'INSERT', SYSDATE);
    ELSIF UPDATING THEN
        INSERT INTO departments_audit (audit_id, dept_id, dept_name, created_date, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :OLD.dept_id, :OLD.dept_name, :OLD.created_date, 'UPDATE', SYSDATE);
    ELSIF DELETING THEN
        INSERT INTO departments_audit (audit_id, dept_id, dept_name, created_date, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :OLD.dept_id, :OLD.dept_name, :OLD.created_date, 'DELETE', SYSDATE);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_employees_audit
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO employees_audit (audit_id, emp_id, emp_name, hire_date, dept_id, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :NEW.emp_id, :NEW.emp_name, :NEW.hire_date, :NEW.dept_id, 'INSERT', SYSDATE);
    ELSIF UPDATING THEN
        INSERT INTO employees_audit (audit_id, emp_id, emp_name, hire_date, dept_id, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :OLD.emp_id, :OLD.emp_name, :OLD.hire_date, :OLD.dept_id, 'UPDATE', SYSDATE);
    ELSIF DELETING THEN
        INSERT INTO employees_audit (audit_id, emp_id, emp_name, hire_date, dept_id, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :OLD.emp_id, :OLD.emp_name, :OLD.hire_date, :OLD.dept_id, 'DELETE', SYSDATE);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_salary_history_audit
AFTER INSERT OR UPDATE OR DELETE ON salary_history
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO salary_history_audit (audit_id, history_id, emp_id, salary, change_date, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :NEW.history_id, :NEW.emp_id, :NEW.salary, :NEW.change_date, 'INSERT', SYSDATE);
    ELSIF UPDATING THEN
        INSERT INTO salary_history_audit (audit_id, history_id, emp_id, salary, change_date, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :OLD.history_id, :OLD.emp_id, :OLD.salary, :OLD.change_date, 'UPDATE', SYSDATE);
    ELSIF DELETING THEN
        INSERT INTO salary_history_audit (audit_id, history_id, emp_id, salary, change_date, operation_type, operation_date)
        VALUES (audit_seq.NEXTVAL, :OLD.history_id, :OLD.emp_id, :OLD.salary, :OLD.change_date, 'DELETE', SYSDATE);
    END IF;
END;
/
