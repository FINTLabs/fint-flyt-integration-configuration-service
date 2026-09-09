ALTER TABLE configuration
    ALTER COLUMN comment TYPE text;

ALTER TABLE value_mapping
    ALTER COLUMN mapping_string TYPE text;

ALTER TABLE instance_collection_reference
    ALTER COLUMN reference TYPE text;
