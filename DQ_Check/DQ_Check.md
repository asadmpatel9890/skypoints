# DQ_Check

Data quality checks on the **landing tables**. They run once for each loaded file, and every result is written to a single audit table.

## Contents

| File | Purpose |
|---|---|
| `DQ_Table_Landing.sql` | Creates the audit table `LANDING_STAGE.DQ_AUDIT` |
| `Proc_DQ_Audit_Members.sql` | `SP_DQ_AUDIT_MEMBERS(file_name)`: checks `LANDING_MEMBERS` |
| `Proc_DQ_Audit_Redemptions.sql` | `SP_DQ_AUDIT_REDEMPTIONS(file_name)`: checks `LANDING_REDEMPTIONS` |

## `DQ_AUDIT`

There is one row per test, per file, per run:
`run_ts`, `table_name`, `source_file_name`, `test_type` (`NOT_NULL` / `UNIQUE` / `ACCEPTED_VALUES` / `FRESHNESS`), `column_name`, `status` (`PASS` / `FAIL`), `failed_count`, `total_count`, `details`.

## How each procedure runs

1. **Strip the path:** the file name you pass is cut down to the bare name (`SPLIT_PART(..., '/', -1)`).
2. **Skip files already audited:** if the file already has rows in `DQ_AUDIT`, the procedure returns `SKIPPED`.
3. **Check the file is loaded:** if there are no rows for the file in the landing table, it returns `NOT RUN`.
4. **Run all tests in one `INSERT`:** a file never ends up half-audited.
5. **Return a summary:** the result is `... Failed tests: N`.

## Checks

| Test | Members (`record_type = 'D'` rows) | Redemptions (JSON) |
|---|---|---|
| NOT_NULL | `member_id`, `member_name`, `enrollment_date` | member level: `member_id`, `feed_date`<br>transaction level: `txn_id`, `txn_date`, `partner`, `miles_redeemed`, `status` |
| UNIQUE | `member_id` | `txn_id` |
| ACCEPTED_VALUES | `record_type` ∈ {H, D} (all rows)<br>`is_active` ∈ {A, I}<br>`tier_code` ∈ {GLD, SLV, PLT} | `status` ∈ {COMPLETED, PENDING} |
| FRESHNESS | last `loaded_at` within 24 h | last `loaded_at` within 24 h |

- Blank strings are treated as NULL (`NULLIF(TRIM(x), '')`).
- The ACCEPTED_VALUES tests ignore NULLs, since the NOT_NULL tests already cover them.
- For UNIQUE, `failed_count` is the number of IDs that appear more than once, not the number of duplicate rows.
- FRESHNESS is measured on the whole table, not on the file being checked. The result explains itself in `details`.
- Redemptions are flattened only where `redemptions` is actually an array (`IS_ARRAY`).

## Usage

```sql
-- one-time setup
-- run DQ_Table_Landing.sql, then both Proc_*.sql files

CALL SKYPOINTS_DEV.LANDING_STAGE.SP_DQ_AUDIT_MEMBERS('<members_file_name>');
CALL SKYPOINTS_DEV.LANDING_STAGE.SP_DQ_AUDIT_REDEMPTIONS('<redemptions_file_name>');

SELECT * FROM SKYPOINTS_DEV.LANDING_STAGE.DQ_AUDIT WHERE status = 'FAIL';
```

Where it fits in the pipeline: `Ingestion/` → **`DQ_Check/`** → `Transformation/`.