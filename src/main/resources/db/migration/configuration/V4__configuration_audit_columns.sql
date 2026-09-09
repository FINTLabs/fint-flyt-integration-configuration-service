ALTER TABLE configuration
    RENAME COLUMN last_modified_by TO last_modified_by_legacy;

ALTER TABLE configuration
    ALTER COLUMN last_modified_by_legacy DROP NOT NULL,
    ALTER COLUMN last_modified_by_legacy DROP DEFAULT,
    ALTER COLUMN last_modified_at DROP NOT NULL,
    ALTER COLUMN last_modified_at DROP DEFAULT,
    ADD COLUMN created_at       TIMESTAMPTZ NULL,
    ADD COLUMN created_by       JSONB NOT NULL DEFAULT '{"type":"UNKNOWN"}'::jsonb,
    ADD COLUMN last_modified_by JSONB NOT NULL DEFAULT '{"type":"UNKNOWN"}'::jsonb;

UPDATE configuration
SET last_modified_by = CASE
                           WHEN lower(coalesce(last_modified_by_legacy, '')) IN ('system', '')
                               THEN '{"type":"SYSTEM"}'::jsonb
                           ELSE '{"type":"UNKNOWN"}'::jsonb
    END;

-- Ingen spørring sorterer eller filtrerer på disse kolonnene; last_modified_by-indeksen ville
-- dessuten fulgt kolonnen over på last_modified_by_legacy, som kun leses via primærnøkkel.
DROP INDEX IF EXISTS idx_configuration_last_modified_by;
DROP INDEX IF EXISTS idx_configuration_last_modified_at;
