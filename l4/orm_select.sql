CREATE OR REPLACE FUNCTION execute_select(p_json CLOB) RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
    v_query VARCHAR2(32767);
    
    -- JSON-объекты для парсинга
    v_json_obj JSON_OBJECT_T;
    v_columns_array JSON_ARRAY_T;
    v_tables_array JSON_ARRAY_T;
    v_joins_array JSON_ARRAY_T;
    v_where_array JSON_ARRAY_T;
    
    -- Переменные для формирования запроса
    v_select_clause VARCHAR2(4000) := 'SELECT ';
    v_from_clause VARCHAR2(4000) := ' FROM ';
    v_join_clause VARCHAR2(4000) := ' ';
    v_where_clause VARCHAR2(4000) := ' ';
    
    -- Вспомогательные функции
    
    -- Функция для обработки вложенного подзапроса
    FUNCTION process_subquery(p_subquery_json JSON_OBJECT_T) RETURN VARCHAR2 IS
        v_subquery_type VARCHAR2(20);
        v_field VARCHAR2(100);
        v_operator VARCHAR2(20);
        v_nested_json CLOB;
        v_result VARCHAR2(4000);
        v_nested_cursor SYS_REFCURSOR;
        
        -- Получаем внутренний JSON для подзапроса
        v_nested_json_obj JSON_OBJECT_T;
    BEGIN
        -- Получаем параметры подзапроса
        v_subquery_type := p_subquery_json.get_String('subquery_type');
        v_field := p_subquery_json.get_String('field');
        
        -- Получаем JSON для вложенного запроса
        v_nested_json := p_subquery_json.get_Object('subquery').to_Clob();
        
        -- Формируем часть запроса в зависимости от типа подзапроса
        IF v_subquery_type IN ('IN', 'NOT IN') THEN
            v_result := v_field || ' ' || v_subquery_type || ' (';
            -- Добавляем вложенный подзапрос - упрощенный вариант
            v_result := v_result || 'SELECT * FROM TABLE(execute_select_to_table(' || 
                        DBMS_ASSERT.ENQUOTE_LITERAL(v_nested_json) || '))';
            v_result := v_result || ')';
            
        ELSIF v_subquery_type IN ('EXISTS', 'NOT EXISTS') THEN
            v_result := v_subquery_type || ' (';
            -- Добавляем вложенный подзапрос - упрощенный вариант
            v_result := v_result || 'SELECT * FROM TABLE(execute_select_to_table(' || 
                        DBMS_ASSERT.ENQUOTE_LITERAL(v_nested_json) || '))';
            
            v_result := v_result || ')';
        END IF;
        
        RETURN v_result;
    END process_subquery;
    
BEGIN
    -- Парсинг JSON
    v_json_obj := JSON_OBJECT_T.parse(p_json);
    
    -- Проверка типа запроса
    IF v_json_obj.get_String('type') != 'SELECT' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Неверный тип запроса. Ожидается SELECT.');
    END IF;
    
    -- Извлечение массивов из JSON
    v_columns_array := v_json_obj.get_Array('columns');
    v_tables_array := v_json_obj.get_Array('tables');
    
    -- Обработка столбцов (SELECT clause)
    FOR i IN 0..v_columns_array.get_size - 1 LOOP
        IF i > 0 THEN
            v_select_clause := v_select_clause || ', ';
        END IF;
        v_select_clause := v_select_clause || v_columns_array.get_String(i);
    END LOOP;
    
    -- Обработка таблиц (FROM clause)
    FOR i IN 0..v_tables_array.get_size - 1 LOOP
        IF i > 0 THEN
            v_from_clause := v_from_clause || ', ';
        END IF;
        v_from_clause := v_from_clause || v_tables_array.get_String(i);
    END LOOP;
    
    -- Обработка JOIN условий, если есть
    IF v_json_obj.has('joins') THEN
        v_joins_array := v_json_obj.get_Array('joins');
        
        FOR i IN 0..v_joins_array.get_size - 1 LOOP
            DECLARE
                v_join_obj JSON_OBJECT_T := v_joins_array.get_Object(i);
                v_join_type VARCHAR2(20) := NVL(v_join_obj.get_String('type'), 'INNER JOIN');
                v_table VARCHAR2(100) := v_join_obj.get_String('table');
                v_condition VARCHAR2(1000) := v_join_obj.get_String('condition');
            BEGIN
                v_join_clause := v_join_clause || v_join_type || ' ' || v_table || ' ON ' || v_condition || ' ';
            END;
        END LOOP;
    END IF;
    
    -- Обработка WHERE условий, если есть
    IF v_json_obj.has('where') THEN
        v_where_array := v_json_obj.get_Array('where');
        IF v_where_array.get_size > 0 THEN
            v_where_clause := ' WHERE ';
            
            FOR i IN 0..v_where_array.get_size - 1 LOOP
                DECLARE
                    v_where_obj JSON_OBJECT_T := v_where_array.get_Object(i);
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
        END IF;
    END IF;
    
    -- Формирование полного SQL-запроса
    v_query := v_select_clause || v_from_clause || v_join_clause || v_where_clause;
    
    DBMS_OUTPUT.PUT_LINE('Сгенерированный запрос: ' || v_query);
    
    -- Выполнение запроса и возврат курсора
    OPEN v_cursor FOR v_query;
    RETURN v_cursor;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ошибка при выполнении запроса: ' || SQLERRM || 
                                ' Сгенерированный запрос: ' || v_query);
END execute_select;
/

-- Вспомогательная функция для преобразования результатов запроса в таблицу
-- Это необходимо для вложенных запросов (отдельная функция для рекурсии)
CREATE OR REPLACE FUNCTION execute_select_to_table(p_json CLOB) 
RETURN SYS.ODCIVARCHAR2LIST PIPELINED IS
    v_cursor SYS_REFCURSOR;
    v_value VARCHAR2(4000);
BEGIN
    -- Используем execute_select для получения курсора
    v_cursor := execute_select(p_json);
    
    -- Извлекаем результаты и передаем в конвейер
    LOOP
        FETCH v_cursor INTO v_value;
        EXIT WHEN v_cursor%NOTFOUND;
        PIPE ROW(v_value);
    END LOOP;
    
    CLOSE v_cursor;
    RETURN;
EXCEPTION
    WHEN OTHERS THEN
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
        RAISE;
END execute_select_to_table;
/ 