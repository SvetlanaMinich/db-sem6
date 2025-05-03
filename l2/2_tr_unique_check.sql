CREATE SEQUENCE groups_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE students_seq START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER groups_create_unique_id
BEFORE INSERT ON GROUPS
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    IF :NEW.ID IS NULL THEN
        :NEW.ID := groups_seq.NEXTVAL;
    ELSE
        SELECT COUNT(*) INTO id_count 
        FROM GROUPS 
        WHERE ID = :NEW.ID;
            
        IF id_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Group ID must be unique.');
        END IF;
    END IF;
END;


CREATE OR REPLACE TRIGGER students_create_unique_id
BEFORE INSERT ON STUDENTS
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    IF :NEW.ID IS NULL THEN
        :NEW.ID := students_seq.NEXTVAL;
    ELSE
        SELECT COUNT(*) INTO id_count 
        FROM STUDENTS 
        WHERE ID = :NEW.ID;
            
        IF id_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Student ID must be unique.');
        END IF;
    END IF;
END;


CREATE OR REPLACE TRIGGER groups_check_unique_name
BEFORE INSERT ON GROUPS
FOR EACH ROW
DECLARE
    name_count NUMBER;
BEGIN
    IF :NEW.NAME IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Groups NAME must NOT be empty');
    END IF;

    SELECT COUNT(*) INTO name_count 
    FROM GROUPS 
    WHERE NAME = :NEW.NAME;
            
    IF name_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Groups NAME must be unique');
    END IF;
END;


-- GROUPS TEST
-- TEST AUTO INCREMENT
BEGIN
    INSERT INTO GROUPS (NAME, C_VAL) VALUES ('GROUP 1', 0);
    INSERT INTO GROUPS (NAME, C_VAL) VALUES ('GROUP 2', 0);
    FOR rec IN (SELECT ID, NAME, C_VAL FROM GROUPS) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.ID || ', NAME: ' || rec.NAME || ', C_VAL: ' || rec.C_VAL);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Тест: Вставка без явного указания ID прошла успешно!');
    DELETE FROM GROUPS;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Тест: Ошибка - ' || SQLERRM);
        DELETE FROM GROUPS;
END;


-- TEST WITH DEFINED UNIQUE ID
BEGIN
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (1, 'GROUP 1', 0);

    FOR rec IN (SELECT ID, NAME, C_VAL FROM GROUPS) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.ID || ', NAME: ' || rec.NAME || ', C_VAL: ' || rec.C_VAL);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Тест: Вставка с явным указанием ID прошла успешно!');
    DELETE FROM GROUPS;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Тест: Ошибка - ' || SQLERRM);
        DELETE FROM GROUPS;
END;

-- TEST WITH DEFINED EXISTING ID
BEGIN
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (1, 'GROUP 1', 0);
    SELECT * FROM GROUPS;
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (1, 'GROUP 2', 0);
    DBMS_OUTPUT.PUT_LINE('Тест: Вставка с явным указанием ID прошла успешно!');
    DELETE FROM GROUPS;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Тест: Ошибка - ' || SQLERRM);
        DELETE FROM GROUPS;
END;


-- TEST WITH EXISTING NAME
BEGIN
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (1, 'GROUP 1', 0);
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (2, 'GROUP 1', 0);
    DBMS_OUTPUT.PUT_LINE('Тест: Вставка с явным указанием ID прошла успешно!');
    DELETE FROM GROUPS;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Тест: Ошибка - ' || SQLERRM);
        DELETE FROM GROUPS;
END;

SELECT * FROM GROUPS;
DELETE FROM GROUPS;