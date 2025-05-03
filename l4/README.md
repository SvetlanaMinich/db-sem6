# JSON-ORM для Oracle PL/SQL

## Описание

Это простой ORM-механизм для Oracle PL/SQL, который позволяет формировать и выполнять SQL-запросы на основе JSON-структуры. Вместо написания сложных SQL-запросов, вы можете передать JSON с параметрами запроса, и механизм автоматически сгенерирует и выполнит соответствующий SQL-запрос.

## Возможности

На данный момент реализован механизм для выполнения SELECT-запросов с возможностями:
- Выбор столбцов
- Указание таблиц
- Условия JOIN (включая разные типы: INNER JOIN, LEFT JOIN и т.д.)
- Условия фильтрации (WHERE) с возможностью комбинирования через AND/OR

## Структура JSON для SELECT-запроса

```json
{
    "type": "SELECT",
    "columns": ["column1", "column2", ...],
    "tables": ["table1", "table2 alias", ...],
    "joins": [
        {
            "type": "INNER JOIN",
            "table": "table_name alias",
            "condition": "join_condition"
        },
        ...
    ],
    "where": [
        {
            "condition": "condition1"
        },
        {
            "connector": "AND|OR",
            "condition": "condition2"
        },
        ...
    ]
}
```

### Описание полей

- **type**: Тип запроса (обязательно должен быть "SELECT")
- **columns**: Массив имен столбцов для выборки
- **tables**: Массив имен таблиц (можно использовать алиасы)
- **joins**: Массив объектов с информацией о JOIN-ах (опционально)
  - **type**: Тип JOIN (INNER JOIN, LEFT JOIN, RIGHT JOIN и т.д.)
  - **table**: Имя присоединяемой таблицы (можно с алиасом)
  - **condition**: Условие соединения (ON-часть)
- **where**: Массив объектов с условиями фильтрации (опционально)
  - **condition**: Условие фильтрации
  - **connector**: Логический оператор соединения с предыдущим условием (AND/OR)

## Пример использования

```sql
DECLARE
    v_json CLOB;
    v_cursor SYS_REFCURSOR;
    -- Переменные для получения результатов
    v_col1 VARCHAR2(100);
    v_col2 NUMBER;
BEGIN
    -- Формирование JSON для запроса
    v_json := '{
        "type": "SELECT",
        "columns": ["employee_id", "first_name", "last_name"],
        "tables": ["employees e"],
        "joins": [
            {
                "type": "INNER JOIN",
                "table": "departments d",
                "condition": "e.department_id = d.department_id"
            }
        ],
        "where": [
            {"condition": "e.salary > 5000"},
            {"connector": "AND", "condition": "d.department_name = ''IT''"}
        ]
    }';
    
    -- Выполнение запроса
    v_cursor := json_orm.execute_select(v_json);
    
    -- Обработка результатов
    LOOP
        FETCH v_cursor INTO v_employee_id, v_first_name, v_last_name;
        EXIT WHEN v_cursor%NOTFOUND;
        -- Обработка полученных данных
        DBMS_OUTPUT.PUT_LINE(v_employee_id || ' ' || v_first_name || ' ' || v_last_name);
    END LOOP;
    
    CLOSE v_cursor;
END;
/
```

## Файлы в проекте

- **orm_select.sql** - Основной пакет с реализацией ORM-механизма для SELECT-запросов
- **test_json_orm.sql** - Скрипт с примерами использования и тестовыми данными

## Установка и использование

1. Выполните скрипт `orm_select.sql` для создания пакета `json_orm`
2. Используйте функцию `json_orm.execute_select()`, передавая ей JSON-строку с параметрами запроса
3. Полученный курсор можно использовать для получения и обработки результатов запроса

## Дальнейшее развитие

Планируемые улучшения:
- Поддержка вложенных запросов в условиях WHERE (IN, EXISTS и т.д.)
- Поддержка GROUP BY, ORDER BY и HAVING
- Реализация DML-операций (INSERT, UPDATE, DELETE)
- Реализация DDL-операций (CREATE TABLE, DROP TABLE)
- Автоматическая генерация триггеров для первичных ключей 



docker run -d --name labs -p 1521:1521 -p 5500:5500 -e ORACLE_PWD=oracle container-registry.oracle.com/database/express:latest