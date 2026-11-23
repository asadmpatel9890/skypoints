# Transformation

Turns raw landing data into typed, cleaned and enriched tables in `SKYPOINTS_DEV.TRANSFORMATION_STAGE`. These tables feed the country split in `Final/`.

## Contents

DDL (create) and DML (load) are kept in separate scripts.

| File | Type | Purpose |
|---|---|---|
| `Create_int_table.sql` | DDL | Creates `INT_MEMBERS` (typed member table) |
| `Load_int_members.sql` | DML | Loads `LANDING_MEMBERS` → `INT_MEMBERS` (`INSERT OVERWRITE`) |
| `Create_dervied_col_members.sql` | DDL | Creates `INT_MEMBERS_DERIVED` |
| `load_derived_column_memebers.sql` | DML | Loads `INT_MEMBERS` → `INT_MEMBERS_DERIVED` with derived columns |
| `latest_record_country_members.sql` | CTAS | Builds `COUNTRY_MEMBERS_LATEST` (latest record per member) |
| `Create_flattening_redemption_landing.sql` | DDL | Creates `INT_FLAT_REDEMPTIONS` |
| `load_flattening_redemption.sql` | DML | Flattens `LANDING_REDEMPTIONS` JSON → `INT_FLAT_REDEMPTIONS` |

## Members flow

**1. `INT_MEMBERS`: typing and cleansing**
- `TRIM` on every field. `UPPER(NULLIF(..., ''))` on tier, agent, state and country, so blank values become `NULL`.
- Dates are parsed with `TRY_TO_DATE`, so bad values become `NULL` instead of failing the load: enrollment and last-flight dates use `YYYYMMDD`, DOB uses `DDMMYYYY`.
- `FILE_DATE` is the date taken from the digits in `source_file_name`.
- `PK(MEM_ID)` is informational only; Snowflake doesn't enforce it.

**2. `INT_MEMBERS_DERIVED`: derived columns**
- `AGE` = `DATEDIFF('YEAR', DOB, CURRENT_DATE())`
- `STALE_MEMBERS` = `'Y'` if the last flight was more than 90 days ago, otherwise `'N'`
- `CURR_DATE` = the processing date

**3. `COUNTRY_MEMBERS_LATEST`: latest record wins**
- Partitioned by `MEM_ID`.
- Step 1: keep the rows from each member's latest file (`MAX(FILE_DATE) OVER (PARTITION BY MEM_ID)` + `QUALIFY`).
- Step 2: within those rows, keep the row with the latest `FLIGHT_DT` (`MAX(FLIGHT_DT) OVER (PARTITION BY MEM_ID)` + `QUALIFY`).

**Lineage**

![Members lineage](images/lineage_members.png)

![Latest members to country tables](images/lineage_country_latest.png)

## Redemptions flow

**`INT_FLAT_REDEMPTIONS`: flattening the JSON**
- Takes `member_id` and `feed_date` from the top level of the payload.
- Turns each element of `payload:redemptions` into its own row (`LATERAL FLATTEN`), with `txn_id`, `txn_date`, `partner`, `miles_redeemed` and `status`.
- Dates are parsed with `TRY_TO_DATE` and numbers with `TRY_TO_NUMBER`. Lineage columns (`source_file_name`, `source_file_row_number`, `loaded_at`) are carried over.

**Lineage**

![Redemptions lineage](images/lineage_redemptions.png)

## Run order

**DDL (one-time setup)**
1. `Create_int_table.sql`
2. `Create_dervied_col_members.sql`
3. `Create_flattening_redemption_landing.sql`

**DML (each run)**
1. `Load_int_members.sql`
2. `load_derived_column_memebers.sql`
3. `latest_record_country_members.sql`
4. `load_flattening_redemption.sql` (doesn't depend on steps 1–3)

Next step: `Final/` (one table per country from `COUNTRY_MEMBERS_LATEST`).