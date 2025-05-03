CREATE OR REPLACE TRIGGER cascade_students_deletion_by_id_of_deleting_group
FOR DELETE ON GROUPS
COMPOUND TRIGGER
    TYPE group_id_table IS TABLE OF GROUPS.ID%TYPE;
    deleted_group_ids group_id_table := group_id_table();

    AFTER EACH ROW IS
    BEGIN
        deleted_group_ids.extend(1);
        deleted_group_ids(deleted_group_ids.count) := :OLD.ID;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FOR i IN 1 .. deleted_group_ids.count LOOP
            DELETE FROM STUDENTS WHERE GROUPS_ID = deleted_group_ids(i);
        END LOOP;
    END AFTER STATEMENT;
END;

DELETE FROM GROUPS WHERE ID = 101;

-- TEST
BEGIN
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (200, 'GROUP A', 0);
    INSERT INTO STUDENTS (NAME, GROUPS_ID) VALUES ('ST 1', 200);
    INSERT INTO STUDENTS (NAME, GROUPS_ID) VALUES ('ST 2', 200);

    DBMS_OUTPUT.PUT_LINE('----- Группы перед удалением: ');
    FOR rec IN (SELECT ID, NAME, C_VAL FROM GROUPS) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.ID || ', NAME: ' || rec.NAME);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----- Студенты перед удалением группы: ');
    FOR rec IN (SELECT ID, NAME, GROUPS_ID FROM STUDENTS) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.ID || ', NAME: ' || rec.NAME || ', GROUPS_ID: ' || rec.GROUPS_ID);
    END LOOP;

    DELETE FROM GROUPS WHERE ID = 200;
    DBMS_OUTPUT.PUT_LINE('----- Группы после удаления: ');
    FOR rec IN (SELECT ID, NAME, C_VAL FROM GROUPS) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.ID || ', NAME: ' || rec.NAME);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('----- Студенты после удаления группы: ');
    FOR rec IN (SELECT ID, NAME, GROUPS_ID FROM STUDENTS) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.ID || ', NAME: ' || rec.NAME || ', GROUPS_ID: ' || rec.GROUPS_ID);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Тест: Студенты каскадно удалились вместе с принадлежащей группой.');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Тест: Ошибка - ' || SQLERRM);
        ROLLBACK;
END;

SELECT * FROM GROUPS;
SELECT * FROM STUDENTS;

DELETE FROM GROUPS WHERE ID = 1;
DELETE FROM STUDENTS;
