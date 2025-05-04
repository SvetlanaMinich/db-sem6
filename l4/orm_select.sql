CREATE OR REPLACE FUNCTION execute_select(p_json IN CLOB)
RETURN SYS_REFCURSOR
AS
    l_cursor        SYS_REFCURSOR;
    l_sql           VARCHAR2(32767);
    l_columns       VARCHAR2(4000);
    l_tables        VARCHAR2(4000);
    l_joins         VARCHAR2(4000) := '';
    l_conditions    VARCHAR2(4000) := '';
    l_group_by      VARCHAR2(4000) := '';
    l_having        VARCHAR2(4000) := '';
    l_order_by      VARCHAR2(4000) := '';
    l_union_sql     VARCHAR2(32767) := '';
    
    -- Для подсчёта элементов массивов
    l_joins_length      INTEGER := 0;
    l_union_length      INTEGER := 0;
BEGIN
    l_columns := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.columns'), '[', ''), ']', ''), '"', '');
    l_tables  := REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.tables'), '[', ''), ']', ''), '"', '');
    
    IF JSON_EXISTS(p_json, '$.joins') THEN
        LOOP
            EXIT WHEN JSON_VALUE(p_json, '$.joins[' || l_joins_length || '].type') IS NULL;
            l_joins_length := l_joins_length + 1;
        END LOOP;

        FOR i IN 0..l_joins_length-1 LOOP
            l_joins := l_joins || ' ' ||
                JSON_VALUE(p_json, '$.joins[' || i || '].type') || ' JOIN ' ||
                JSON_VALUE(p_json, '$.joins[' || i || '].table') ||
                ' ON ' || JSON_VALUE(p_json, '$.joins[' || i || '].on') || ' ';
        END LOOP;
    END IF;

    IF JSON_EXISTS(p_json, '$.nested') THEN
        DECLARE
            l_nested_sql VARCHAR2(32767);
            l_nested_operator VARCHAR2(20);
            l_outer_column VARCHAR2(100);
        BEGIN
            -- В outer запросе поле, к которому применяется вложенный запрос
            l_outer_column := JSON_VALUE(p_json, '$.conditions');
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
            l_conditions := ' WHERE ' || l_outer_column || ' ' || l_nested_operator || ' (' || l_nested_sql || ')';
        END;
    ELSIF JSON_EXISTS(p_json, '$.conditions') THEN
        l_conditions := ' WHERE ' || JSON_VALUE(p_json, '$.conditions');
    END IF;

    IF JSON_EXISTS(p_json, '$.group_by') THEN
        l_group_by := ' GROUP BY ' || REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.group_by'), '[', ''), ']', ''), '"', '');
    END IF;

    IF JSON_EXISTS(p_json, '$.having') THEN
        l_having := ' HAVING ' || JSON_VALUE(p_json, '$.having');
    END IF;

    IF JSON_EXISTS(p_json, '$.order_by') THEN
        l_order_by := ' ORDER BY ' || REPLACE(REPLACE(REPLACE(JSON_QUERY(p_json, '$.order_by'), '[', ''), ']', ''), '"', '');
    END IF;

    l_sql := 'SELECT ' || l_columns || ' FROM ' || l_tables || l_joins || l_conditions || l_group_by || l_having || l_order_by;

    DBMS_OUTPUT.PUT_LINE('Generated SQL: ' || l_sql);

    OPEN l_cursor FOR l_sql;
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
END execute_select;
/