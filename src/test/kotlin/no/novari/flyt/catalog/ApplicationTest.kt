package no.novari.flyt.catalog

import jakarta.persistence.EntityManagerFactory
import no.novari.flyt.catalog.database.CatalogSchemas
import org.assertj.core.api.Assertions.assertThat
import org.flywaydb.core.Flyway
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.ApplicationContext
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import org.springframework.test.context.TestPropertySource
import org.springframework.transaction.PlatformTransactionManager
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import java.sql.DriverManager
import javax.sql.DataSource

@SpringBootTest
@Testcontainers
@TestPropertySource(
    properties = [
        // Testcontainers-brukeren følger ikke {tenant}_{applikasjonsnavn}_db, så prefikset kan ikke utledes.
        "novari.flyt.catalog.database.schema-prefix=",
    ],
)
class ApplicationTest {
    @Autowired
    lateinit var context: ApplicationContext

    @Autowired
    lateinit var schemas: CatalogSchemas

    @ParameterizedTest
    @CsvSource(
        "ownSchemaDataSource,       own",
        "integrationDataSource,     integration",
        "configurationDataSource,   configuration",
        "valueConvertingDataSource, valueConverting",
        "discoveryDataSource,       discovery",
    )
    fun `each data source connects to its own schema`(
        beanName: String,
        schemaProperty: String,
    ) {
        context.getBean(beanName, DataSource::class.java).connection.use { connection ->
            assertThat(connection.isValid(1)).isTrue()
            assertThat(connection.schema).isEqualTo(schemaOf(schemaProperty))
        }
    }

    @ParameterizedTest
    @CsvSource(
        "integrationFlyway,     integration,     2",
        "configurationFlyway,   configuration,   6",
        "valueConvertingFlyway, valueConverting, 5",
        "discoveryFlyway,       discovery,       2",
    )
    fun `each flyway configuration validates its own schema without checksum mismatches`(
        beanName: String,
        schemaProperty: String,
        expectedMigrations: Int,
    ) {
        val flyway = context.getBean(beanName, Flyway::class.java)

        assertThat(flyway.validateWithResult().validationSuccessful).isTrue()
        assertThat(flyway.info().pending()).isEmpty()
        // Flyway skriver også en versjonsløs rad for skjemaopprettelsen.
        assertThat(flyway.info().applied().mapNotNull { it.version?.version })
            .hasSize(expectedMigrations)
        assertThat(flyway.configuration.schemas).containsExactly(schemaOf(schemaProperty))
        // flyway_schema_history.script er filnavnet, ikke stien. Det er det som gjør at radene de
        // gamle tjenestene skrev fortsatt matcher etter at filene flyttet til hver sin katalog.
        assertThat(flyway.info().applied().mapNotNull { it.script }).noneMatch { it.contains("/") }
    }

    @Test
    fun `only the two envers-audited persistence units register the revision entity`() {
        assertThat(entityNamesOf("configurationEntityManagerFactory")).contains(REVISION_ENTITY)
        assertThat(entityNamesOf("valueConvertingEntityManagerFactory")).contains(REVISION_ENTITY)
        assertThat(entityNamesOf("integrationEntityManagerFactory")).doesNotContain(REVISION_ENTITY)
        assertThat(entityNamesOf("discoveryEntityManagerFactory")).doesNotContain(REVISION_ENTITY)
    }

    @Test
    fun `the service's own empty schema is the primary persistence unit`() {
        assertThat(context.getBean(DataSource::class.java))
            .isSameAs(context.getBean("ownSchemaDataSource"))
        assertThat(context.getBean(EntityManagerFactory::class.java))
            .isSameAs(context.getBean("ownSchemaEntityManagerFactory"))
        assertThat(context.getBean(PlatformTransactionManager::class.java))
            .isSameAs(context.getBean("ownSchemaTransactionManager"))
    }

    @Test
    fun `the primary persistence unit has no entities, so an unqualified write cannot reach domain data`() {
        assertThat(entityNamesOf("ownSchemaEntityManagerFactory")).isEmpty()
    }

    @Test
    fun `each envers-audited schema has its own revinfo sequence`() {
        listOf(schemas.configuration, schemas.valueConverting).forEach { schema ->
            context.getBean("configurationDataSource", DataSource::class.java).connection.use { connection ->
                connection
                    .prepareStatement(
                        "SELECT count(*) FROM information_schema.sequences WHERE sequence_schema = ? AND sequence_name = 'revinfo_seq'",
                    ).use { statement ->
                        statement.setString(1, schema)
                        statement.executeQuery().use { rows ->
                            rows.next()
                            assertThat(rows.getInt(1)).describedAs("revinfo_seq i %s", schema).isEqualTo(1)
                        }
                    }
            }
        }
    }

    private fun schemaOf(property: String): String =
        when (property) {
            "own" -> schemas.own
            "integration" -> schemas.integration
            "configuration" -> schemas.configuration
            "valueConverting" -> schemas.valueConverting
            "discovery" -> schemas.discovery
            else -> error("Ukjent skjema: $property")
        }

    private fun entityNamesOf(beanName: String): List<String> =
        context
            .getBean(beanName, EntityManagerFactory::class.java)
            .metamodel.entities
            .map { it.name }

    companion object {
        private const val REVISION_ENTITY = "ActorRevisionEntity"

        @Container
        @JvmStatic
        val postgres: PostgreSQLContainer<*> = PostgreSQLContainer("postgres:17-alpine")

        // I drift oppretter pgerator dette skjemaet sammen med databasebrukeren. Ingen Flyway-konfigurasjon
        // eier det, så testen må opprette det selv for å speile oppsettet appen møter.
        @BeforeAll
        @JvmStatic
        fun createOwnSchema() {
            DriverManager.getConnection(postgres.jdbcUrl, postgres.username, postgres.password).use { connection ->
                connection.createStatement().use {
                    it.execute("CREATE SCHEMA IF NOT EXISTS ${CatalogSchemas.OWN_SCHEMA}")
                }
            }
        }

        // @ServiceConnection bidrar med en JdbcConnectionDetails-bønne, ikke spring.datasource.*,
        // og de fire datakildene bygges fra DataSourceProperties.
        @DynamicPropertySource
        @JvmStatic
        fun datasourceProperties(registry: DynamicPropertyRegistry) {
            registry.add("spring.datasource.url", postgres::getJdbcUrl)
            registry.add("spring.datasource.username", postgres::getUsername)
            registry.add("spring.datasource.password", postgres::getPassword)
        }
    }
}
