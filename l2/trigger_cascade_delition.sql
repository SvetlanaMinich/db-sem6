CREATE OR REPLACE TRIGGER groups_bd_cascade
BEFORE DELETE ON GROUPS
FOR EACH ROW
BEGIN
    trigger_control_pkg.disable_students_trigger := TRUE;
    DELETE FROM STUDENTS WHERE GROUPS_ID = :OLD.ID;
    trigger_control_pkg.disable_students_trigger := FALSE;
EXCEPTION
    WHEN OTHERS THEN
        trigger_control_pkg.disable_students_trigger := FALSE;
        RAISE;
END;