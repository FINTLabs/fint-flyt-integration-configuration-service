package no.novari.flyt.catalog.database

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties("novari.flyt.catalog.database")
class CatalogDatabaseProperties {
    /** Utledes fra databasebrukernavnet når den ikke er satt. Tom streng gir uprefiksede skjemanavn. */
    var schemaPrefix: String? = null
}
