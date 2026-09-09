alter table integration
    add column created_at       timestamptz null,
    add column created_by       jsonb not null default '{"type":"UNKNOWN"}'::jsonb,
    add column last_modified_at timestamptz null,
    add column last_modified_by jsonb not null default '{"type":"UNKNOWN"}'::jsonb;
