-- Функция для выполнения DDL-операций (CREATE TABLE и DROP TABLE) на основе JSON
CREATE OR REPLACE FUNCTION execute_ddl(p_json CLOB) RETURN SYS_REFCURSOR IS
    v_json_obj JSON_OBJECT_T;
    v_type VARCHAR2(20);
    v_table_name VARCHAR2(100);
    v_query VARCHAR2(32767);
    v_result VARCHAR2(1000);
    v_cursor SYS_REFCURSOR;
    v_pk_column VARCHAR2(100); -- Имя первичного ключа
    v_auto_pk_trigger BOOLEAN := FALSE; -- Флаг для создания триггера первичного ключа
    v_sequence_name VARCHAR2(100); -- Имя последовательности для автогенерации PK
    v_trigger_name VARCHAR2(100); -- Имя триггера
    v_sequence_query VARCHAR2(4000); -- Запрос для создания последовательности
    v_trigger_query VARCHAR2(4000); -- Запрос для создания триггера
    
BEGIN
    -- Парсинг JSON
    v_json_obj := JSON_OBJECT_T.parse(p_json);
    
    -- Получаем тип операции и имя таблицы
    v_type := v_json_obj.get_String('type');
    v_table_name := v_json_obj.get_String('table_name');
    
    -- Проверяем наличие параметра auto_pk_trigger
    IF v_json_obj.has('auto_pk_trigger') THEN
        v_auto_pk_trigger := v_json_obj.get_Boolean('auto_pk_trigger');
    END IF;
    
    -- Проверяем тип операции
    IF v_type NOT IN ('CREATE_TABLE', 'DROP_TABLE') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Неверный тип DDL-операции. Ожидается CREATE_TABLE или DROP_TABLE.');
    END IF;
    
    -- Формируем DDL-запрос в зависимости от типа операции
    IF v_type = 'CREATE_TABLE' THEN
        -- CREATE TABLE table_name (col1 type1, col2 type2, ...)
        
        DECLARE
            v_columns_array JSON_ARRAY_T;
            v_columns_clause VARCHAR2(4000) := '(';
            v_constraints_array JSON_ARRAY_T;
            v_constraint_clause VARCHAR2(4000) := '';
            v_has_primary_key BOOLEAN := FALSE;
        BEGIN
            -- Проверяем наличие определения столбцов
            IF NOT v_json_obj.has('columns') THEN
                RAISE_APPLICATION_ERROR(-20002, 'Отсутствует определение столбцов для CREATE TABLE.');
            END IF;
            
            -- Обработка столбцов
            v_columns_array := v_json_obj.get_Array('columns');
            
            FOR i IN 0..v_columns_array.get_size - 1 LOOP
                DECLARE
                    v_column_obj JSON_OBJECT_T := v_columns_array.get_Object(i);
                    v_column_name VARCHAR2(100) := v_column_obj.get_String('name');
                    v_column_type VARCHAR2(100) := v_column_obj.get_String('type');
                    v_is_nullable BOOLEAN := TRUE;
                    v_default_value VARCHAR2(100);
                BEGIN
                    -- Добавляем разделитель между столбцами, если не первый столбец
                    IF i > 0 THEN
                        v_columns_clause := v_columns_clause || ', ';
                    END IF;
                    
                    -- Формируем определение столбца
                    v_columns_clause := v_columns_clause || v_column_name || ' ' || v_column_type;
                    
                    -- Обрабатываем NULL/NOT NULL
                    IF v_column_obj.has('nullable') THEN
                        v_is_nullable := v_column_obj.get_Boolean('nullable');
                    END IF;
                    
                    IF NOT v_is_nullable THEN
                        v_columns_clause := v_columns_clause || ' NOT NULL';
                    END IF;
                    
                    -- Обрабатываем DEFAULT, если есть
                    IF v_column_obj.has('default') THEN
                        v_default_value := v_column_obj.get_String('default');
                        
                        -- Проверяем, нужно ли заключить значение по умолчанию в кавычки
                        IF v_column_obj.get_String('type') LIKE '%CHAR%' OR 
                           v_column_obj.get_String('type') LIKE '%DATE%' OR 
                           v_column_obj.get_String('type') LIKE '%TIMESTAMP%' THEN
                            v_columns_clause := v_columns_clause || ' DEFAULT ''' || v_default_value || '''';
                        ELSE
                            v_columns_clause := v_columns_clause || ' DEFAULT ' || v_default_value;
                        END IF;
                    END IF;
                    
                    -- Проверяем наличие PRIMARY KEY на уровне столбца
                    IF v_column_obj.has('primary_key') AND v_column_obj.get_Boolean('primary_key') THEN
                        v_columns_clause := v_columns_clause || ' PRIMARY KEY';
                        v_has_primary_key := TRUE;
                        v_pk_column := v_column_name; -- Запоминаем имя колонки с PK
                    END IF;
                END;
            END LOOP;
            
            -- Обрабатываем ограничения таблицы, если они есть
            IF v_json_obj.has('constraints') THEN
                v_constraints_array := v_json_obj.get_Array('constraints');
                
                FOR i IN 0..v_constraints_array.get_size - 1 LOOP
                    DECLARE
                        v_constraint_obj JSON_OBJECT_T := v_constraints_array.get_Object(i);
                        v_constraint_type VARCHAR2(20) := v_constraint_obj.get_String('type');
                        v_constraint_name VARCHAR2(100);
                        v_columns VARCHAR2(1000);
                    BEGIN
                        -- Добавляем разделитель между ограничениями
                        IF i > 0 OR v_columns_clause != '(' THEN
                            v_columns_clause := v_columns_clause || ', ';
                        END IF;
                        
                        -- Получаем имя ограничения, если есть
                        IF v_constraint_obj.has('name') THEN
                            v_constraint_name := v_constraint_obj.get_String('name');
                            v_columns_clause := v_columns_clause || 'CONSTRAINT ' || v_constraint_name || ' ';
                        END IF;
                        
                        -- Обрабатываем тип ограничения
                        CASE v_constraint_type
                            WHEN 'PRIMARY_KEY' THEN
                                IF v_has_primary_key THEN
                                    CONTINUE; -- Пропускаем, если PK уже определен на уровне столбца
                                END IF;
                                
                                v_columns := v_constraint_obj.get_String('columns');
                                v_columns_clause := v_columns_clause || 'PRIMARY KEY (' || v_columns || ')';
                                v_has_primary_key := TRUE;
                                
                                -- Запоминаем имя первичного ключа 
                                -- Предполагаем, что это один столбец (не составной ключ)
                                IF INSTR(v_columns, ',') = 0 THEN
                                    v_pk_column := TRIM(v_columns);
                                END IF;
                                
                            WHEN 'UNIQUE' THEN
                                v_columns := v_constraint_obj.get_String('columns');
                                v_columns_clause := v_columns_clause || 'UNIQUE (' || v_columns || ')';
                                
                            WHEN 'FOREIGN_KEY' THEN
                                v_columns := v_constraint_obj.get_String('columns');
                                v_columns_clause := v_columns_clause || 'FOREIGN KEY (' || v_columns || ') ' ||
                                                   'REFERENCES ' || v_constraint_obj.get_String('references_table') ||
                                                   '(' || v_constraint_obj.get_String('references_columns') || ')';
                                
                                -- Добавляем ON DELETE, если указан
                                IF v_constraint_obj.has('on_delete') THEN
                                    v_columns_clause := v_columns_clause || ' ON DELETE ' || 
                                                       v_constraint_obj.get_String('on_delete');
                                END IF;
                                
                            WHEN 'CHECK' THEN
                                v_columns_clause := v_columns_clause || 'CHECK (' || 
                                                   v_constraint_obj.get_String('condition') || ')';
                                
                            ELSE
                                NULL; -- Игнорируем неизвестные типы ограничений
                        END CASE;
                    END;
                END LOOP;
            END IF;
            
            -- Закрываем определение столбцов и ограничений
            v_columns_clause := v_columns_clause || ')';
            
            -- Формируем полный CREATE TABLE запрос
            v_query := 'CREATE TABLE ' || v_table_name || ' ' || v_columns_clause;
            
            -- Подготовка запросов для автогенерации первичного ключа, если требуется
            IF v_auto_pk_trigger AND v_has_primary_key AND v_pk_column IS NOT NULL THEN
                -- Имена для последовательности и триггера
                v_sequence_name := 'SEQ_' || v_table_name;
                v_trigger_name := 'TRG_' || v_table_name || '_PK';
                
                -- Запрос для создания последовательности
                v_sequence_query := 'CREATE SEQUENCE ' || v_sequence_name || 
                                    ' START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
                                    
                -- Запрос для создания триггера
                v_trigger_query := 'CREATE OR REPLACE TRIGGER ' || v_trigger_name || 
                                  ' BEFORE INSERT ON ' || v_table_name || 
                                  ' FOR EACH ROW ' ||
                                  'BEGIN ' ||
                                  '  IF :NEW.' || v_pk_column || ' IS NULL THEN ' ||
                                  '    SELECT ' || v_sequence_name || '.NEXTVAL INTO :NEW.' || v_pk_column || ' FROM DUAL; ' ||
                                  '  END IF; ' ||
                                  'END;';
            END IF;
        END;
        
    ELSIF v_type = 'DROP_TABLE' THEN
        -- DROP TABLE table_name [CASCADE CONSTRAINTS]
        
        DECLARE
            v_cascade_constraints BOOLEAN := FALSE;
            v_purge BOOLEAN := FALSE;
        BEGIN
            -- Формируем базовый DROP TABLE запрос
            v_query := 'DROP TABLE ' || v_table_name;
            
            -- Добавляем CASCADE CONSTRAINTS, если указано
            IF v_json_obj.has('cascade_constraints') THEN
                v_cascade_constraints := v_json_obj.get_Boolean('cascade_constraints');
                IF v_cascade_constraints THEN
                    v_query := v_query || ' CASCADE CONSTRAINTS';
                END IF;
            END IF;
        END;
        
    END IF;
    
    -- Выводим сгенерированный запрос для отладки
    DBMS_OUTPUT.PUT_LINE('Сгенерированный DDL-запрос: ' || v_query);
    
    -- Выполняем DDL-запрос
    BEGIN
        EXECUTE IMMEDIATE v_query;
        v_result := 'DDL-операция выполнена успешно.';
        
        -- Создаем последовательность и триггер, если нужно
        IF v_type = 'CREATE_TABLE' AND v_auto_pk_trigger AND v_pk_column IS NOT NULL THEN
            -- Создаем последовательность
            DBMS_OUTPUT.PUT_LINE('Создание последовательности: ' || v_sequence_query);
            BEGIN
                EXECUTE IMMEDIATE v_sequence_query;
                v_result := v_result || ' Последовательность создана.';
            EXCEPTION
                WHEN OTHERS THEN
                    v_result := v_result || ' Ошибка при создании последовательности: ' || SQLERRM;
            END;
            
            -- Создаем триггер
            DBMS_OUTPUT.PUT_LINE('Создание триггера: ' || v_trigger_query);
            BEGIN
                EXECUTE IMMEDIATE v_trigger_query;
                v_result := v_result || ' Триггер создан.';
            EXCEPTION
                WHEN OTHERS THEN
                    v_result := v_result || ' Ошибка при создании триггера: ' || SQLERRM;
            END;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            v_result := 'Ошибка при выполнении DDL-операции: ' || SQLERRM;
            RAISE_APPLICATION_ERROR(-20003, v_result);
    END;
    
    -- Формируем запрос для возврата результатов операции
    v_query := 'SELECT ''' || v_type || ''' AS operation_type, ''' || 
               v_table_name || ''' AS table_name, ''' || 
               v_result || ''' AS result FROM dual';
    
    -- Открываем курсор с результатами и возвращаем его
    OPEN v_cursor FOR v_query;
    RETURN v_cursor;
    
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20001 OR SQLCODE = -20002 OR SQLCODE = -20003 THEN
            RAISE; -- Пробрасываем наши собственные исключения
        ELSE
            RAISE_APPLICATION_ERROR(-20004, 'Ошибка при выполнении DDL-запроса: ' || SQLERRM);
        END IF;
END execute_ddl;
/ 