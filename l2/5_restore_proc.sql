CREATE OR REPLACE PROCEDURE restore_student_data(
    point_time IN TIMESTAMP DEFAULT NULL,
    offset_time IN NUMBER DEFAULT 0
)
IS
    restore_time TIMESTAMP;
    groups_id_num NUMBER;
BEGIN
    IF point_time IS NULL AND offset_time = 0 THEN
        restore_time := SYSTIMESTAMP;
    ELSIF point_time IS NULL THEN
        restore_time := SYSTIMESTAMP - NUMTODSINTERVAL(offset_time, 'SECOND');
    ELSE
        restore_time := point_time;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Restore time: ' || TO_CHAR(restore_time, 'DD-MON-YYYY HH24:MI:SS.FF3'));
    
    FOR REC IN (
        SELECT A.STUDENT_ID, A.ACTION_TYPE, A.OLD_GROUP, A.NEW_GROUP, A.OLD_NAME, A.NEW_NAME
        FROM STUDENT_LOG A
        WHERE A.CHANGE_DATE <= SYSTIMESTAMP 
              AND A.CHANGE_DATE > restore_time
        ORDER BY A.CHANGE_DATE DESC
    ) LOOP
        IF REC.ACTION_TYPE = 'DELETE' THEN
            SELECT COUNT(*) INTO groups_id_num
            FROM GROUPS
            WHERE ID = REC.OLD_GROUP;

            IF groups_id_num = 0 THEN
                 DBMS_OUTPUT.PUT_LINE('Cannot restore student ' || REC.STUDENT_ID || ' because group ' || REC.OLD_GROUP || ' does not exist anymore');
            ELSE
                INSERT INTO STUDENTS(ID, NAME, GROUPS_ID)
                VALUES (REC.STUDENT_ID, REC.OLD_NAME, REC.OLD_GROUP);
            END IF;
        ELSIF REC.ACTION_TYPE = 'UPDATE' THEN
            SELECT COUNT(*) INTO groups_id_num
            FROM GROUPS
            WHERE ID = REC.OLD_GROUP;

            IF groups_id_num = 0 THEN
                 DBMS_OUTPUT.PUT_LINE('Cannot restore student ' || REC.STUDENT_ID || ' because group ' || REC.OLD_GROUP || ' does not exist anymore');
            ELSE
                UPDATE STUDENTS
                SET NAME = REC.OLD_NAME,
                    GROUPS_ID = REC.OLD_GROUP
                WHERE ID = REC.STUDENT_ID;
            END IF;
        ELSE
            DELETE FROM STUDENTS
            WHERE ID = REC.STUDENT_ID;
        END IF;
    END LOOP;    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN   -- Ловим ЛЮБОЕ исключение
        DBMS_OUTPUT.PUT_LINE('Ошибка восстановления: ' || SQLERRM);
        ROLLBACK;      -- Откатываем всю транзакцию
        RAISE;         -- Пробрасываем ошибку выше
END; 

BEGIN
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (200, 'GROUP A', 0);
    restore_student_data(NULL,11000);
END;

-- TEST
BEGIN
    INSERT INTO GROUPS (ID, NAME, C_VAL) VALUES (201, 'G2', 0);

    INSERT INTO STUDENTS (ID, NAME, GROUPS_ID) VALUES (1, 'S1', 201);
    UPDATE STUDENTS
    SET NAME = 'S1_UPDATED'
    WHERE ID = 1;
    DBMS_LOCK.SLEEP(10);

    DELETE FROM STUDENTS WHERE ID = 1;

    DBMS_OUTPUT.PUT_LINE('----- Логи STUDENT_LOG:');
    FOR rec IN (SELECT * FROM STUDENT_LOG ORDER BY CHANGE_DATE DESC) LOOP
        DBMS_OUTPUT.PUT_LINE('Log ID: ' || rec.LOG_ID || 
                             ', Student: ' || rec.STUDENT_ID || 
                             ', Action: ' || rec.ACTION_TYPE || 
                             ', Old Group: ' || rec.OLD_GROUP || 
                             ', New Group: ' || rec.NEW_GROUP || 
                             ', Old Name: ' || rec.OLD_NAME || 
                             ', New Name: ' || rec.NEW_NAME || 
                             ', Date: ' || TO_CHAR(rec.CHANGE_DATE, 'DD-MON-YYYY HH24:MI:SS'));
    END LOOP;

    restore_student_data(NULL, 60);
    DBMS_LOCK.SLEEP(5);

    DBMS_OUTPUT.PUT_LINE('----- Студенты после восстановления: ');
    FOR rec IN (SELECT ID, NAME, GROUPS_ID FROM STUDENTS) LOOP
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.ID || ', NAME: ' || rec.NAME || ', GROUPS_ID: ' || rec.GROUPS_ID);
    END LOOP;

    ROLLBACK;
    DELETE FROM GROUPS;
    DELETE FROM STUDENTS;
    DELETE FROM STUDENT_LOG;
    DBMS_OUTPUT.PUT_LINE('Тест завершён УСПЕШНО');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка в тесте: ' || SQLERRM);
        ROLLBACK;
        DELETE FROM GROUPS;
        DELETE FROM STUDENTS;
        DELETE FROM STUDENT_LOG;        
END;

DELETE FROM STUDENT_LOG;
DELETE FROM STUDENTS;
DELETE FROM GROUPS;
SELECT * FROM STUDENT_LOG;
SELECT * FROM STUDENTS;