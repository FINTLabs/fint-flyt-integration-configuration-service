create table configuration
(
    id                      bigserial not null,
    comment                 varchar(255),
    completed               boolean   not null,
    integration_id          int8      not null,
    integration_metadata_id int8      not null,
    version                 int4,
    mapping_id              int8      not null,
    primary key (id)
);
create table instance_collection_reference
(
    id        bigserial not null,
    index     int4      not null,
    reference varchar(255),
    primary key (id)
);
create table object_collection_mapping
(
    id bigserial not null,
    primary key (id)
);
create table object_collection_mapping_object_mappings
(
    collection_mapping_id int8 not null,
    element_mapping_id    int8 not null
);
create table object_collection_mapping_objects_from_collection_mappings
(
    collection_mapping_id      int8 not null,
    from_collection_mapping_id int8 not null
);
create table object_mapping
(
    id bigserial not null,
    primary key (id)
);
create table object_mapping_object_collection_mapping_per_key
(
    object_mapping_id            int8         not null,
    object_collection_mapping_id int8         not null,
    key                          varchar(255) not null,
    primary key (object_mapping_id, key)
);
create table object_mapping_object_mapping_per_key
(
    parent_id int8         not null,
    child_id  int8         not null,
    key       varchar(255) not null,
    primary key (parent_id, key)
);
create table object_mapping_value_collection_mapping_per_key
(
    object_mapping_id           int8         not null,
    value_collection_mapping_id int8         not null,
    key                         varchar(255) not null,
    primary key (object_mapping_id, key)
);
create table object_mapping_value_mapping_per_key
(
    object_mapping_id int8         not null,
    value_mapping_id  int8         not null,
    key               varchar(255) not null,
    primary key (object_mapping_id, key)
);
create table objects_from_collection_mapping_references_ordered
(
    objects_from_collection_mapping_id int8 not null,
    instance_collection_reference_id   int8 not null
);
create table objects_from_collection_mapping
(
    id                bigserial not null,
    object_mapping_id int8      not null,
    primary key (id)
);
create table value_collection_mapping
(
    id bigserial not null,
    primary key (id)
);
create table value_collection_mapping_value_mappings
(
    collection_mapping_id int8 not null,
    element_mapping_id    int8 not null
);
create table value_collection_mapping_values_from_collection_mappings
(
    collection_mapping_id      int8 not null,
    from_collection_mapping_id int8 not null
);
create table value_mapping
(
    id             bigserial    not null,
    mapping_string varchar(255),
    type           varchar(255) not null,
    primary key (id)
);
create table values_from_collection_mapping_references_ordered
(
    values_from_collection_mapping_id int8 not null,
    instance_collection_reference_id  int8 not null
);
create table values_from_collection_mapping
(
    id               bigserial not null,
    value_mapping_id int8      not null,
    primary key (id)
);
alter table configuration
    add constraint UniqueIntegrationIdAndVersion unique (integration_id, version);
alter table object_collection_mapping_object_mappings
    add constraint UK_a0vn9eam7l35afm90k6ylu7le unique (element_mapping_id);
alter table object_collection_mapping_objects_from_collection_mappings
    add constraint UK_o8qrmt9mvri5n6rv9ag3bu3ey unique (from_collection_mapping_id);
alter table object_mapping_object_collection_mapping_per_key
    add constraint UK_2adm7ftc95kgcrvt1nfsgjw3c unique (object_collection_mapping_id);
alter table object_mapping_object_mapping_per_key
    add constraint UK_oqrcyqyttp3a5jti0qsvcowic unique (child_id);
alter table object_mapping_value_collection_mapping_per_key
    add constraint UK_156j33a8q9p9nm8el5fwq6jxi unique (value_collection_mapping_id);
alter table object_mapping_value_mapping_per_key
    add constraint UK_ptwngyxt6t1up273t6ertw40t unique (value_mapping_id);
alter table objects_from_collection_mapping_references_ordered
    add constraint UK_k8tdwivvk7pex39aw8uckoyt1 unique (instance_collection_reference_id);
alter table value_collection_mapping_value_mappings
    add constraint UK_81o2214022lytsm691por0b9j unique (element_mapping_id);
alter table value_collection_mapping_values_from_collection_mappings
    add constraint UK_6tsyyv1pvnqmdr7f2avn239m7 unique (from_collection_mapping_id);
alter table values_from_collection_mapping_references_ordered
    add constraint UK_nxe1x7yq6o3f3lf9gyepwsoqq unique (instance_collection_reference_id);
alter table configuration
    add constraint FKwmivbmg8cyv1hyhr9951xu47 foreign key (mapping_id) references object_mapping;
alter table object_collection_mapping_object_mappings
    add constraint FKsdk72agykqag4xjoq9y12aeyj foreign key (element_mapping_id) references object_mapping;
alter table object_collection_mapping_object_mappings
    add constraint FKln0boomy063wg78kown5bjr09 foreign key (collection_mapping_id) references object_collection_mapping;
alter table object_collection_mapping_objects_from_collection_mappings
    add constraint FKbkbieyhnkl906t7ag1fnlriah foreign key (from_collection_mapping_id) references objects_from_collection_mapping;
alter table object_collection_mapping_objects_from_collection_mappings
    add constraint FKs0hyfa9qqtao8vecqm2ikumxu foreign key (collection_mapping_id) references object_collection_mapping;
alter table object_mapping_object_collection_mapping_per_key
    add constraint FKoajrfdkq22yk7y64xbior6oo0 foreign key (object_collection_mapping_id) references object_collection_mapping;
alter table object_mapping_object_collection_mapping_per_key
    add constraint FK8q49btex188odatuyrt2wmoem foreign key (object_mapping_id) references object_mapping;
alter table object_mapping_object_mapping_per_key
    add constraint FKqpltue1j2m8s5eclob9ddhi17 foreign key (child_id) references object_mapping;
alter table object_mapping_object_mapping_per_key
    add constraint FKnw7jt09f3aoq9mu0cu5jdhd36 foreign key (parent_id) references object_mapping;
alter table object_mapping_value_collection_mapping_per_key
    add constraint FKj21v9e9ryoue138y2630tlew0 foreign key (value_collection_mapping_id) references value_collection_mapping;
alter table object_mapping_value_collection_mapping_per_key
    add constraint FKgjg189qebrfujh4x927bcwdwl foreign key (object_mapping_id) references object_mapping;
alter table object_mapping_value_mapping_per_key
    add constraint FKmbs8y6aekhqoo3i5ugohgdmqi foreign key (value_mapping_id) references value_mapping;
alter table object_mapping_value_mapping_per_key
    add constraint FK7u1q81aimulsgn0k13ri5r9nr foreign key (object_mapping_id) references object_mapping;
alter table objects_from_collection_mapping_references_ordered
    add constraint FK3qcj55prtvetwrrtvvbnr7so4 foreign key (instance_collection_reference_id) references instance_collection_reference;
alter table objects_from_collection_mapping_references_ordered
    add constraint FKfcttpi2dhdcwmn60irnbdw3yn foreign key (objects_from_collection_mapping_id) references objects_from_collection_mapping;
alter table objects_from_collection_mapping
    add constraint FKg9htsc08dvpg63kjxxn2914ds foreign key (object_mapping_id) references object_mapping;
alter table value_collection_mapping_value_mappings
    add constraint FKi75h2s4t9d09en05yrwvugygg foreign key (element_mapping_id) references value_mapping;
alter table value_collection_mapping_value_mappings
    add constraint FK3fy02sw4xbqik3snec1mwc0d8 foreign key (collection_mapping_id) references value_collection_mapping;
alter table value_collection_mapping_values_from_collection_mappings
    add constraint FKjiu8cel9pfatl3f9lgcx6e3nl foreign key (from_collection_mapping_id) references values_from_collection_mapping;
alter table value_collection_mapping_values_from_collection_mappings
    add constraint FKdxr5x6iqfmlewo8p8re4t7b67 foreign key (collection_mapping_id) references value_collection_mapping;
alter table values_from_collection_mapping_references_ordered
    add constraint FK2tq5ntbxvf0fg5578p8t334ce foreign key (instance_collection_reference_id) references instance_collection_reference;
alter table values_from_collection_mapping_references_ordered
    add constraint FKps8hyj2oqagd7q2a6w2dtx251 foreign key (values_from_collection_mapping_id) references values_from_collection_mapping;
alter table values_from_collection_mapping
    add constraint FKe99xh6knmllx5olj1rjpj5gcg foreign key (value_mapping_id) references value_mapping;
