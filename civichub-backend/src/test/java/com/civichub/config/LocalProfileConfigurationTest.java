package com.civichub.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class LocalProfileConfigurationTest {

    @Test
    void localProfileShouldEnableHibernateUpdateWithoutDatabasePassword() throws IOException {
        Path localProfile = Path.of("src/main/resources/application-local.yml");

        assertThat(localProfile).exists();
        String content = Files.readString(localProfile);

        assertThat(content).contains("ddl-auto: update");
        assertThat(content.toLowerCase()).doesNotContain("password");
    }
}
