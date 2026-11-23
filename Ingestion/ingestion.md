# Ingestion

Loads raw SkyPoints source files from a Snowflake **internal stage** into the **landing (raw) layer**. Nothing is cleaned or typed here; every value lands as-is with file lineage so later layers can audit and reprocess.

## Contents

| File | Purpose |
|---|---|
| `DDL/Creating_Stages.sql` | Creates the 3 layer schemas in `SKYPOINTS_DEV`: `LANDING_STAGE`, `TRANSFORMATION_STAGE`, `FINAL_STAGE` |
| `DDL/Landing_Tables.sql` | Creates the raw landing tables `LANDING_MEMBERS` and `LANDING_REDEMPTIONS` |
| `SF_internal__stage.sql` | Creates internal stage `skypoint_stage` (directory table enabled) |
| `file_format_members.sql` | `MEMBER_FILE_FORMAT` for the pipe-delimited members flat file |
| `file_format_redemptions.sql` | `REDEMPTION_FILE_FORMAT` for the redemptions JSON file |
| `copy_data_into_table.sql` | `COPY INTO` logic for both landing tables |

## Landing tables (`SKYPOINTS_DEV.LANDING_STAGE`)

Both are **transient** (raw data is reloadable from the stage, so Fail-safe is not needed).

- **`LANDING_MEMBERS`**: one `VARCHAR` column per source field (`record_type` H/D, `member_id`, `enrollment_date` YYYYMMDD, `dob` DDMMYYYY, etc.). Dates stay as text so malformed values don't fail the load.
- **`LANDING_REDEMPTIONS`**: a single `payload VARIANT` column holding each JSON record.

Audit columns on both:
- `source_file_name` (`METADATA$FILENAME`), used for traceability and reprocessing
- `source_file_row_number` (`METADATA$FILE_ROW_NUMBER`), used for latest-record-wins ordering
- `loaded_at`, which defaults to the load timestamp

## File formats

| Format | Settings |
|---|---|
| `MEMBER_FILE_FORMAT` | `CSV`, `FIELD_DELIMITER = '\|'`, `SKIP_HEADER = 1`, `SKIP_BLANK_LINES = TRUE`, `ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE` (bad rows still land in raw; DQ handles them later) |
| `REDEMPTION_FILE_FORMAT` | `JSON`, `STRIP_OUTER_ARRAY = TRUE` (one row per array element) |

## Load logic

| Stage path | Target | Mapping |
|---|---|---|
| `@skypoint_stage/flat_file/` | `LANDING_MEMBERS` | columns `$2`–`$12` + file metadata |
| `@skypoint_stage/semiStruct/` | `LANDING_REDEMPTIONS` | `$1` → `payload` + file metadata |

## Run order

1. `DDL/Creating_Stages.sql`
2. `DDL/Landing_Tables.sql`
3. `SF_internal__stage.sql`
4. `file_format_members.sql`, `file_format_redemptions.sql`
5. Upload files to the stage (`PUT` or Snowsight) under `flat_file/` and `semiStruct/`
6. `copy_data_into_table.sql`

Next step: `DQ_Check/` → `Transformation/` → `Final/`.