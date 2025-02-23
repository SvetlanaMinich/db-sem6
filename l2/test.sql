BEGIN
    INSERT INTO GROUPS(id, name) VALUES (1, 'Group A');
    INSERT INTO GROUPS(id, name) VALUES (2, 'Group B');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;

SELECT * FROM GROUPS;
SELECT * FROM STUDENTS;

BEGIN
    DELETE FROM STUDENTS
    WHERE ID = 1;
    
    INSERT INTO STUDENTS(ID, NAME, GROUPS_ID) VALUES (1, 'John', 1);
    SELECT * FROM GROUPS;
    
    UPDATE students SET groups_id = 2 WHERE GROUPS_ID = 1;
    SELECT * FROM groups;
    
    DELETE FROM students WHERE id = 1;
    SELECT * FROM groups;
END;


BEGIN
    INSERT INTO students(id, name, groupS_id) VALUES (2, 'Alice', 1);
    UPDATE students SET groupS_id = 2 WHERE id = 2;
    DELETE FROM students WHERE id = 2;
    
    SELECT * FROM student_log;
    
    ROLLBACK;
END;

-- Для избежания конфликтов триггеров
CREATE OR REPLACE PACKAGE trigger_control_pkg IS
    disable_students_trigger BOOLEAN := FALSE;
END;
BEGIN
    INSERT INTO students(ID, NAME, GROUPS_ID) VALUES (3, 'Bob', 1);
    DELETE FROM groups WHERE id = 1;
    
    SELECT * FROM students;
    SELECT * FROM groups;
    
    ROLLBACK;
END;


BEGIN
    BEGIN
        INSERT INTO groups(id, name) VALUES (2, 'New Group');
    END;
    
    BEGIN
        INSERT INTO groups(id, name) VALUES (3, 'Group B');
    END;
    
    ROLLBACK;
END;