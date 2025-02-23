CREATE TABLE GROUPS (
    ID NUMBER PRIMARY KEY,
    NAME VARCHAR2(100) NOT NULL,
    C_VAL NUMBER DEFAULT 0
);

CREATE TABLE STUDENTS (
    ID NUMBER PRIMARY KEY,
    NAME VARCHAR2(100) NOT NULL,
    GROUPS_ID NUMBER NOT NULL REFERENCES GROUPS(ID)
);

DROP TABLE STUDENTS;
DROP TABLE GROUPS;

SELECT ID, NAME, C_VAL FROM GROUPS;
SELECT * FROM STUDENTS;