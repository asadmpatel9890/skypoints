--CREATING AN INTERMEDIATE TABLE 
USE schema SKYPOINTS_DEV.TRANSFORMATION_STAGE;

CREATE OR REPLACE TABLE INT_MEMBERS (
    NAME            VARCHAR(255)  NOT NULL,
    MEM_ID          VARCHAR(18)   NOT NULL,
    ENROLL_DT       DATE          NOT NULL,
    FLIGHT_DT       DATE,
    TIER            VARCHAR(5),
    AGENT_NAME      VARCHAR(255),
    STATE           VARCHAR(5),
    COUNTRY         VARCHAR(5),
    DOB             DATE,
    FLAG            CHAR,
             
    CONSTRAINT PK_MEMBER_INTERMEDIATE PRIMARY KEY (MEM_ID)  -- informational only in Snowflake
);


select * from int_members;