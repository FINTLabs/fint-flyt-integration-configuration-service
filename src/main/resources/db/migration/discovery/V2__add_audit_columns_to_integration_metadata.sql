alter table integration_metadata
    add column created_at timestamptz null,
    add column created_by jsonb not null default '{"type":"UNKNOWN"}'::jsonb;
