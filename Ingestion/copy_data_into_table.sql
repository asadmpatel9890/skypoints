COPY INTO LANDING_MEMBERS (
    record_type, member_name, member_id, enrollment_date, last_flight_date,
    tier_code, agent_name, state, country, dob, is_active,
    source_file_name, source_file_row_number)
FROM (
    SELECT $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
           METADATA$FILENAME, METADATA$FILE_ROW_NUMBER
    FROM @skypoint_stage/flat_file/SkyPoints_Members_20121013.txt
)
FILE_FORMAT = (FORMAT_NAME = 'MEMBER_FILE_FORMAT');

--REDEMPTIONS 
COPY INTO LANDING_REDEMPTIONS (payload, source_file_name, source_file_row_number)
FROM (
    SELECT $1, METADATA$FILENAME, METADATA$FILE_ROW_NUMBER
    FROM @skypoint_stage/semiStruct/
)
FILES = ('SkyPoints_Members_20241011.json')
FILE_FORMAT = (FORMAT_NAME = 'REDEMPTION_FILE_FORMAT')

