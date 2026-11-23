
--

CREATE OR REPLACE PROCEDURE INSERT_DATA_COUNTRY_TABLE()
RETURNS VARCHAR 
LANGUAGE SQL
AS
$$
declare
 c1 cursor for select country_code, target_table from SKYPOINTS_DEV.FINAL_STAGE.COUNTRY_TABLE_MAP;
 tbl varchar;
 cc varchar;
 sch varchar default 'SKYPOINTS_DEV.FINAL_STAGE';
 stmt varchar;
 stmt_um varchar;
 result varchar;
begin
    for rec in c1 do
        cc := rec.country_code;
        tbl := rec.target_table;
        
        stmt:='INSERT INTO '||sch||'.'||tbl||' 
            (NAME, MEM_ID, ENROLL_DT, FLIGHT_DT, TIER, AGENT_NAME, STATE, COUNTRY, DOB, AGE, STALE_members, FLAG, CURR_DATE) 
        select 
        NAME, MEM_ID, ENROLL_DT, FLIGHT_DT, TIER, AGENT_NAME, STATE, COUNTRY, DOB, AGE, STALE_members, FLAG, CURR_DATE
        from SKYPOINTS_DEV.TRANSFORMATION_STAGE.COUNTRY_members_LATEST where country =?';

        
        
        EXECUTE IMMEDIATE :stmt using (cc);
        
        result := 'Inserted all the country tables' ;
    end for;
    return retult;
end;
$$;
----------


