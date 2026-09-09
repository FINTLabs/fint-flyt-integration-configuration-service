ALTER TABLE configuration
    ADD COLUMN IF NOT EXISTS last_modified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS last_modified_by TEXT NOT NULL DEFAULT 'system';

CREATE INDEX IF NOT EXISTS idx_configuration_last_modified_at ON configuration (last_modified_at DESC);
CREATE INDEX IF NOT EXISTS idx_configuration_last_modified_by ON configuration (last_modified_by);