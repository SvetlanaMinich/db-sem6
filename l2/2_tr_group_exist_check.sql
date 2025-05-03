CREATE OR REPLACE TRIGGER groups_existence_check_when_insert_student
BEFORE INSERT ON STUDENTS
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    IF :NEW.GROUPS_ID IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Groups ID must NOT be empty');
    END IF;

    SELECT COUNT(*) INTO id_count
    FROM GROUPS
    WHERE ID = :NEW.GROUPS_ID;

    IF id_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Group with this ID does not exist');
    END IF;
END;


-- TEST WITHOUT ERRORS 
BEGIN
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (101, 'Group 1', 0);
    INSERT INTO STUDENTS (NAME, GROUPS_ID) VALUES ('Student 1', 101);
    DBMS_OUTPUT.PUT_LINE('Тест 1: Успешно! Студент добавлен с группой ID=101');
    
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Тест 1: Ошибка - ' || SQLERRM);
        ROLLBACK;
END;


-- TEST WITH NON EXISTING GROUP
BEGIN
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (101, 'Group 1', 0);
    INSERT INTO STUDENTS (NAME, GROUPS_ID) VALUES ('Student 1', 102);
    DBMS_OUTPUT.PUT_LINE('Тест 1: Успешно! Студент добавлен с группой ID=102');
    
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Тест 1: Ошибка - ' || SQLERRM);
        ROLLBACK;
END;

SELECT * FROM STUDENTS;
