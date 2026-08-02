package com.civichub.ai.pipeline.validator;

import com.civichub.ai.exception.ImageTooLargeException;
import com.civichub.ai.exception.InvalidImageException;
import com.civichub.ai.exception.UnsupportedImageFormatException;
import com.civichub.ai.pipeline.storage.StoredAIImage;
import java.nio.file.Files;
import java.util.Locale;
import java.util.Set;
import org.springframework.stereotype.Component;

@Component
public class DefaultAIImageValidator implements AIImageValidator {

    public static final long MAX_IMAGE_SIZE_BYTES = 5L * 1024L * 1024L;
    public static final Set<String> SUPPORTED_MIME_TYPES = Set.of("image/jpeg", "image/png", "image/webp");

    @Override
    public void validate(StoredAIImage image) {
        if (image == null || image.getPath() == null || !Files.exists(image.getPath())) {
            throw new InvalidImageException(AIImageValidationError.MISSING.name());
        }
        if (!Files.isReadable(image.getPath())) {
            throw new InvalidImageException(AIImageValidationError.NOT_READABLE.name());
        }
        if (image.getSizeBytes() <= 0) {
            throw new InvalidImageException(AIImageValidationError.EMPTY.name());
        }
        if (image.getSizeBytes() > MAX_IMAGE_SIZE_BYTES) {
            throw new ImageTooLargeException(MAX_IMAGE_SIZE_BYTES);
        }
        String mimeType = image.getMimeType();
        if (mimeType == null || !SUPPORTED_MIME_TYPES.contains(mimeType.toLowerCase(Locale.ROOT))) {
            throw new UnsupportedImageFormatException(mimeType == null ? "unknown" : mimeType);
        }
    }
}
