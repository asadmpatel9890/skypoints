SET as_of_date = CURRENT_DATE();

INSERT OVERWRITE INTO SKYPOINTS_DEV.TRANSFORMATION_STAGE.INT_MEMBERS
    (NAME, MEM_ID,Enroll_Dt,Flight_Dt,TIER,Agent_Name,State,Country,DOB,Flag,FILE_DATE)

with typed as(
    SELECT 
        TRIM(s.member_name)                                                     as Name,
        Trim(s.member_id)                                                       as Mem_id,
        Try_to_date(trim(s.enrollment_date),'YYYYMMDD')                         as Enroll_dt,
        Try_to_date(trim(s.last_flight_date),'YYYYMMDD')                        as Flight_dt,
        NULLIF(TRIM(s.tier_code),'')                                            as Tier,
        NULLIF(TRIM(s.agent_name),'')                                           as Agent_Name,
        NULLIF(TRIM(s.state),'')                                                as State,
        NULLIF(TRIM(s.country),'')                                              as Country,
        TRY_TO_DATE(trim(s.dob),'DDMMYYYY')                                     as DOB,
        TRIM(s.is_active)                                                       as Flag,
        try_to_date(trim(regexp_substr(source_file_name,'[0-9]+')),'YYYYMMDD')  as FILE_DATE
    FROM SKYPOINTS_DEV.LANDING_STAGE.LANDING_MEMBERS s
)
SELECT 
    typed.name,
    typed.mem_id,
    typed.Enroll_dt,
    typed.Flight_dt,
    typed.Tier,
    typed.Agent_Name,
    typed.State,
    typed.Country,
    typed.DOB,
    typed.Flag,
    typed.FILE_DATE
FROM typed ;

SELECT * FROM INT_MEMBERS