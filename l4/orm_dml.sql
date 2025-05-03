-- Функция для выполнения DML-операций (INSERT, UPDATE, DELETE) на основе JSON
CREATE OR REPLACE FUNCTION execute_dml(p_json CLOB) RETURN SYS_REFCURSOR IS
    v_json_obj JSON_OBJECT_T;
    v_type VARCHAR2(20);
    v_table VARCHAR2(100);
    v_query VARCHAR2(32767);
    v_dml_query VARCHAR2(32767);
    v_rows_affected NUMBER := 0;
    v_cursor SYS_REFCURSOR;
    
    -- Функция для обработки подзапроса (повторно используем из execute_select)
    FUNCTION process_subquery(p_subquery_json JSON_OBJECT_T) RETURN VARCHAR2 IS
        v_subquery_type VARCHAR2(20);
        v_field VARCHAR2(100);
        v_nested_json CLOB;
        v_result VARCHAR2(4000);
    BEGIN
        v_subquery_type := p_subquery_json.get_String('subquery_type');
        v_field := p_subquery_json.get_String('field');
        v_nested_json := p_subquery_json.get_Object('subquery').to_Clob();
        
        IF v_subquery_type IN ('IN', 'NOT IN') THEN
            v_result := v_field || ' ' || v_subquery_type || ' (';
            v_result := v_result || 'SELECT * FROM TABLE(execute_select_to_table(' || 
                        DBMS_ASSERT.ENQUOTE_LITERAL(v_nested_json) || '))';
            v_result := v_result || ')';
        ELSIF v_subquery_type IN ('EXISTS', 'NOT EXISTS') THEN
            v_result := v_subquery_type || ' (';
            v_result := v_result || 'SELECT * FROM TABLE(execute_select_to_table(' || 
                        DBMS_ASSERT.ENQUOTE_LITERAL(v_nested_json) || '))';
            v_result := v_result || ')';
        END IF;
        
        RETURN v_result;
    END process_subquery;
    
    -- Функция для обработки условий WHERE
    FUNCTION process_where(p_where_array JSON_ARRAY_T) RETURN VARCHAR2 IS
        v_where_clause VARCHAR2(4000) := ' WHERE ';
    BEGIN
        FOR i IN 0..p_where_array.get_size - 1 LOOP
            DECLARE
                v_where_obj JSON_OBJECT_T := p_where_array.get_Object(i);
                v_condition VARCHAR2(4000);
                v_connector VARCHAR2(10) := NVL(v_where_obj.get_String('connector'), '');
                v_is_subquery BOOLEAN := FALSE;
            BEGIN
                -- Проверяем, является ли условие подзапросом
                IF v_where_obj.has('subquery') THEN
                    v_is_subquery := TRUE;
                    v_condition := process_subquery(v_where_obj);
                ELSE
                    v_condition := v_where_obj.get_String('condition');
                END IF;
                
                -- Добавляем соединитель для условий (AND, OR)
                IF i > 0 AND v_connector IS NOT NULL THEN
                    v_where_clause := v_where_clause || ' ' || v_connector || ' ';
                END IF;
                
                v_where_clause := v_where_clause || v_condition;
            END;
        END LOOP;
        
        RETURN v_where_clause;
    END process_where;
    
BEGIN
    -- Парсинг JSON
    v_json_obj := JSON_OBJECT_T.parse(p_json);
    
    -- Получаем тип операции
    v_type := v_json_obj.get_String('type');
    v_table := v_json_obj.get_String('table');
    
    -- Формируем и выполняем DML-запрос в зависимости от типа
    IF v_type = 'INSERT' THEN
        -- INSERT может быть двух видов:
        -- 1. Со значениями: INSERT INTO table (col1, col2) VALUES (val1, val2)
        -- 2. С подзапросом: INSERT INTO table (col1, col2) SELECT col1, col2 FROM ...
        
        DECLARE
            v_columns_array JSON_ARRAY_T;
            v_columns_clause VARCHAR2(4000) := '(';
            v_has_values BOOLEAN := v_json_obj.has('values');
            v_has_select BOOLEAN := v_json_obj.has('select');
            v_values_clause VARCHAR2(4000);
            v_select_json CLOB;
        BEGIN
            -- Обработка колонок
            v_columns_array := v_json_obj.get_Array('columns');
            
            FOR i IN 0..v_columns_array.get_size - 1 LOOP
                IF i > 0 THEN
                    v_columns_clause := v_columns_clause || ', ';
                END IF;
                v_columns_clause := v_columns_clause || v_columns_array.get_String(i);
            END LOOP;
            
            v_columns_clause := v_columns_clause || ')';
            
            -- Начинаем формировать запрос
            v_dml_query := 'INSERT INTO ' || v_table || ' ' || v_columns_clause;
            
            IF v_has_values THEN
                -- INSERT с конкретными значениями
                DECLARE
                    v_values_array JSON_ARRAY_T := v_json_obj.get_Array('values');
                BEGIN
                    v_values_clause := ' VALUES (';
                    
                    FOR i IN 0..v_values_array.get_size - 1 LOOP
                        IF i > 0 THEN
                            v_values_clause := v_values_clause || ', ';
                        END IF;
                        
                        -- Проверяем тип значения и добавляем кавычки для строк если нужно
                        IF v_values_array.get_Type(i) = 'STRING' THEN
                            v_values_clause := v_values_clause || '''' || REPLACE(v_values_array.get_String(i), '''', '''''') || '''';
                        ELSE
                            v_values_clause := v_values_clause || v_values_array.get_String(i);
                        END IF;
                    END LOOP;
                    
                    v_values_clause := v_values_clause || ')';
                    v_dml_query := v_dml_query || v_values_clause;
                END;
            ELSIF v_has_select THEN
                -- INSERT с подзапросом SELECT
                v_select_json := v_json_obj.get_Object('select').to_Clob();
                v_dml_query := v_dml_query || ' SELECT * FROM TABLE(execute_select_to_table(' || 
                          DBMS_ASSERT.ENQUOTE_LITERAL(v_select_json) || '))';
            END IF;
        END;
        
    ELSIF v_type = 'UPDATE' THEN
        -- UPDATE table SET col1 = val1, col2 = val2 WHERE ...
        
        DECLARE
            v_set_array JSON_ARRAY_T;
            v_set_clause VARCHAR2(4000) := ' SET ';
            v_where_array JSON_ARRAY_T;
            v_where_clause VARCHAR2(4000);
        BEGIN
            -- Обработка SET выражений
            v_set_array := v_json_obj.get_Array('set');
            
            FOR i IN 0..v_set_array.get_size - 1 LOOP
                DECLARE
                    v_set_obj JSON_OBJECT_T := v_set_array.get_Object(i);
                    v_column VARCHAR2(100) := v_set_obj.get_String('column');
                    v_value VARCHAR2(4000);
                BEGIN
                    IF i > 0 THEN
                        v_set_clause := v_set_clause || ', ';
                    END IF;
                    
                    -- Проверяем, является ли значение подзапросом
                    IF v_set_obj.has('subquery') THEN
                        v_value := '(' || 'SELECT * FROM TABLE(execute_select_to_table(' || 
                                 DBMS_ASSERT.ENQUOTE_LITERAL(v_set_obj.get_Object('subquery').to_Clob()) || '))' || ')';
                    ELSE
                        -- Проверяем тип значения
                        IF v_set_obj.get_Type('value') = 'STRING' THEN
                            v_value := '''' || REPLACE(v_set_obj.get_String('value'), '''', '''''') || '''';
                        ELSE
                            v_value := v_set_obj.get_String('value');
                        END IF;
                    END IF;
                    
                    v_set_clause := v_set_clause || v_column || ' = ' || v_value;
                END;
            END LOOP;
            
            -- Начинаем формировать запрос
            v_dml_query := 'UPDATE ' || v_table || v_set_clause;
            
            -- Обработка WHERE условий
            IF v_json_obj.has('where') THEN
                v_where_array := v_json_obj.get_Array('where');
                v_where_clause := process_where(v_where_array);
                v_dml_query := v_dml_query || v_where_clause;
            END IF;
        END;
        
    ELSIF v_type = 'DELETE' THEN
        -- DELETE FROM table WHERE ...
        
        DECLARE
            v_where_array JSON_ARRAY_T;
            v_where_clause VARCHAR2(4000);
        BEGIN
            -- Начинаем формировать запрос
            v_dml_query := 'DELETE FROM ' || v_table;
            
            -- Обработка WHERE условий
            IF v_json_obj.has('where') THEN
                v_where_array := v_json_obj.get_Array('where');
                v_where_clause := process_where(v_where_array);
                v_dml_query := v_dml_query || v_where_clause;
            END IF;
        END;
        
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Неверный тип DML-операции. Ожидается INSERT, UPDATE или DELETE.');
    END IF;
    
    -- Выводим сгенерированный запрос для отладки
    DBMS_OUTPUT.PUT_LINE('Сгенерированный DML-запрос: ' || v_dml_query);
    
    -- Выполняем DML-запрос
    EXECUTE IMMEDIATE v_dml_query;
    v_rows_affected := SQL%ROWCOUNT;
    
    -- Формируем запрос для возврата результатов операции
    v_query := 'SELECT ''' || v_type || ''' AS operation_type, ''' || 
               v_table || ''' AS table_name, ' || v_rows_affected || 
               ' AS rows_affected FROM dual';
    
    -- Открываем курсор с результатами и возвращаем его
    OPEN v_cursor FOR v_query;
    RETURN v_cursor;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ошибка при выполнении DML-запроса: ' || SQLERRM || 
                               ' Сгенерированный запрос: ' || v_dml_query);
END execute_dml;
/ 