CREATE SEQUENCE mytable_seq1
    START WITH 1
    INCREMENT BY 1;

CREATE SEQUENCE mytable_seq
    START WITH 10001
    INCREMENT BY 1;

CREATE OR REPLACE PROCEDURE insert_record(p_val NUMBER) IS
BEGIN
    INSERT INTO MyTable (id, val) VALUES (mytable_seq.NEXTVAL, p_val);
    COMMIT;
END;

CREATE OR REPLACE PROCEDURE update_record(p_id NUMBER, p_new_val NUMBER) IS
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

    UPDATE MyTable SET val = p_new_val WHERE id = p_id;
    COMMIT;
END;

CREATE OR REPLACE PROCEDURE delete_record(p_id NUMBER) IS
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

    DELETE FROM MyTable WHERE id = p_id;
    COMMIT;
END;