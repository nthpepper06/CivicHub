package com.civichub.ai.pipeline.storage;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.exception.StorageUnavailableException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.test.util.ReflectionTestUtils;

class LocalAIImageStorageTest {

    private final LocalAIImageStorage storage = new LocalAIImageStorage();

    @TempDir
    Path tempDir;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(storage, "uploadPath", tempDir.toString());
        ReflectionTestUtils.invokeMethod(storage, "init");
    }

    @Test
    void resolvesExistingUploadUrlToLocalStorage() throws Exception {
        Path image = tempDir.resolve("report-images").resolve("street.png");
        Files.createDirectories(image.getParent());
        Files.writeString(image, "image");

        StoredAIImage resolved = storage.resolve("http://localhost:8080/uploads/report-images/street.png");

        assertThat(resolved.getPath()).isEqualTo(image.toAbsolutePath().normalize());
        assertThat(resolved.getReference()).isEqualTo("http://localhost:8080/uploads/report-images/street.png");
        assertThat(resolved.getSizeBytes()).isEqualTo(Files.size(image));
    }

    @Test
    void rejectsPathTraversalOutsideUploadRoot() {
        assertThatThrownBy(() -> storage.resolve("/uploads/../secret.png"))
                .isInstanceOf(StorageUnavailableException.class)
                .hasMessageContaining("outside configured upload storage");
    }
}
