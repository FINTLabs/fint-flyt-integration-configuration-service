create table instance_metadata_category
(
    id           bigserial not null,
    display_name varchar(255),
    content_id   int8,
    primary key (id)
);
create table instance_metadata_content
(
    id bigserial not null,
    primary key (id)
);
create table instance_metadata_content_categories
(
    instance_metadata_content_id int8 not null,
    categories_id                int8 not null
);
create table instance_metadata_content_instance_object_collection_metadata
(
    instance_metadata_content_id           int8 not null,
    instance_object_collection_metadata_id int8 not null
);
create table instance_metadata_content_instance_value_metadata
(
    instance_metadata_content_id int8 not null,
    instance_value_metadata_id   int8 not null
);
create table instance_object_collection_metadata
(
    id                 bigserial not null,
    display_name       varchar(255),
    "key"              varchar(255),
    object_metadata_id int8,
    primary key (id)
);
create table instance_value_metadata
(
    id           bigserial not null,
    display_name varchar(255),
    "key"        varchar(255),
    type         varchar(255),
    primary key (id)
);
create table integration_metadata
(
    id                                 bigserial    not null,
    integration_display_name           varchar(255) not null,
    source_application_id              int8         not null,
    source_application_integration_id  varchar(255) not null,
    source_application_integration_uri varchar(255),
    version                            int8         not null,
    instance_metadata_id               int8,
    primary key (id)
);
alter table instance_metadata_content_categories
    add constraint UK_kxomjfb82qvgtepnhk6k99i76 unique (categories_id);
alter table instance_metadata_content_instance_object_collection_metadata
    add constraint UK_tdq2ytc061u2quaxydqv5ggg1 unique (instance_object_collection_metadata_id);
alter table instance_metadata_content_instance_value_metadata
    add constraint UK_hmdlf3jn42rfwpiiq4s649325 unique (instance_value_metadata_id);
alter table integration_metadata
    add constraint UniqueSourceApplicationIdAndSourceApplicationIntegrationIdAndVersion unique (source_application_id, source_application_integration_id, version);
alter table instance_metadata_category
    add constraint FKj3ksu4am4tqsa9uw6xxd78aom foreign key (content_id) references instance_metadata_content;
alter table instance_metadata_content_categories
    add constraint FKt4ooeapuxm6qkuk4cn69hllww foreign key (categories_id) references instance_metadata_category;
alter table instance_metadata_content_categories
    add constraint FKas40p5vwnta3uh9dg5cqg47i foreign key (instance_metadata_content_id) references instance_metadata_content;
alter table instance_metadata_content_instance_object_collection_metadata
    add constraint FK9w7hpcykrcwq3nnv6kanaqat5 foreign key (instance_object_collection_metadata_id) references instance_object_collection_metadata;
alter table instance_metadata_content_instance_object_collection_metadata
    add constraint FK9wf9tfotueqifrak5rvxxjj5l foreign key (instance_metadata_content_id) references instance_metadata_content;
alter table instance_metadata_content_instance_value_metadata
    add constraint FKsajrvh1pvdi8m6oujtid9deix foreign key (instance_value_metadata_id) references instance_value_metadata;
alter table instance_metadata_content_instance_value_metadata
    add constraint FK3r8mqupexypww7lam0n29d6uu foreign key (instance_metadata_content_id) references instance_metadata_content;
alter table instance_object_collection_metadata
    add constraint FKlas89mvhhf87llvl0l6cjrtam foreign key (object_metadata_id) references instance_metadata_content;
alter table integration_metadata
    add constraint FKhcjnj4xmiphqe9scflkdp6eod foreign key (instance_metadata_id) references instance_metadata_content;
