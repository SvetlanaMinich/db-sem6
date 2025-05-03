CREATE USER dev IDENTIFIED BY dev_password;
GRANT CONNECT, RESOURCE TO dev;  -- for granting access rights
ALTER USER dev QUOTA UNLIMITED ON USERS;

CREATE USER prod IDENTIFIED BY prod_password;
GRANT CONNECT, RESOURCE TO prod;
ALTER USER prod QUOTA UNLIMITED ON USERS;


-- SESSION DEV
ALTER SESSION SET CURRENT_SCHEMA = dev;
SELECT * FROM ALL_OBJECTS WHERE OWNER = 'DEV';

-- tables
CREATE TABLE circular1 (
    c_id NUMBER PRIMARY KEY,
    c2_id NUMBER
);
ALTER TABLE circular1
ADD CONSTRAINT fk_c2 FOREIGN KEY (c2_id) REFERENCES circular2(c_id);

CREATE TABLE circular2 (
    c_id NUMBER PRIMARY KEY,
    c1_id NUMBER,
    CONSTRAINT fk_c1 FOREIGN KEY (c1_id) REFERENCES circular1(c_id)
);

-- ALTER TABLE circular1 DROP CONSTRAINT fk_c2;
-- ALTER TABLE circular2 DROP CONSTRAINT fk_c1;

-- -- Затем удаляем сами таблицы
-- DROP TABLE circular1;
-- DROP TABLE circular2;

-- очередь создания
CREATE TABLE t1 (
    t_id NUMBER PRIMARY KEY,
    course_name VARCHAR2(200),
    t3_id NUMBER,
    CONSTRAINT fk_t3 FOREIGN KEY (t3_id) REFERENCES t3(t_id)
);

CREATE TABLE t2 (
    t_id NUMBER PRIMARY KEY,
    course_name VARCHAR2(200)
);

CREATE TABLE t3 (
    t_id NUMBER PRIMARY KEY,
    course_name VARCHAR2(200),
    t2_id NUMBER,
    CONSTRAINT fk_t2 FOREIGN KEY (t2_id) REFERENCES t2(t_id)
);


-- разные типы в одинаковых таблицах
CREATE TABLE test_type1 (
    t_id NUMBER PRIMARY KEY,
    course_name VARCHAR2(200)
);


CREATE TABLE students (
    student_id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    birthdate DATE,
    email VARCHAR2(150)
);
INSERT INTO students VALUES (1, 'Alice Johnson', TO_DATE('2002-05-10', 'YYYY-MM-DD'), 'alice@example.com');
INSERT INTO students VALUES (2, 'Bob Smith', TO_DATE('2001-09-22', 'YYYY-MM-DD'), 'bob@example.com');

CREATE TABLE courses (
    course_id NUMBER PRIMARY KEY,
    course_name VARCHAR2(200)
);
INSERT INTO courses VALUES (101, 'Mathematics');
INSERT INTO courses VALUES (102, 'Computer Science');

CREATE TABLE enrollments (
    enrollment_id NUMBER PRIMARY KEY,
    student_id NUMBER,
    course_id NUMBER,
    semester VARCHAR2(20),
    grade CHAR(2),
    CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES students(student_id),
    CONSTRAINT fk_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
INSERT INTO enrollments VALUES (1, 1, 101, 'Fall 2024', 'A');
INSERT INTO enrollments VALUES (2, 2, 102, 'Spring 2025', 'B');

-- indexes
CREATE INDEX index_enrollments_semester ON enrollments(semester);

-- procedures
CREATE OR REPLACE PROCEDURE select_stud(p_student_id IN NUMBER) AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Selected student: ' || p_student_id);
END;

-- functions
CREATE OR REPLACE FUNCTION get_student_email(s_id NUMBER) RETURN VARCHAR2 AS
    s_email VARCHAR2(150);
BEGIN
    SELECT email INTO s_email FROM students WHERE student_id = s_id;
    RETURN s_email;
END;

-- packages
CREATE OR REPLACE PACKAGE student_pkg AS
    PROCEDURE welcome_student(p_name VARCHAR2);
END student_pkg;
/
CREATE OR REPLACE PACKAGE BODY student_pkg AS
    PROCEDURE welcome_student(p_name VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Welcome, ' || p_name || '!');
    END;
END student_pkg;

COMMIT;


-- SESSION PROD
ALTER SESSION SET CURRENT_SCHEMA = prod;

SELECT * FROM ALL_OBJECTS WHERE OWNER = 'PROD';

CREATE TABLE test_type1 (
    t_id NUMBER PRIMARY KEY,
    course_name NUMBER
);

CREATE TABLE students (
    student_id NUMBER PRIMARY KEY,
    name VARCHAR2(100),
    birthdate DATE
    -- no email
);
INSERT INTO students VALUES (1, 'Alice Johnson', TO_DATE('2002-05-10', 'YYYY-MM-DD'));
INSERT INTO students VALUES (2, 'Bob Smith', TO_DATE('2001-09-22', 'YYYY-MM-DD'));

CREATE TABLE enrollments (
    enrollment_id NUMBER PRIMARY KEY,
    student_id NUMBER,
    course_id NUMBER,
    semester VARCHAR2(20)
    -- no grade
);
INSERT INTO enrollments VALUES (1, 1, 101, 'Fall 2024');
INSERT INTO enrollments VALUES (2, 2, 102, 'Spring 2025');

-- need to be dropped
CREATE TABLE TESTs (
    test_id NUMBER PRIMARY KEY
);

CREATE OR REPLACE FUNCTION get_student_email(s_id VARCHAR2) RETURN NUMBER AS
    s_email NUMBER;
BEGIN
    RETURN s_email;
END;


CREATE OR REPLACE PROCEDURE select_stud(p_student_id IN NUMBER) AS
BEGIN
    DBMS_OUTPUT.PUT_LINE(p_student_id);
END;

COMMIT;


DELETE FROM all_objects 
WHERE OWNER = 'PROD';

GRANT SELECT_CATALOG_ROLE, EXECUTE_CATALOG_ROLE TO SYSTEM;
GRANT SELECT ANY DICTIONARY TO SYSTEM;
GRANT CREATE ANY TABLE TO SYSTEM;
GRANT ALTER ANY TABLE TO SYSTEM;
GRANT DROP ANY TABLE TO SYSTEM;




-- COMPARE PROCEDURE
CREATE OR REPLACE PROCEDURE compare_schemas(
    dev_schema_name IN VARCHAR2,
    prod_schema_name IN VARCHAR2
) AUTHID CURRENT_USER AS
    -- CLOB - Character Large Object.
    ddl_script CLOB := ''; 
    table_created BOOLEAN := FALSE;

    -- Функция проверки существования объекта в PROD
    FUNCTION object_exists_in_prod(p_type VARCHAR2, p_name VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM all_objects
        WHERE owner = UPPER(prod_schema_name)
        AND object_type = p_type
        AND object_name = p_name;
        
        RETURN v_count > 0;
    END;

    -- Процедура генерации DDL для объекта
    PROCEDURE generate_ddl_for_object(p_type VARCHAR2, p_name VARCHAR2) IS
    BEGIN
        IF p_type = 'PACKAGE' THEN
            ddl_script := ddl_script || DBMS_METADATA.GET_DDL('PACKAGE', p_name, UPPER(dev_schema_name)) || CHR(10) || '/' || CHR(10);
            ddl_script := ddl_script || DBMS_METADATA.GET_DDL('PACKAGE_BODY', p_name, UPPER(dev_schema_name)) || CHR(10) || '/' || CHR(10);
        ELSE
            ddl_script := ddl_script || DBMS_METADATA.GET_DDL(p_type, p_name, UPPER(dev_schema_name)) || CHR(10) || '/' || CHR(10);
        END IF;
    END;
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE schema_differences (
            object_type VARCHAR2(50),
            object_name VARCHAR2(255),
            difference_type VARCHAR2(255),
            creation_order NUMBER DEFAULT 0
        )';
        table_created := TRUE;
        DBMS_OUTPUT.PUT_LINE('Temporary table schema_differences created');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -955 THEN -- ORA-00955: таблица уже существует
                table_created := TRUE;
                DBMS_OUTPUT.PUT_LINE('Temporary table schema_differences already exists');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Error creating schema_differences: ' || SQLERRM);
                RAISE;
            END IF;
    END;


    -- процедура должна предоставить перечень таблиц, которые есть в схеме Dev, но нет в Prod
    FOR t IN (
        SELECT table_name FROM all_tables
        WHERE owner = UPPER(dev_schema_name)
        AND table_name NOT IN (
            SELECT table_name FROM all_tables WHERE owner = UPPER(prod_schema_name)
        )
    ) LOOP
        EXECUTE IMMEDIATE 'INSERT INTO schema_differences (object_type, object_name, difference_type, creation_order)
                   VALUES (:1, :2, :3, :4)'
        USING 'TABLE', t.table_name, 'Missing in Prod', 0;
        
        -- Генерируем DDL для создания таблицы
        DECLARE
            first_column BOOLEAN := TRUE;
        BEGIN
            FOR col IN (
                SELECT column_name, data_type, data_length, data_precision, data_scale, nullable
                FROM all_tab_columns
                WHERE owner = UPPER(dev_schema_name) AND table_name = t.table_name
            ) LOOP
                ddl_script := ddl_script || 
                    CASE WHEN first_column THEN 'CREATE TABLE ' || t.table_name || ' (' || CHR(10) ELSE ',' || CHR(10) END ||
                    '    ' || col.column_name || ' ' || col.data_type || 
                    CASE WHEN col.data_type IN ('VARCHAR2', 'CHAR') THEN '(' || col.data_length || ')' 
                         WHEN col.data_type = 'NUMBER' AND col.data_precision IS NOT NULL THEN '(' || col.data_precision || ',' || col.data_scale || ')'
                         ELSE '' END ||
                    CASE WHEN col.nullable = 'N' THEN ' NOT NULL' ELSE '' END;
                first_column := FALSE;
            END LOOP;
            
            -- Добавляем PRIMARY KEY и FOREIGN KEY
            FOR cons IN (
                SELECT constraint_name, constraint_type, r_constraint_name
                FROM all_constraints
                WHERE owner = UPPER(dev_schema_name) AND table_name = t.table_name
            ) LOOP
                IF cons.constraint_type = 'P' THEN
                    DECLARE
                        pk_columns VARCHAR2(4000) := '';
                    BEGIN
                        FOR pk_col IN (
                            SELECT column_name
                            FROM all_cons_columns
                            WHERE owner = UPPER(dev_schema_name) AND constraint_name = cons.constraint_name
                            ORDER BY position
                        ) LOOP
                            IF pk_columns IS NOT NULL THEN
                                pk_columns := pk_columns || ', ';
                            END IF;
                            pk_columns := pk_columns || pk_col.column_name;
                        END LOOP;
                        ddl_script := ddl_script || ',' || CHR(10) || 
                            '    CONSTRAINT ' || cons.constraint_name || ' PRIMARY KEY (' || pk_columns || ')';
                    END;
                ELSIF cons.constraint_type = 'R' THEN
                    DECLARE
                        fk_columns VARCHAR2(4000) := '';
                        ref_columns VARCHAR2(4000) := '';
                        ref_table VARCHAR2(255);
                    BEGIN
                        FOR fk_col IN (
                            SELECT column_name
                            FROM all_cons_columns
                            WHERE owner = UPPER(dev_schema_name) AND constraint_name = cons.constraint_name
                            ORDER BY position
                        ) LOOP
                            IF fk_columns IS NOT NULL THEN
                                fk_columns := fk_columns || ', ';
                            END IF;
                            fk_columns := fk_columns || fk_col.column_name;
                        END LOOP;
                        FOR ref_col IN (
                            SELECT column_name
                            FROM all_cons_columns
                            WHERE owner = UPPER(dev_schema_name) AND constraint_name = cons.r_constraint_name
                            ORDER BY position
                        ) LOOP
                            IF ref_columns IS NOT NULL THEN
                                ref_columns := ref_columns || ', ';
                            END IF;
                            ref_columns := ref_columns || ref_col.column_name;
                        END LOOP;
                        SELECT table_name INTO ref_table
                        FROM all_constraints
                        WHERE owner = UPPER(dev_schema_name) AND constraint_name = cons.r_constraint_name;
                        ddl_script := ddl_script || ',' || CHR(10) || 
                            '    CONSTRAINT ' || cons.constraint_name || ' FOREIGN KEY (' || fk_columns || 
                            ') REFERENCES ' || ref_table || ' (' || ref_columns || ')';
                    END;
                END IF;
            END LOOP;
            ddl_script := ddl_script || CHR(10) || ');' || CHR(10) || CHR(10);
        END;
    END LOOP;

    -- либо в которых различается структура таблиц
    FOR rec IN (
        SELECT d.table_name FROM all_tables d
        JOIN all_tables p ON d.table_name = p.table_name
        WHERE d.owner = UPPER(dev_schema_name) AND p.owner = UPPER(prod_schema_name)
    ) LOOP
        FOR col_diff IN (
            SELECT column_name, data_type, data_length, data_precision, data_scale, nullable
            FROM all_tab_columns
            WHERE owner = UPPER(dev_schema_name) AND table_name = rec.table_name
            MINUS
            SELECT column_name, data_type, data_length, data_precision, data_scale, nullable
            FROM all_tab_columns
            WHERE owner = UPPER(prod_schema_name) AND table_name = rec.table_name
        ) LOOP
            EXECUTE IMMEDIATE 'INSERT INTO schema_differences (object_type, object_name, difference_type, creation_order)
                    VALUES (:1, :2, :3, :4)'
            USING 'TABLE', rec.table_name, 'Column mismatch: ' || col_diff.column_name, 0;
            ddl_script := ddl_script || 'ALTER TABLE ' || rec.table_name || ' ADD (' || col_diff.column_name || ' ' || 
                col_diff.data_type || 
                CASE WHEN col_diff.data_type IN ('VARCHAR2', 'CHAR') THEN '(' || col_diff.data_length || ')' 
                     WHEN col_diff.data_type = 'NUMBER' AND col_diff.data_precision IS NOT NULL THEN '(' || col_diff.data_precision || ',' || col_diff.data_scale || ')'
                     ELSE '' END ||
                CASE WHEN col_diff.nullable = 'N' THEN ' NOT NULL' ELSE '' END || ');' || CHR(10);
        END LOOP;
    END LOOP;


    -- с учетом возможности сравнения не только таблиц, но и процедур, функций, индексов пакетов
    FOR obj IN (
        SELECT object_type, object_name 
        FROM all_objects 
        WHERE owner = UPPER(dev_schema_name)
        AND object_type IN ('FUNCTION', 'PACKAGE', 'INDEX', 'PROCEDURE')
        AND object_name NOT LIKE 'SYS\_%' ESCAPE '\'
    ) LOOP
        -- Проверяем наличие объекта в PROD
        IF NOT object_exists_in_prod(obj.object_type, obj.object_name) THEN
            DBMS_OUTPUT.PUT_LINE('NOT IN PROD  -> ' || UPPER(obj.object_type));
            -- Объект отсутствует в PROD
            EXECUTE IMMEDIATE 'INSERT INTO schema_differences 
                            (object_type, object_name, difference_type, creation_order)
                            VALUES (:1, :2, :3, :4)'
            USING obj.object_type, obj.object_name, 'Missing in Prod', 0;
            
            -- Генерируем DDL для отсутствующего объекта
            generate_ddl_for_object(obj.object_type, obj.object_name);
        ELSE
            -- Объект есть в PROD, проверяем содержание
            DECLARE
                v_dev_ddl  CLOB;
                v_prod_ddl CLOB;
            BEGIN
                -- Получаем DDL из DEV
                BEGIN
                    v_dev_ddl := DBMS_METADATA.GET_DDL(obj.object_type, obj.object_name, UPPER(dev_schema_name));
                EXCEPTION
                    WHEN OTHERS THEN
                        v_dev_ddl := 'ERROR:' || SQLERRM;
                END;
                
                -- Получаем DDL из PROD
                BEGIN
                    v_prod_ddl := DBMS_METADATA.GET_DDL(obj.object_type, obj.object_name, UPPER(prod_schema_name));
                EXCEPTION
                    WHEN OTHERS THEN
                        v_prod_ddl := 'ERROR:' || SQLERRM;
                END;

                -- Сравнение содержимого
                IF v_dev_ddl <> v_prod_ddl THEN
                    EXECUTE IMMEDIATE '
                        INSERT INTO schema_differences 
                        (object_type, object_name, difference_type, creation_order)
                        VALUES (:1, :2, :3, :4)'
                    USING obj.object_type, obj.object_name, 'Mismatch functionality', 0;
                    
                    generate_ddl_for_object(obj.object_type, obj.object_name);
                END IF;
            END;
        END IF;
    END LOOP;

    -- с учетом необходимости удаления в схеме prod объектов, отсутствующих в схеме dev 
    FOR missing_dev IN (
        SELECT object_type, object_name FROM all_objects
        WHERE owner = UPPER(prod_schema_name)
        AND object_type IN ('TABLE', 'PROCEDURE', 'FUNCTION', 'PACKAGE', 'INDEX')
        AND object_name NOT IN (
            SELECT object_name FROM all_objects WHERE owner = UPPER(dev_schema_name)
        )
        AND object_name NOT LIKE 'SYS\_%' ESCAPE '\'
    ) LOOP
        -- INSERT INTO schema_differences
        -- VALUES (missing_dev.object_type, missing_dev.object_name, 'Should be dropped in Prod');
        ddl_script := ddl_script || 'DROP ' || missing_dev.object_type || ' ' || missing_dev.object_name || ';' || CHR(10);
    END LOOP;
    
    -- Наименования таблиц должны быть отсортированы в соответствии с очередностью их возможного создания в схеме prod
    DECLARE
        -----------------------------------------------------------------
        -- Загружаем foreign key зависимости из all_constraints схемы dev в коллекцию
        TYPE t_dep_rec IS RECORD (
            table_name  VARCHAR2(255),
            depends_on  VARCHAR2(255)
        );
        TYPE t_dep_tab IS TABLE OF t_dep_rec;
        v_deps t_dep_tab;
        -----------------------------------------------------------------
        -- Коллекция для отслеживания посещенных таблиц
        TYPE t_visited IS TABLE OF BOOLEAN INDEX BY VARCHAR2(255);
        visited t_visited;
        -----------------------------------------------------------------
        -- Коллекция для отсортированных имен таблиц
        sorted SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
        -----------------------------------------------------------------
        -- Коллекция для имен таблиц из schema_differences (только TABLE)
        TYPE t_tbl_names IS TABLE OF VARCHAR2(255);
        v_tbl_names t_tbl_names;
        -----------------------------------------------------------------
        -- Рекурсивная процедура обхода зависимостей
        PROCEDURE visit(p_table VARCHAR2) IS
        BEGIN
            IF visited.EXISTS(p_table) THEN
                RETURN;
            END IF;
            visited(p_table) := TRUE;
            FOR i IN 1 .. v_deps.COUNT LOOP
                IF v_deps(i).table_name = p_table THEN
                    visit(v_deps(i).depends_on);
                END IF;
            END LOOP;
            sorted.EXTEND;
            sorted(sorted.COUNT) := p_table;
        END;
    BEGIN
        -- Загружаем зависимости (foreign key) для схемы dev
        SELECT a.table_name, c_pk.table_name
        BULK COLLECT INTO v_deps
        FROM all_constraints a
        JOIN all_constraints c_pk 
            ON a.r_constraint_name = c_pk.constraint_name
        WHERE a.constraint_type = 'R'
          AND a.owner = UPPER(dev_schema_name);

        -- Получаем список таблиц из schema_differences динамически
        EXECUTE IMMEDIATE 
          'SELECT DISTINCT object_name FROM schema_differences WHERE object_type = ''TABLE'''
          BULK COLLECT INTO v_tbl_names;

        -- Выполняем обход для каждой таблицы
        FOR idx IN 1 .. v_tbl_names.COUNT LOOP
            visit(v_tbl_names(idx));
        END LOOP;

        -- Обновляем поле creation_order для таблиц в соответствии с топологической сортировкой
        FOR i IN 1 .. sorted.COUNT LOOP
            EXECUTE IMMEDIATE '
                UPDATE schema_differences 
                SET creation_order = :1 
                WHERE object_type = ''TABLE'' AND object_name = :2'
            USING i, sorted(i);
        END LOOP;
    END;
    
    -- В случае закольцованных связей выводить соответствующее сообщение
    DECLARE
        TYPE t_edge IS RECORD (
            from_table VARCHAR2(255),
            to_table   VARCHAR2(255)
        );
        TYPE t_edge_tab IS TABLE OF t_edge;
        edges t_edge_tab;

        TYPE t_path IS TABLE OF VARCHAR2(255) INDEX BY VARCHAR2(255);
        visited t_path;
        path t_path;

        PROCEDURE find_cycles(current_table VARCHAR2, start_table VARCHAR2) IS
        BEGIN
            IF visited.EXISTS(current_table) THEN
                IF current_table = start_table THEN
                    DBMS_OUTPUT.PUT_LINE('Circular dependency detected at: ' || start_table);
                END IF;
                RETURN;
            END IF;

            visited(current_table) := '1';
            path(current_table) := '1';

            FOR i IN 1 .. edges.COUNT LOOP
                IF edges(i).from_table = current_table THEN
                    find_cycles(edges(i).to_table, start_table);
                END IF;
            END LOOP;

            path.DELETE(current_table);
        END;
    BEGIN
        -- Загружаем все foreign key зависимости между таблицами схемы
        SELECT a.table_name, pk.table_name
        BULK COLLECT INTO edges
        FROM all_constraints a
        JOIN all_constraints pk ON a.r_constraint_name = pk.constraint_name
        WHERE a.constraint_type = 'R'
        AND a.owner = UPPER(dev_schema_name)
        AND pk.owner = UPPER(dev_schema_name);

        -- Запускаем поиск циклов с каждой таблицы
        FOR i IN 1 .. edges.COUNT LOOP
            visited.DELETE;
            path.DELETE;
            find_cycles(edges(i).from_table, edges(i).from_table);
        END LOOP;
    END;

    
    DECLARE
        v_object_type VARCHAR2(50);
        v_object_name VARCHAR2(255);
        v_difference_type VARCHAR2(255);
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR 'SELECT object_type, object_name, difference_type
                           FROM schema_differences 
                           ORDER BY CASE WHEN object_type = ''TABLE'' THEN 1 ELSE 2 END, creation_order';
        LOOP
            FETCH v_cursor INTO v_object_type, v_object_name, v_difference_type;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(v_object_type || ': ' || v_object_name || ' - ' || v_difference_type);
        END LOOP;
        CLOSE v_cursor;
    END;

    -- generated ddl-script
    DBMS_OUTPUT.PUT_LINE('--- GENERATED DDL SCRIPT ---');
    DBMS_OUTPUT.PUT_LINE(ddl_script);

    EXECUTE IMMEDIATE 'DROP TABLE schema_differences';
END compare_schemas;

---------------------------------------------------------------

SELECT USER FROM DUAL;
GRANT SELECT_CATALOG_ROLE TO SYSTEM;
GRANT EXECUTE_CATALOG_ROLE TO SYSTEM;

SELECT owner, object_name, object_type 
FROM all_objects 
WHERE object_name = 'COMPARE_SCHEMAS' AND object_type = 'PROCEDURE';

ALTER SESSION SET CURRENT_SCHEMA = SYSTEM;


BEGIN
    compare_schemas('dev', 'prod');
END;