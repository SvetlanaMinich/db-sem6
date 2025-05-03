# Вложенные запросы в JSON-ORM

## Описание

В этой версии JSON-ORM добавлена поддержка вложенных запросов (подзапросов) как часть условий фильтрации. Теперь можно использовать операторы IN, NOT IN, EXISTS и NOT EXISTS с вложенными запросами.

## Структура JSON для вложенных запросов

Для использования вложенного запроса в условии WHERE, используйте следующую структуру:

```json
{
    "type": "SELECT",
    "columns": ["column1", "column2", ...],
    "tables": ["table1", "table2 alias", ...],
    "where": [
        {
            "subquery": {
                "type": "SELECT",
                "columns": ["column1"],
                "tables": ["table1"],
                "where": [
                    {"condition": "condition1"}
                ]
            },
            "subquery_type": "IN | NOT IN | EXISTS | NOT EXISTS",
            "field": "field_name"  // Только для IN и NOT IN
        }
    ]
}
```

### Описание полей для вложенных запросов

- **subquery**: Объект, содержащий вложенный SELECT-запрос
- **subquery_type**: Тип оператора для вложенного запроса (IN, NOT IN, EXISTS, NOT EXISTS)
- **field**: Поле, к которому применяется оператор IN или NOT IN (не используется для EXISTS/NOT EXISTS)
- **correlation**: Условие корреляции для EXISTS/NOT EXISTS (опционально)

## Примеры использования

### Пример IN

```json
{
    "type": "SELECT",
    "columns": ["employee_id", "first_name", "last_name"],
    "tables": ["employees"],
    "where": [
        {
            "subquery": {
                "type": "SELECT",
                "columns": ["department_id"],
                "tables": ["departments"],
                "where": [
                    {"condition": "department_name = 'IT'"}
                ]
            },
            "subquery_type": "IN",
            "field": "department_id"
        }
    ]
}
```

Это сгенерирует SQL:
```sql
SELECT employee_id, first_name, last_name 
FROM employees 
WHERE department_id IN (
    SELECT department_id FROM departments WHERE department_name = 'IT'
)
```

### Пример EXISTS

```json
{
    "type": "SELECT",
    "columns": ["d.department_id", "d.department_name"],
    "tables": ["departments d"],
    "where": [
        {
            "subquery": {
                "type": "SELECT",
                "columns": ["1"],
                "tables": ["employees e"],
                "where": [
                    {"condition": "e.department_id = d.department_id"},
                    {"connector": "AND", "condition": "e.salary > 50000"}
                ]
            },
            "subquery_type": "EXISTS"
        }
    ]
}
```

Это сгенерирует SQL:
```sql
SELECT d.department_id, d.department_name 
FROM departments d 
WHERE EXISTS (
    SELECT 1 FROM employees e 
    WHERE e.department_id = d.department_id AND e.salary > 50000
)
```

## Ограничения и особенности

1. Вложенные запросы можно использовать только в условиях WHERE
2. Поддерживаются операторы IN, NOT IN, EXISTS и NOT EXISTS
3. Для IN и NOT IN обязательно указывать поле в параметре "field"
4. Для EXISTS и NOT EXISTS можно использовать "correlation" для связи с внешним запросом

## Как это работает

1. Функция `execute_select` определяет, является ли условие WHERE вложенным запросом
2. Если да, вызывается вспомогательная функция `process_subquery` для обработки вложенного запроса
3. Вложенный запрос преобразуется в SQL с использованием вспомогательной функции `execute_select_to_table`
4. Генерируется полный SQL-запрос с подзапросом

## Файлы в проекте

- **orm_select.sql** - Основная функция с поддержкой вложенных запросов
- **test_subqueries.sql** - Примеры использования вложенных запросов 