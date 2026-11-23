# Final Layer (`SKYPOINTS_DEV.FINAL_STAGE`)

This folder holds the target tables. Each member ends up in exactly one country table, chosen from their **latest** record.

## Files

| File | Purpose |
|---|---|
| `Create_country_table.sql` | Creates `COUNTRY_TABLE_TEMPLATE`, then `TABLE_USA`, `TABLE_INDIA`, `TABLE_PHILIPPINES`, `TABLE_CANADA`, `TABLE_AUSTRALIA` and `TABLE_UNMAPPED_COUNTRY`, all built with `LIKE` the template. |
| `COUNTRY_SPLIT_METADATA.sql` | Creates `COUNTRY_TABLE_MAP` (country code → target table, `IS_ACTIVE`) and seeds the 5 countries. |
| `SP_SPLIT_MEMBERS_BY_COUNTRY.sql` *(to add)* | Moves `INT_MEMBERS_DERIVED` into the country tables using "latest record wins". |

## Country mapping

| Code | Table |
|---|---|
| USA | TABLE_USA |
| IND | TABLE_INDIA |
| PHIL | TABLE_PHILIPPINES |
| CAN | TABLE_CANADA |
| AU | TABLE_AUSTRALIA |
| unknown / blank / inactive | TABLE_UNMAPPED_COUNTRY |

To add a country, insert one row into `COUNTRY_TABLE_MAP`. The procedure creates the new table on its next run.

## Country table columns

`NAME, MEM_ID (PK), ENROLL_DT, FLIGHT_DT, TIER, AGENT_NAME, STATE, COUNTRY, DOB, AGE, STALE_MEMBERS, FLAG, CURR_DATE`

## Split logic

1. **Latest per member:** `ROW_NUMBER() OVER (PARTITION BY MEM_ID ORDER BY FILE_DATE DESC, SOURCE_FILE_NAME DESC, SOURCE_FILE_ROW_NUMBER DESC) = 1`.
2. **Only newer records are applied:** a record is compared with `MEMBER_MASTER`, so late or re-sent files are ignored and re-runs change nothing.
3. **Atomic apply:** in one transaction, members who moved country are deleted from their old table, merged into the new one, and `MEMBER_MASTER` is updated.
4. **No silent drops:** unmapped countries go to `TABLE_UNMAPPED_COUNTRY`. Rows missing mandatory fields are skipped here and reported by DQ.

## Run order

```sql
-- one-time
Create_country_table.sql
COUNTRY_SPLIT_METADATA.sql
-- after the transformation layer has run
CALL SKYPOINTS_DEV.FINAL_STAGE.SP_SPLIT_MEMBERS_BY_COUNTRY();
```