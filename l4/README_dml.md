# DML-операции в JSON-ORM

## Описание

В этой части JSON-ORM добавлена поддержка DML-операций (INSERT, UPDATE, DELETE) с использованием JSON для описания структуры запроса. Функция `execute_dml` позволяет генерировать и выполнять DML-запросы на основе JSON-структуры, включая возможность использовать подзапросы в условиях WHERE и значениях SET.

## Возвращаемое значение

Функция `execute_dml` возвращает число типа NUMBER — количество строк, затронутых операцией.

## Структура JSON для DML-операций

### INSERT

```json
{
    "type": "INSERT",
    "table": "table_name",
    "columns": ["column1", "column2", ...],
    
    // Один из двух вариантов:
    // 1. Прямые значения:
    "values": [value1, value2, ...],
    
    // 2. Подзапрос:
    "select": {
        "type": "SELECT",
        "columns": ["column1", "column2", ...],
        "tables": ["table_name"],
        "where": [...]
    }
}
```

### UPDATE

```json
{
    "type": "UPDATE",
    "table": "table_name",
    "set": [
        {
            "column": "column_name",
            "value": "value"  // Или прямое значение
        },
        {
            "column": "column_name",
            "subquery": {     // Или подзапрос
                "type": "SELECT",
                "columns": ["column1"],
                "tables": ["table_name"],
                "where": [...]
            }
        }
    ],
    "where": [
        {"condition": "column1 = value1"},
        {"connector": "AND|OR", "condition": "column2 = value2"},
        // Или с подзапросом
        {
            "subquery": {
                "type": "SELECT",
                "columns": ["column1"],
                "tables": ["table_name"],
                "where": [...]
            },
            "subquery_type": "IN|NOT IN|EXISTS|NOT EXISTS",
            "field": "field_name"  // Только для IN/NOT IN
        }
    ]
}
```

### DELETE

```json
{
    "type": "DELETE",
    "table": "table_name",
    "where": [
        {"condition": "column1 = value1"},
        {"connector": "AND|OR", "condition": "column2 = value2"},
        // Или с подзапросом
        {
            "subquery": {
                "type": "SELECT",
                "columns": ["column1"],
                "tables": ["table_name"],
                "where": [...]
            },
            "subquery_type": "IN|NOT IN|EXISTS|NOT EXISTS",
            "field": "field_name"  // Только для IN/NOT IN
        }
    ]
}
```

## Примеры использования

### 1. INSERT с простыми значениями

```json
{
    "type": "INSERT",
    "table": "employees",
    "columns": ["employee_id", "first_name", "last_name", "department_id"],
    "values": [10, "Иван", "Петров", 20]
}
```

Генерируемый SQL:
```sql
INSERT INTO employees (employee_id, first_name, last_name, department_id) 
VALUES (10, 'Иван', 'Петров', 20)
```

### 2. INSERT с подзапросом

```json
{
    "type": "INSERT",
    "table": "department_stats",
    "columns": ["department_id", "employee_count", "avg_salary"],
    "select": {
        "type": "SELECT",
        "columns": ["department_id", "COUNT(*)", "AVG(salary)"],
        "tables": ["employees"],
        "where": [
            {"condition": "salary > 30000"}
        ]
    }
}
```

Генерируемый SQL:
```sql
INSERT INTO department_stats (department_id, employee_count, avg_salary)
SELECT department_id, COUNT(*), AVG(salary) FROM employees WHERE salary > 30000
```

### 3. UPDATE с простыми условиями

```json
{
    "type": "UPDATE",
    "table": "employees",
    "set": [
        {"column": "salary", "value": 50000},
        {"column": "position", "value": "Senior Developer"}
    ],
    "where": [
        {"condition": "department_id = 10"},
        {"connector": "AND", "condition": "years_of_service > 5"}
    ]
}
```

Генерируемый SQL:
```sql
UPDATE employees
SET salary = 50000, position = 'Senior Developer'
WHERE department_id = 10 AND years_of_service > 5
```

### 4. UPDATE с подзапросом в WHERE

```json
{
    "type": "UPDATE",
    "table": "employees",
    "set": [
        {"column": "bonus", "value": 5000}
    ],
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

Генерируемый SQL:
```sql
UPDATE employees
SET bonus = 5000
WHERE department_id IN (SELECT department_id FROM departments WHERE department_name = 'IT')
```

### 5. DELETE с подзапросом

```json
{
    "type": "DELETE",
    "table": "employees",
    "where": [
        {
            "subquery": {
                "type": "SELECT",
                "columns": ["1"],
                "tables": ["performance_reviews p"],
                "where": [
                    {"condition": "p.employee_id = employees.employee_id"},
                    {"connector": "AND", "condition": "p.rating < 3"}
                ]
            },
            "subquery_type": "EXISTS"
        }
    ]
}
```

Генерируемый SQL:
```sql
DELETE FROM employees
WHERE EXISTS (
    SELECT 1 FROM performance_reviews p 
    WHERE p.employee_id = employees.employee_id AND p.rating < 3
)
```

## Обработка ошибок

Если во время выполнения DML-операции возникает ошибка, функция генерирует исключение с:
- Кодом -20001 для неверного типа операции
- Кодом -20002 для ошибок выполнения запроса

Сообщение об ошибке включает текст оригинальной ошибки и сгенерированный SQL-запрос.

## Файлы в проекте

- **orm_dml.sql** - Функция для выполнения DML-операций на основе JSON
- **test_dml.sql** - Тестовый скрипт с примерами использования DML-операций 