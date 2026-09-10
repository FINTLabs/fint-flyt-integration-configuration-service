create table integration
(
    id                                bigserial not null,
    active_configuration_id           int8,
    destination                       varchar(255),
    source_application_id             int8,
    source_application_integration_id varchar(255),
    state                             varchar(255),
    primary key (id)
);
alter table integration
    add constraint UniqueSourceApplicationIdAndSourceApplicationIntegrationId unique (source_application_id, source_application_integration_id);
