CREATE TABLE IF NOT EXISTS SKYPOINTS_DEV.LANDING_STAGE.DQ_AUDIT (
    run_ts            TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    table_name        VARCHAR,
    source_file_name  VARCHAR,   -- NULL for freshness (it is table-level)
    test_type         VARCHAR,   -- NOT_NULL | UNIQUE | ACCEPTED_VALUES | FRESHNESS
    column_name       VARCHAR,
    status            VARCHAR,   -- PASS | FAIL
    failed_count      NUMBER,
    total_count       NUMBER,
    details           VARCHAR    -- used by the freshness test
);

Select * from DQ_AUDIT;
