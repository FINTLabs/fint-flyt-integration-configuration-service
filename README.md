# FINT Flyt Integration Configuration Service

Spring Boot-tjeneste som skal samle katalogdomenet i FINT Flyt — integration, configuration,
value converting og discovery — i én utrullbar enhet, og erstatte de fire tjenestene som eier
disse domenene i dag.

Persistenslaget står, men ingen domenelogikk er flyttet inn ennå.

## Pakkestruktur

Ett Gradle-modul med én pakke per domene under `no.novari.flyt.catalog`:

| Pakke                                    | Erstatter                          |
|------------------------------------------|------------------------------------|
| `no.novari.flyt.catalog.configuration`   | fint-flyt-configuration-service    |
| `no.novari.flyt.catalog.integration`     | fint-flyt-integration-service      |
| `no.novari.flyt.catalog.valueconverting` | fint-flyt-value-converting-service |
| `no.novari.flyt.catalog.discovery`       | fint-flyt-discovery-service        |

Pakkeskillet er et krav, ikke en preferanse: tjenesten beholder de fire eksisterende
databaseskjemaene, og trenger derfor én persistence unit per skjema. `@EnableJpaRepositories`
velger repositories per pakke, så hvert domene må ligge i sin egen pakke.

## Persistering

Tjenesten migrerer ikke data. Hvert domene beholder skjemaet den gamle tjenesten eier, i samme
`fint-flyt`-database per tenant. Fire persistence units er påkrevd fordi `configuration_aud` og
`value_converting_aud` hver har en ekte fremmednøkkel til en `revinfo`-tabell i sitt eget skjema,
og Envers tillater kun én revisjonsentitet per persistence unit.

Hvert domene har derfor sin egen `DataSource`, `EntityManagerFactory`, `PlatformTransactionManager`
og `Flyway`, satt opp i `<Domene>PersistenceConfig` i domenepakken. Configuration er merket
`@Primary` — uten en primærkandidat feiler Spring Boots autokonfigurasjon på flertydighet.
Kun configuration og valueconverting registrerer revisjonsentiteten fra `flyt-audit-starter`, slik
at hver av dem løser `revinfo` mot sitt eget skjema.

### Skjemanavn

Skjemanavnene hører hjemme i konfigurasjon, ikke i kode: hver `DataSource` setter `hikari.schema`,
og entitetene har ingen `@Table(schema = ...)`.

Alle fem skjemaene deler tenant-prefiks, så prefikset utledes fra databasebrukeren flaiserator
setter, ved å fjerne tjenestens eget skjemanavn fra den. Utrullingen trenger dermed ingen
per-tenant-konfigurasjon utover det overlayene allerede setter. `novari.flyt.catalog.database.schema-prefix`
overstyrer utledningen — tom streng gir uprefiksede skjemanavn, som er det lokal utvikling og
testene bruker.

### Flyway

Migreringene fra de fire gamle tjenestene ligger under hver sin katalog i
`src/main/resources/db/migration/`, med én `Flyway`-bønne per skjema. Hvert skjema har allerede sin
egen `flyway_schema_history`, så versjonsnumrene kolliderer ikke selv om alle fire har en `V1__init.sql`.

**`.sql`-filene er kopiert byte-for-byte og må aldri reformateres.** Flyway beregner checksum på
filinnhold, så et enkelt linjeskift gir checksum-avvik og stopper oppstart. `.editorconfig` slår
derfor av `insert_final_newline` og `trim_trailing_whitespace` for katalogen.

I drift er alle migreringene allerede kjørt, så Flyway gjør ikke annet enn å validere. Det er
nettopp verdien: applikasjonen verifiserer ved oppstart at den snakker med det skjemaet den tror.

## Kafka

Det er bevisst ingen Kafka-konfigurasjon i dette repoet, og ingen i kustomize-basen.
Topic-konfigurasjon opprettes og endres når konsument-bønnene bygges, altså ved oppstart — ikke
ved cutover. En tjeneste som deployes med Kafka aktivert før et domene er migrert, ville derfor
kunne endre topics som fortsatt eies av de gamle tjenestene. Kafka legges til per domenesteg,
sammen med domenet som trenger det.

## Kjøre lokalt

Forutsetninger:

- Java 25
- Docker (for Docker Compose og for Testcontainers i testene)

```shell
docker compose up -d                                    # PostgreSQL på localhost:5441
./gradlew check                                         # ktlint + tester
SPRING_PROFILES_ACTIVE=local-staging ./gradlew bootRun  # kjører på port 8095
```

## Utrulling

- `kustomize/base/` — `Application`-ressursen for fint-flyt-intgr-conf-service.
- `kustomize/overlays/<org>/<env>/` — genereres per tenant og miljø.
- `kustomize/templates/overlay.yaml.tpl` — envsubst-malen alle overlays rendres fra.

Regenerer overlays etter endringer i malen:

```shell
./scripts/render-overlay.sh
```

Applikasjonsnavnet gir databasebrukeren, og dermed skjemaet, navnet sitt: flaiserator oppretter
én `PGUser` per applikasjon, og skjemaet følger mønsteret `{tenant}_{applikasjonsnavn}_db` i databasen `fint-flyt`.
