# FINT Flyt Integration Configuration Service

Spring Boot-tjeneste som skal samle katalogdomenet i FINT Flyt — integration, configuration,
value converting og discovery — i én utrullbar enhet, og erstatte de fire tjenestene som eier
disse domenene i dag.

Repoet inneholder foreløpig bare skjelettet: ingen domenelogikk er flyttet inn ennå.

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

Inntil persistence unitene er satt opp, kobler tjenesten seg bare til sitt eget skjema — nok til
å bekrefte at databasesecreten virker.

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
