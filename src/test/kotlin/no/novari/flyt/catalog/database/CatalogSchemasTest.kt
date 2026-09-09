package no.novari.flyt.catalog.database

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource
import org.junit.jupiter.params.provider.NullSource
import org.junit.jupiter.params.provider.ValueSource

class CatalogSchemasTest {
    @ParameterizedTest
    @CsvSource(
        "afk_no_fint_flyt_intgr_conf_service_db, afk_no_",
        "bym_oslo_kommune_no_fint_flyt_intgr_conf_service_db, bym_oslo_kommune_no_",
        "fint_flyt_intgr_conf_service_db, ''",
    )
    fun `the schema prefix is the database username without the service's own schema name`(
        username: String,
        expectedPrefix: String,
    ) {
        assertThat(CatalogSchemas.schemaPrefixFrom(username)).isEqualTo(expectedPrefix)
    }

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = ["postgres", "afk_no_fint_flyt_configuration_service_db", ""])
    fun `a username that does not match the pattern fails with a message naming the escape hatch`(username: String?) {
        assertThatThrownBy { CatalogSchemas.schemaPrefixFrom(username) }
            .isInstanceOf(IllegalArgumentException::class.java)
            .hasMessageContaining("novari.flyt.catalog.database.schema-prefix")
    }

    @Test
    fun `the four schema names carry the tenant prefix of the old services`() {
        val schemas = CatalogSchemas("afk_no_")

        assertThat(schemas.integration).isEqualTo("afk_no_fint_flyt_integration_service_db")
        assertThat(schemas.configuration).isEqualTo("afk_no_fint_flyt_configuration_service_db")
        assertThat(schemas.valueConverting).isEqualTo("afk_no_fint_flyt_value_converting_service_db")
        assertThat(schemas.discovery).isEqualTo("afk_no_fint_flyt_discovery_service_db")
    }
}
