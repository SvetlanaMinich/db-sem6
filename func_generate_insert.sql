CREATE OR REPLACE FUNCTION generate_insert_query(p_id NUMBER) RETURN VARCHAR2 IS
    v_val NUMBER;
    v_query VARCHAR2(4000);
    v_count NUMBER;
BEGIN
    IF p_id <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: p_id must be a positive number greater than zero.');
    END IF;

    SELECT COUNT(*) INTO v_count 
    FROM MyTable 
    WHERE id = p_id;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: Record with id ' || p_id || ' does not exist.');
    END IF;

    SELECT val INTO v_val FROM MyTable WHERE id = p_id;
    
    v_query := 'INSERT INTO MyTable (id, val) VALUES (' || p_id || ', ' || v_val || ');';
    
    RETURN v_query;
END;