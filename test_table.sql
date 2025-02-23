SELECT * FROM MyTable;
SELECT check_even_odd_ratio FROM dual;
SELECT generate_insert_query(20000) FROM dual;

BEGIN
    insert_record(500);
END;

BEGIN
    update_record(10001, 700);
END;

BEGIN
    delete_record(10001);
END;

SELECT calculate_annual_salary(6000, 15) FROM dual;

DROP TABLE MyTable;

