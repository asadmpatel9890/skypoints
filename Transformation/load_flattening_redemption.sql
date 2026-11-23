use schema SKYPOINTS_DEV.TRANSFORMATION_STAGE;

INSERT INTO INT_FLAT_REDEMPTIONS(    
    MEMBER_ID,
    FEED_DATE,
    TXN_ID,
    TXN_DATE,
    PARTNER,
    MILES_REDEEMED,
    STATUS,
    SOURCE_FILE_NAME,
    SOURCE_FILE_ROW_NUMBER,
    LOADED_AT)
SELECT 
    trim(l.payload:member_id::STRING)                            AS MEMBER_ID,
    TRY_TO_DATE(TRIM(L.PAYLOAD:feed_date::STRING),'YYYYMMDD')   AS feed_date,
    r.value:txn_id::STRING                                      AS TXN_ID,
    TRY_TO_DATE(TRIM(r.value:txn_date::STRING),'YYYYMMDD')      AS TXN_DATE,
    TRIM(r.value:partner::STRING)                               AS PARTNER,
    TRY_TO_NUMBER(TRIM(r.value:miles_redeemed::string))         AS miles_redeemed,
    trim(r.value:status::STRING)                                AS STATUS,
    l.source_file_name,
    l.source_file_row_number,
    l.loaded_at
,FROM SKYPOINTS_DEV.LANDING_STAGE.LANDING_REDEMPTIONS l,
    LATERAL FLATTEN(INPUT => L.PAYLOAD:redemptions) r