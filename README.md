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
og `Flyway`, satt opp i `<Domene>PersistenceConfig` i domenepakken. De fire er likestilte — ingen av
dem er primærkandidat. Kun configuration og valueconverting registrerer revisjonsentiteten fra
`flyt-audit-starter`, slik at hver av dem løser `revinfo` mot sitt eget skjema.

### Primærkandidaten er tjenestens eget skjema

Spring Boots autokonfigurasjon krever én `@Primary` `DataSource` og `EntityManagerFactory`.
Den rollen har `OwnSchemaPersistenceConfig`, som peker på tjenestens eget skjema — det pgerator
oppretter etter applikasjonsnavnet. Skjemaet er tomt og ubrukt, og persistence uniten har ingen
entiteter.

At det er tomt er poenget. En `@Transactional`, en `EntityManager` eller et repository som glemmer
sin qualifier faller tilbake på primærkandidaten. Peker den på et domeneskjema, leser eller skriver
feilen stille mot ekte data; peker den på det tomme skjemaet, feiler den på manglende tabell med én
gang. Valget gjør også de fire domenene symmetriske, framfor at ett av dem er privilegert av en
vilkårlig grunn.

Skulle katalogen senere få tabeller som deles av alle domenene — eller de fire skjemaene bli
konsolidert — er det dette skjemaet de hører hjemme i, og primærkandidaten peker allerede dit.

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

I drift er alle migreringene allerede kjørt, så Flyway gjør ikke annet enn å validere mot
historikken de gamle tjenestene skrev. Det er nettopp verdien: applikasjonen verifiserer ved
oppstart at den snakker med det skjemaet den tror.

**`.sql`-filene er kopiert byte-for-byte og må aldri endres.** Flyway sammenligner `script` og
`checksum` mot radene som allerede står i `flyway_schema_history`; avviker de, stopper oppstarten.

Checksummen beregnes linje for linje over filinnholdet. Linjeskift, final newline og blanke linjer
påvirker den derfor ikke, men **trailing whitespace gjør det** — og det er nettopp den slags endring
en editor gjør uoppfordret. `.editorconfig` slår av `trim_trailing_whitespace` for katalogen, og
`insert_final_newline` i tillegg, slik at filene forblir byte-identiske med originalene.

`src/test/resources/legacy-flyway-checksums.txt` holder checksummene hentet fra de gamle repoene, og
en test sammenligner filene mot dem. Endres en migrering, feiler CI med filnavn og begge verdiene.
Den filen skal ikke oppdateres for å få testen grønn — da er invarianten brutt, og migreringen skal
tilbakestilles.

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

`docker-compose.yaml` monterer `scripts/local-postgres-init.sql`, som oppretter tjenestens eget
skjema slik pgerator gjør i drift. Skriptet kjører bare når datavolumet er tomt — har du et volum
fra før, trengs `docker compose down -v` én gang.

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
