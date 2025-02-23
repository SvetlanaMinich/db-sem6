CREATE OR REPLACE TRIGGER students_cval_trigger
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
DECLARE
    GROUPS_WITH_DESIRED_ID_COUNT NUMBER;
BEGIN
    IF NOT trigger_control_pkg.disable_students_trigger THEN
        IF INSERTING THEN
            UPDATE GROUPS 
            SET C_VAL = C_VAL + 1 
            WHERE ID = :NEW.GROUPS_ID;
        ELSIF UPDATING THEN
            IF :OLD.GROUPS_ID != :NEW.GROUPS_ID THEN
                UPDATE GROUPS 
                SET C_VAL = C_VAL + 1 
                WHERE ID = :NEW.GROUPS_ID;

                UPDATE GROUPS 
                SET C_VAL = C_VAL - 1 
                WHERE ID = :OLD.GROUPS_ID;
            END IF;
        ELSIF DELETING THEN
            SELECT COUNT(*) INTO GROUPS_WITH_DESIRED_ID_COUNT FROM GROUPS WHERE ID = :OLD.GROUPS_ID;
            IF GROUPS_WITH_DESIRED_ID_COUNT > 0 THEN
                UPDATE GROUPS 
                SET C_VAL = C_VAL - 1 
                WHERE ID = :OLD.GROUPS_ID;
            END IF;
        END IF;
    END IF;
END;
/