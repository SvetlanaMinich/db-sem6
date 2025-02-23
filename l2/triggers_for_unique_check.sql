CREATE SEQUENCE groups_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE students_seq START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER groups_create_index_and_check_unique_name_and_index
BEFORE INSERT ON GROUPS
FOR EACH ROW
DECLARE
    name_count NUMBER;
    id_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO id_count 
    FROM GROUPS 
    WHERE ID = :NEW.ID;
        
    IF id_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Group ID must be unique');
    END IF;
    
    SELECT COUNT(*) INTO name_count 
    FROM GROUPS 
    WHERE NAME = :NEW.NAME;
    
    IF name_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Group name must be unique.');
    END IF;
END;

CREATE OR REPLACE TRIGGER students_create_index_and_check_unique_index
BEFORE INSERT ON STUDENTS
FOR EACH ROW
DECLARE
    id_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO id_count 
    FROM STUDENTS 
    WHERE ID = :NEW.ID;
        
    IF id_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Students ID must be unique');
    END IF;
END;