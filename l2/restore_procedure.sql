CREATE OR REPLACE PROCEDURE restore_student_data(
    p_restore_time IN TIMESTAMP DEFAULT SYSTIMESTAMP - INTERVAL '1' HOUR
)
IS
BEGIN
    FOR del_record IN (
        SELECT a.STUDENT_ID, a.OLD_NAME, a.OLD_GROUP
        FROM STUDENT_LOG a
        WHERE a.ACTION_TYPE = 'DELETE'
        AND a.CHANGE_DATE <= p_restore_time
        ORDER BY a.CHANGE_DATE DESC
    ) LOOP
        INSERT INTO STUDENTS(ID, NAME, GROUP_ID)
        VALUES (del_record.STUDENT_ID, del_record.OLD_NAME, del_record.OLD_GROUP);
    END LOOP;

    FOR upd_record IN (
        SELECT a.STUDENT_ID, a.OLD_GROUP, a.OLD_NAME
        FROM STUDENT_LOG a
        WHERE a.ACTION_TYPE = 'UPDATE'
        AND a.CHANGE_DATE <= p_restore_time
        ORDER BY a.CHANGE_DATE DESC
    ) LOOP
        UPDATE STUDENTS s
        SET 
            s.GROUP_ID = upd_record.OLD_GROUP,
            s.NAME = upd_record.OLD_NAME
        WHERE s.ID = upd_record.STUDENT_ID;
    END LOOP;

    FOR ins_record IN (
        SELECT a.STUDENT_ID
        FROM STUDENT_LOG a
        WHERE a.ACTION_TYPE = 'INSERT'
        AND a.CHANGE_DATE <= p_restore_time
        ORDER BY a.CHANGE_DATE DESC
    ) LOOP
        DELETE FROM STUDENTS WHERE ID = ins_record.STUDENT_ID;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Restore to ' || p_restore_time || ' completed.');
EXCEPTION
    WHEN OTHERS THEN   -- Ловим ЛЮБОЕ исключение
        ROLLBACK;      -- Откатываем всю транзакцию
        RAISE;         -- Пробрасываем ошибку выше
END; 