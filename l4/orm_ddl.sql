CREATE OR REPLACE FUNCTION execute_ddl(p_json IN CLOB)
RETURN SYS_REFCURSOR
AS
    l_cursor          SYS_REFCURSOR;
    l_sql             VARCHAR2(32767);
    l_command         VARCHAR2(20);
    l_table           VARCHAR2(50);
    l_columns_string  VARCHAR2(4000);
    l_cascade         VARCHAR2(10);
    l_index           NUMBER := 0;
    l_col_name        VARCHAR2(100);
    l_col_type        VARCHAR2(100);
    l_col_constraints VARCHAR2(500);
    l_col_def         VARCHAR2(400);
    l_pk_column       VARCHAR2(100);
BEGIN
    -- Извлекаем команду и имя таблицы из JSON
    l_command := JSON_VALUE(p_json, '$.command');
    l_table   := JSON_VALUE(p_json, '$.table');
    
    IF UPPER(l_command) = 'CREATE' THEN
         l_columns_string := '';
         l_index := 0;
         LOOP
             l_col_name := JSON_VALUE(p_json, '$.columns[' || l_index || '].name');
             EXIT WHEN l_col_name IS NULL;
             l_col_type := JSON_VALUE(p_json, '$.columns[' || l_index || '].type');
             l_col_constraints := JSON_VALUE(p_json, '$.columns[' || l_index || '].constraints');
             IF l_col_constraints IS NOT NULL THEN
                 IF INSTR(UPPER(l_col_constraints), 'PRIMARY KEY') > 0 THEN
                     l_pk_column := l_col_name;
                 END IF;
                 l_col_def := l_col_name || ' ' || l_col_type || ' ' || l_col_constraints;
             ELSE
                 l_col_def := l_col_name || ' ' || l_col_type;
             END IF;
             IF l_index = 0 THEN
                 l_columns_string := l_col_def;
             ELSE
                 l_columns_string := l_columns_string || ', ' || l_col_def;
             END IF;
             l_index := l_index + 1;
         END LOOP;
         l_sql := 'CREATE TABLE ' || l_table || ' (' || l_columns_string || ')';
         EXECUTE IMMEDIATE l_sql;

         IF l_pk_column IS NOT NULL THEN
             DBMS_OUTPUT.PUT_LINE('PK column: ' || l_pk_column);
             l_sql := 'CREATE SEQUENCE ' || l_table || '_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
             EXECUTE IMMEDIATE l_sql;

             l_sql := 'CREATE OR REPLACE TRIGGER ' || l_table || '_trg ' || CHR(10) ||
                      'BEFORE INSERT ON ' || l_table || CHR(10) ||
                      'FOR EACH ROW' || CHR(10) ||
                      'BEGIN' || CHR(10) ||
                      '  IF :new.' || l_pk_column || ' IS NULL THEN' || CHR(10) ||
                      '    :new.' || l_pk_column || ' := ' || l_table || '_seq.NEXTVAL;' || CHR(10) ||
                      '  END IF;' || CHR(10) ||
                      'END;';
             EXECUTE IMMEDIATE l_sql;
             DBMS_OUTPUT.PUT_LINE('Trigger created: ' || l_sql);
         END IF;
         
    ELSIF UPPER(l_command) = 'DROP' THEN
         l_sql := 'DROP TABLE ' || l_table;
         -- При наличии настройки cascade добавляем опцию CASCADE CONSTRAINTS
         IF JSON_EXISTS(p_json, '$.cascade') THEN
             l_cascade := JSON_VALUE(p_json, '$.cascade');
             IF UPPER(l_cascade) = 'TRUE' THEN
                 l_sql := l_sql || ' CASCADE CONSTRAINTS';
             END IF;
         END IF;
         EXECUTE IMMEDIATE l_sql;
         
    ELSE
         RAISE_APPLICATION_ERROR(-20001, 'Unsupported DDL command');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('DDL Query: ' || l_sql);
    OPEN l_cursor FOR SELECT 'DDL operation completed successfully.' AS message FROM dual;
    RETURN l_cursor;
    
EXCEPTION
    WHEN OTHERS THEN
         DECLARE
              v_error_msg VARCHAR2(4000);
         BEGIN
              v_error_msg := 'Error: ' || SQLERRM;
              OPEN l_cursor FOR SELECT v_error_msg AS message FROM dual;
              RETURN l_cursor;
         END;
END execute_ddl;
/
