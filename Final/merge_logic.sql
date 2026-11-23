use schema SKYPOINTS_DEV.FINAL_STAGE

Create or replace table mem_redempt_merge as
select 
    m.name, 
    m.mem_id, 
    r.partner,
    r.miles_redeemed,
    m.country 
from SKYPOINTS_DEV.TRANSFORMATION_STAGE.COUNTRY_MEMBERS_LATEST m 
    inner join 
SKYPOINTS_DEV.TRANSFORMATION_STAGE.INT_FLAT_REDEMPTIONS r 
    on m.mem_id = r.member_id 

