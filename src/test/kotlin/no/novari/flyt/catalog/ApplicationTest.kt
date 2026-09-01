package no.novari.flyt.catalog

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.testcontainers.service.connection.ServiceConnection
import org.springframework.test.context.TestPropertySource
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import javax.sql.DataSource

@SpringBootTest
@Testcontainers
@TestPropertySource(
    properties = [
        // application-flyt-postgres binder hikari-skjemaet til fint.database.username, som ikke finnes her
        "spring.datasource.hikari.schema=public",
    ],
)
class ApplicationTest {
    @Autowired
    lateinit var dataSource: DataSource

    @Test
    fun `the application context starts and the datasource connects`() {
        dataSource.connection.use { connection ->
            assertThat(connection.isValid(1)).isTrue()
            assertThat(connection.schema).isEqualTo("public")
        }
    }

    companion object {
        @Container
        @ServiceConnection
        @JvmStatic
        val postgres: PostgreSQLContainer<*> = PostgreSQLContainer("postgres:17-alpine")
    }
}
