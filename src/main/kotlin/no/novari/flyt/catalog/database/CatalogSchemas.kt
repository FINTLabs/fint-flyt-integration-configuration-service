package no.novari.flyt.catalog.database

class CatalogSchemas(
    schemaPrefix: String,
) {
    val integration = schemaPrefix + "fint_flyt_integration_service_db"
    val configuration = schemaPrefix + "fint_flyt_configuration_service_db"
    val valueConverting = schemaPrefix + "fint_flyt_value_converting_service_db"
    val discovery = schemaPrefix + "fint_flyt_discovery_service_db"

    companion object {
        const val OWN_SCHEMA = "fint_flyt_intgr_conf_service_db"

        /**
         * Flaiserator navngir skjemaet likt databasebrukeren, etter mønsteret `{tenant}_{applikasjonsnavn}_db`.
         * De fire gamle skjemaene deler dermed tenant-prefiks med tjenestens eget, og utrullingen trenger ingen
         * per-tenant-konfigurasjon utover det overlayene allerede setter.
         */
        fun schemaPrefixFrom(databaseUsername: String?): String {
            require(databaseUsername != null && databaseUsername.endsWith(OWN_SCHEMA)) {
                "Kan ikke utlede skjemaprefiks: databasebrukeren '$databaseUsername' slutter ikke på '$OWN_SCHEMA'. " +
                    "Sett novari.flyt.catalog.database.schema-prefix eksplisitt."
            }
            return databaseUsername.removeSuffix(OWN_SCHEMA)
        }
    }
}
