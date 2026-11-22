set curr_date = CURRENT_DATE();

Create or replace table INT_MEMBERS_DERIVED(
    NAME VARCHAR(255) NOT NULL,
	MEM_ID VARCHAR(18) NOT NULL,
	ENROLL_DT DATE NOT NULL,
	FLIGHT_DT DATE,
	TIER VARCHAR(5),
	AGENT_NAME VARCHAR(255),
	STATE VARCHAR(5),
	COUNTRY VARCHAR(5),
	DOB DATE,
    AGE INT,
    STALE_MEMBERS CHAR(1),
	FLAG VARCHAR(1),
    CURR_DATE DATE,
	constraint PK_MEMBER_INTERMEDIATE primary key (MEM_ID)

);

insert into INT_MEMBERS_DERIVED 
select
    name,
    mem_id, 
    enroll_dt, 
    flight_dt,
    tier, 
    agent_name,
    state,
    country,
    dob,
    datediff('YEAR',dob,current_date()) as age,
    case when DATEDIFF('DAY',FLIGHT_DT,current_date()) > 90 THEN 'Y' else 'N' end as stale_flag,
    FLAG,
    CURRENT_DATE()
from INT_MEMBERS;

SELECT * FROM INT_MEMBERS_DERIVED;