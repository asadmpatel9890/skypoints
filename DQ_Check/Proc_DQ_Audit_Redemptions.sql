USE SCHEMA SKYPOINTS_DEV.LANDING_STAGE;

CREATE OR REPLACE PROCEDURE SP_DQ_AUDIT_REDEMPTIONS(P_FILE_NAME VARCHAR)
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
      WHERE table_name = 'LANDING_REDEMPTIONS' AND source_file_name = :v_file);
  IF (already > 0) THEN
    RETURN 'SKIPPED: ' || v_file || ' was already audited (' || already::STRING || ' result rows). No checks run.';
  END IF;

  -- 2. Is the file actually loaded?
  LET loaded NUMBER := (
      SELECT COUNT(*) FROM SKYPOINTS_DEV.LANDING_STAGE.LANDING_REDEMPTIONS
      WHERE ENDSWITH(source_file_name, :v_file));
  IF (loaded = 0) THEN
    RETURN 'NOT RUN: no rows for ' || v_file || ' in LANDING_REDEMPTIONS. Load the file first.';
  END IF;

  -- 3. Run all tests and log them in ONE insert
  INSERT INTO SKYPOINTS_DEV.LANDING_STAGE.DQ_AUDIT
         (table_name, source_file_name, test_type, column_name, status, failed_count, total_count, details)
  WITH m AS (   -- one row per member object in this file
      SELECT payload FROM SKYPOINTS_DEV.LANDING_STAGE.LANDING_REDEMPTIONS
      WHERE ENDSWITH(source_file_name, :v_file)
  ),
  x AS (        -- one row per transaction (only where redemptions really is an array)
      SELECT r.value AS v
      FROM m, LATERAL FLATTEN(input => IFF(IS_ARRAY(m.payload:redemptions), m.payload:redemptions, NULL)) r
  ),
  t AS (
      -- NOT NULL: member level
      SELECT 'NOT_NULL' AS test_type, 'member_id' AS col,
             COUNT_IF(NULLIF(TRIM(payload:member_id::STRING), '') IS NULL) AS failed, COUNT(*) AS total FROM m
      UNION ALL
      SELECT 'NOT_NULL', 'feed_date', COUNT_IF(NULLIF(TRIM(payload:feed_date::STRING), '') IS NULL), COUNT(*) FROM m
      -- NOT NULL: transaction level
      UNION ALL
      SELECT 'NOT_NULL', 'txn_id',         COUNT_IF(NULLIF(TRIM(v:txn_id::STRING), '') IS NULL),         COUNT(*) FROM x
      UNION ALL
      SELECT 'NOT_NULL', 'txn_date',       COUNT_IF(NULLIF(TRIM(v:txn_date::STRING), '') IS NULL),       COUNT(*) FROM x
      UNION ALL
      SELECT 'NOT_NULL', 'partner',        COUNT_IF(NULLIF(TRIM(v:partner::STRING), '') IS NULL),        COUNT(*) FROM x
      UNION ALL
      SELECT 'NOT_NULL', 'miles_redeemed', COUNT_IF(NULLIF(TRIM(v:miles_redeemed::STRING), '') IS NULL), COUNT(*) FROM x
      UNION ALL
      SELECT 'NOT_NULL', 'status',         COUNT_IF(NULLIF(TRIM(v:status::STRING), '') IS NULL),         COUNT(*) FROM x
      -- UNIQUE: number of txn_ids that appear more than once in this file
      UNION ALL
      SELECT 'UNIQUE', 'txn_id',
             (SELECT COUNT(*) FROM (SELECT NULLIF(TRIM(v:txn_id::STRING), '') FROM x
                                    WHERE NULLIF(TRIM(v:txn_id::STRING), '') IS NOT NULL
                                    GROUP BY 1 HAVING COUNT(*) > 1)),
             COUNT_IF(NULLIF(TRIM(v:txn_id::STRING), '') IS NOT NULL)
      FROM x
      -- ACCEPTED VALUES (nulls are left to the NOT NULL test)
      UNION ALL
      SELECT 'ACCEPTED_VALUES', 'status',
             COUNT_IF(NULLIF(TRIM(v:status::STRING), '') IS NOT NULL
                      AND UPPER(TRIM(v:status::STRING)) NOT IN ('COMPLETED','PENDING')),
             COUNT(*) FROM x
  )
  SELECT 'LANDING_REDEMPTIONS', :v_file, test_type, col,
         IFF(failed = 0, 'PASS', 'FAIL'), failed, total, NULL
  FROM t
  UNION ALL
  -- Freshness: was anything loaded into the table in the last 24 hours?
  SELECT 'LANDING_REDEMPTIONS', :v_file, 'FRESHNESS', 'loaded_at',
         IFF(hrs IS NULL OR hrs > 24, 'FAIL', 'PASS'),
         IFF(hrs IS NULL OR hrs > 24, 1, 0), 1,
         'hours since last load: ' || COALESCE(hrs::STRING, 'never loaded') || ' (limit 24)'
  FROM (SELECT DATEDIFF('hour', MAX(loaded_at), CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS hrs
        FROM SKYPOINTS_DEV.LANDING_STAGE.LANDING_REDEMPTIONS);

  -- 4. Summary
  LET failed_tests NUMBER := (
      SELECT COUNT(*) FROM SKYPOINTS_DEV.LANDING_STAGE.DQ_AUDIT
      WHERE table_name = 'LANDING_REDEMPTIONS' AND source_file_name = :v_file
        AND run_ts >= :v_start AND status = 'FAIL');

  RETURN 'Redemptions DQ done for ' || v_file || '. Failed tests: ' || failed_tests::STRING;
END;
$$;

