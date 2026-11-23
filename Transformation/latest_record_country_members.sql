create or replace table country_members_latest as
with filter_latest_records_file_date as                                           --- extracting lastest file records wrt to the file date
(
select *,
max(file_date)
    over(partition by mem_id) as latest_file_date 
from SKYPOINTS_DEV.TRANSFORMATION_STAGE.INT_MEMBERS_DERIVED
qualify latest_file_date = file_date
),
filter_latest_records_flight_dt as
(
select *,                                           --- extracting latetst flight date records 
max(flight_dt)
    over(partition by mem_id) as latest_flight_date 
from filter_latest_records_file_date
qualify latest_flight_date = flight_dt
)
select * from filter_latest_records_flight_dt

