create or replace table country_members_latest as
select *, max(file_date)over(partition by name) as latest_file_date from SKYPOINTS_DEV.TRANSFORMATION_STAGE.INT_MEMBERS_DERIVED
qualify latest_file_date = file_date;

