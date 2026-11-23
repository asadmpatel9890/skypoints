USE SCHEMA SKYPOINTS_DEV.TRANSFORMATION_STAGE;

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
    CURRENT_DATE(),
    FILE_DATE
from INT_MEMBERS;


select * from INT_MEMBERS_DERIVED;

