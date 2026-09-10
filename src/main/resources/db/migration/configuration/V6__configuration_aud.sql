CREATE TABLE configuration_aud
(
    id                      BIGINT   NOT NULL,
    rev                     BIGINT   NOT NULL REFERENCES revinfo (rev),
    revtype                 SMALLINT,
    integration_id          INT8,
    integration_metadata_id INT8,
    version                 INT4,
    completed               BOOLEAN,
    comment                 TEXT,
    mapping_id              INT8,
    PRIMARY KEY (id, rev)
);
