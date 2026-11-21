USE SCHEMA SKYPOINTS_DEV.LANDING_STAGE;

CREATE OR REPLACE PROCEDURE SP_DQ_AUDIT_MEMBERS(P_FILE_NAME VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
  LET v_file  VARCHAR := SPLIT_PART(:P_FILE_NAME, '/', -1);   -- keep only the bare file name
  LET v_start TIMESTAMP_NTZ := CURRENT_TIMESTAMP();

  -- 1. Has this file already been audited?
  LET already NUMBER := (
      SELECT COUNT(*) FROM SKYPOINTS_DEV.LANDING_STAGE.DQ_AUDIT
      WHERE table_name = 'LANDING_MEMBERS' AND source_file_name = :v_file);
  IF (already > 0) THEN
    RETURN 'SKIPPED: ' || v_file || ' was already audited (' || already::STRING || ' result rows). No checks run.';
  END IF;

  -- 2. Is the file actually loaded? (don't log an audit for a file that isn't there yet)
  LET loaded NUMBER := (
      SELECT COUNT(*) FROM SKYPOINTS_DEV.LANDING_STAGE.LANDING_MEMBERS
      WHERE ENDSWITH(source_file_name, :v_file));
  IF (loaded = 0) THEN
    RETURN 'NOT RUN: no rows for ' || v_file || ' in LANDING_MEMBERS. Load the file first.';
  END IF;

  -- 3. Run all tests and log them in ONE insert, so a file is never half-audited
  INSERT INTO SKYPOINTS_DEV.LANDING_STAGE.DQ_AUDIT
         (table_name, source_file_name, test_type, column_name, status, failed_count, total_count, details)
  WITH f AS (SELECT * FROM SKYPOINTS_DEV.LANDING_STAGE.LANDING_MEMBERS
             WHERE ENDSWITH(source_file_name, :v_file)),
       d AS (SELECT * FROM f WHERE record_type = 'D'),
  t AS (
      SELECT 'NOT_NULL' AS test_type, 'member_id' AS col,
             COUNT_IF(NULLIF(TRIM(member_id), '') IS NULL) AS failed, COUNT(*) AS total FROM d
      UNION ALL
      SELECT 'NOT_NULL', 'member_name',     COUNT_IF(NULLIF(TRIM(member_name), '') IS NULL),     COUNT(*) FROM d
      UNION ALL
      SELECT 'NOT_NULL', 'enrollment_date', COUNT_IF(NULLIF(TRIM(enrollment_date), '') IS NULL), COUNT(*) FROM d
      UNION ALL
      SELECT 'UNIQUE', 'member_id',
             (SELECT COUNT(*) FROM (SELECT member_id FROM d
                                    WHERE NULLIF(TRIM(member_id), '') IS NOT NULL
                                    GROUP BY member_id HAVING COUNT(*) > 1)),
             COUNT_IF(NULLIF(TRIM(member_id), '') IS NOT NULL)
      FROM d
      UNION ALL
      SELECT 'ACCEPTED_VALUES', 'record_type',
             COUNT_IF(record_type IS NOT NULL AND UPPER(TRIM(record_type)) NOT IN ('H','D')), COUNT(*) FROM f
      UNION ALL
      SELECT 'ACCEPTED_VALUES', 'is_active',
             COUNT_IF(is_active IS NOT NULL AND UPPER(TRIM(is_active)) NOT IN ('A','I')), COUNT(*) FROM d
      UNION ALL
      SELECT 'ACCEPTED_VALUES', 'tier_code',
             COUNT_IF(tier_code IS NOT NULL AND UPPER(TRIM(tier_code)) NOT IN ('GLD','SLV','PLT')), COUNT(*) FROM d
  )
  SELECT 'LANDING_MEMBERS', :v_file, test_type, col,
         IFF(failed = 0, 'PASS', 'FAIL'), failed, total, NULL
  FROM t
  UNION ALL
  -- Freshness: was anything loaded into the table in the last 24 hours?
  SELECT 'LANDING_MEMBERS', :v_file, 'FRESHNESS', 'loaded_at',
         IFF(hrs IS NULL OR hrs > 24, 'FAIL', 'PASS'),
         IFF(hrs IS NULL OR hrs > 24, 1, 0), 1,
         'hours since last load: ' || COALESCE(hrs::STRING, 'never loaded') || ' (limit 24)'
  FROM (SELECT DATEDIFF('hour', MAX(loaded_at), CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS hrs
        FROM SKYPOINTS_DEV.LANDING_STAGE.LANDING_MEMBERS);

  -- 4. Summary
  LET failed_tests NUMBER := (
      SELECT COUNT(*) FROM SKYPOINTS_DEV.LANDING_STAGE.DQ_AUDIT
      WHERE table_name = 'LANDING_MEMBERS' AND source_file_name = :v_file
        AND run_ts >= :v_start AND status = 'FAIL');

  RETURN 'Members DQ done for ' || v_file || '. Failed tests: ' || failed_tests::STRING;
END;
$$;