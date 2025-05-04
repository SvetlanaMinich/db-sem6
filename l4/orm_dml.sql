CREATE OR REPLACE FUNCTION execute_dml(p_json IN CLOB)
RETURN SYS_REFCURSOR
AS
    l_cursor SYS_REFCURSOR;
    l_sql    VARCHAR2(32767);
    l_type   VARCHAR2(10);
    l_table  VARCHAR2(50);
    l_columns VARCHAR2(1000);
    l_values  VARCHAR2(1000);
    l_set     VARCHAR2(1000);
    l_conditions VARCHAR2(1000);
    l_nested_sql VARCHAR2(32767);
BEGIN
    -- Парсим JSON (используем встроенные функции Oracle)
    l_type := JSON_VALUE(p_json, '$.type');
    l_table := JSON_VALUE(p_json, '$.table');
    
    IF l_type = 'INSERT' THEN
        l_columns := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.columns'), '[', ''), ']', ''), '"', '');
        DECLARE
            l_values_raw VARCHAR2(1000);
        BEGIN
            l_values_raw := JSON_QUERY(p_json, '$.values');
            IF JSON_EXISTS(p_json, '$.nested') THEN
                DECLARE
                    l_n_columns VARCHAR2(4000);
                    l_n_tables  VARCHAR2(4000);
                    l_n_conditions VARCHAR2(4000) := '';
                BEGIN
                    l_n_columns := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.nested.columns'), '[', ''), ']', ''), '"', '');
                    l_n_tables  := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.nested.tables'), '[', ''), ']', ''), '"', '');
                    IF JSON_EXISTS(p_json, '$.nested.conditions') THEN
                        l_n_conditions := ' WHERE ' || JSON_VALUE(p_json, '$.nested.conditions');
                    END IF;
                    l_nested_sql := 'SELECT ' || l_n_columns || ' FROM ' || l_n_tables || l_n_conditions;
                END;
                l_values := REPLACE(REPLACE(REPLACE(l_values_raw, '[', ''), ']', ''), '"', '');
                l_values := REPLACE(l_values, 'SUBQUERY', '(' || l_nested_sql || ')');
            ELSE
                l_values := REPLACE(REPLACE(REPLACE(l_values_raw, '[', ''), ']', ''), '"', '');
            END IF;
        END;
        l_sql := 'INSERT INTO ' || l_table || ' (' || l_columns || ') VALUES (' || l_values || ')';
        EXECUTE IMMEDIATE l_sql;
        
    ELSIF l_type = 'UPDATE' THEN
        l_set := JSON_VALUE(p_json, '$.set');
        IF JSON_EXISTS(p_json, '$.nested') THEN
            DECLARE
                l_nested_sql VARCHAR2(32767);
                l_nested_operator VARCHAR2(20);
            BEGIN
                l_nested_operator := JSON_VALUE(p_json, '$.nested_operator');
                DECLARE
                    l_n_columns VARCHAR2(4000);
                    l_n_tables  VARCHAR2(4000);
                    l_n_conditions VARCHAR2(4000) := '';
                BEGIN
                    l_n_columns := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.nested.columns'), '[', ''), ']', ''), '"', '');
                    l_n_tables  := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.nested.tables'), '[', ''), ']', ''), '"', '');
                    IF JSON_EXISTS(p_json, '$.nested.conditions') THEN
                        l_n_conditions := ' WHERE ' || JSON_VALUE(p_json, '$.nested.conditions');
                    END IF;
                    l_nested_sql := 'SELECT ' || l_n_columns || ' FROM ' || l_n_tables || l_n_conditions;
                END;
                l_conditions := ' WHERE ' || JSON_VALUE(p_json, '$.conditions') || ' ' || l_nested_operator || ' (' || l_nested_sql || ')';
            END;
        ELSIF JSON_EXISTS(p_json, '$.conditions') THEN
            l_conditions := ' WHERE ' || JSON_VALUE(p_json, '$.conditions');
        END IF;
        l_sql := 'UPDATE ' || l_table || ' SET ' || l_set || l_conditions;
        EXECUTE IMMEDIATE l_sql;
        
    ELSIF l_type = 'DELETE' THEN
        IF JSON_EXISTS(p_json, '$.nested') THEN
            DECLARE
                l_nested_sql VARCHAR2(32767);
                l_nested_operator VARCHAR2(20);
            BEGIN
                l_nested_operator := JSON_VALUE(p_json, '$.nested_operator');
                DECLARE
                    l_n_columns VARCHAR2(4000);
                    l_n_tables  VARCHAR2(4000);
                    l_n_conditions VARCHAR2(4000) := '';
                BEGIN
                    l_n_columns := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.nested.columns'), '[', ''), ']', ''), '"', '');
                    l_n_tables  := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.nested.tables'), '[', ''), ']', ''), '"', '');
                    IF JSON_EXISTS(p_json, '$.nested.conditions') THEN
                        l_n_conditions := ' WHERE ' || JSON_VALUE(p_json, '$.nested.conditions');
                    END IF;
                    l_nested_sql := 'SELECT ' || l_n_columns || ' FROM ' || l_n_tables || l_n_conditions;
                END;
                l_conditions := ' WHERE ' || JSON_VALUE(p_json, '$.conditions') || ' ' || l_nested_operator || ' (' || l_nested_sql || ')';
            END;
        ELSIF JSON_EXISTS(p_json, '$.conditions') THEN
            l_conditions := ' WHERE ' || JSON_VALUE(p_json, '$.conditions');
        END IF;
        l_sql := 'DELETE FROM ' || l_table || l_conditions;
        EXECUTE IMMEDIATE l_sql;
        
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Unsupported DML type');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('sql query: ' || l_sql);
    OPEN l_cursor FOR SELECT 'DML operation completed successfully.' AS message FROM dual;
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
END execute_dml;