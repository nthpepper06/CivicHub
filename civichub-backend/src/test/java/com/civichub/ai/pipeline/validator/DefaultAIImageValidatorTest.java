package com.civichub.ai.pipeline.validator;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.exception.ImageTooLargeException;
import com.civichub.ai.exception.InvalidImageException;
import com.civichub.ai.exception.UnsupportedImageFormatException;
import com.civichub.ai.pipeline.storage.StoredAIImage;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class DefaultAIImageValidatorTest {

    private final DefaultAIImageValidator validator = new DefaultAIImageValidator();

    @TempDir
    Path tempDir;

    @Test
    void acceptsReadableSupportedNonEmptyImage() throws Exception {
        Path image = tempDir.resolve("street.png");
        Files.writeString(image, "image");

        validator.validate(StoredAIImage.builder()
                .path(image)
                .mimeType("image/png")
                .sizeBytes(Files.size(image))
                .build());
    }

    @Test
    void rejectsMissingImage() {
        assertThatThrownBy(() -> validator.validate(StoredAIImage.builder()
                        .path(tempDir.resolve("missing.png"))
                        .mimeType("image/png")
                        .sizeBytes(1)
                        .build()))
                .isInstanceOf(InvalidImageException.class)
                .hasMessage("MISSING");
    }

    @Test
    void rejectsEmptyImage() throws Exception {
        Path image = tempDir.resolve("empty.png");
        Files.createFile(image);

        assertThatThrownBy(() -> validator.validate(StoredAIImage.builder()
                        .path(image)
                        .mimeType("image/png")
                        .sizeBytes(0)
                        .build()))
                .isInstanceOf(InvalidImageException.class)
                .hasMessage("EMPTY");
    }

    @Test
    void rejectsUnsupportedFormat() throws Exception {
        Path image = tempDir.resolve("street.gif");
        Files.writeString(image, "image");

        assertThatThrownBy(() -> validator.validate(StoredAIImage.builder()
                        .path(image)
                        .mimeType("image/gif")
                        .sizeBytes(Files.size(image))
                        .build()))
                .isInstanceOf(UnsupportedImageFormatException.class);
    }

    @Test
    void rejectsOversizedImage() throws Exception {
        Path image = tempDir.resolve("large.png");
        Files.writeString(image, "image");

        assertThatThrownBy(() -> validator.validate(StoredAIImage.builder()
                        .path(image)
                        .mimeType("image/png")
                        .sizeBytes(DefaultAIImageValidator.MAX_IMAGE_SIZE_BYTES + 1)
                        .build()))
                .isInstanceOf(ImageTooLargeException.class);
    }
}
