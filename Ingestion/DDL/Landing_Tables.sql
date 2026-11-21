-- CREATING LANDING TABLE (LANDING_MEMEBERS)

USE SCHEMA SKYPOINTS_DEV.LANDING_STAGE;

CREATE TRANSIENT TABLE IF NOT EXISTS SKYPOINTS_DEV.LANDING_STAGE.LANDING_MEMBERS (
    record_type             VARCHAR,   -- 'H' header or 'D' detail
    member_name             VARCHAR,
    member_id               VARCHAR,
    enrollment_date         VARCHAR,   -- raw YYYYMMDD text
    last_flight_date        VARCHAR,
    tier_code               VARCHAR,
    agent_name              VARCHAR,
    state                   VARCHAR,
    country                 VARCHAR,
    dob                     VARCHAR,   -- raw DDMMYYYY text, may be short
    is_active               VARCHAR,
    source_file_name        VARCHAR,   -- audit and reprocessing
    source_file_row_number  NUMBER,    -- used for latest-wins ordering
    loaded_at               TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
---
-- CREATING A REDEMPTION TABLE TO UNLOAD THE SEMI-STRUCTURE DATA
CREATE TRANSIENT TABLE IF NOT EXISTS LANDING_REDEMPTIONS(
    payload                 VARIANT,
    source_file_name        VARCHAR,   -- audit and reprocessing
    source_file_row_number  NUMBER,    -- used for latest-wins ordering
    loaded_at               TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


select * from landing_members;