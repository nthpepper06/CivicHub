package com.civichub.ai.pipeline.storage;

import com.civichub.ai.exception.StorageUnavailableException;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
@RequiredArgsConstructor
public class LocalAIImageStorage implements AIImageStorage {

    private static final String UPLOADS_PREFIX = "/uploads/";

    @Value("${app.upload.path:uploads}")
    private String uploadPath;

    private Path uploadRoot;

    @PostConstruct
    void init() {
        uploadRoot = Path.of(uploadPath).toAbsolutePath().normalize();
    }

    @Override
    public StoredAIImage resolve(String imageReference) {
        if (!StringUtils.hasText(imageReference)) {
            throw new StorageUnavailableException("Image reference is required");
        }
        Path imagePath = resolvePath(imageReference);
        if (!imagePath.startsWith(uploadRoot)) {
            throw new StorageUnavailableException("Image reference is outside configured upload storage");
        }
        try {
            return StoredAIImage.builder()
                    .reference(imageReference)
                    .path(imagePath)
                    .mimeType(Files.probeContentType(imagePath))
                    .sizeBytes(Files.exists(imagePath) ? Files.size(imagePath) : 0L)
                    .build();
        } catch (IOException exception) {
            throw new StorageUnavailableException("Unable to inspect image storage");
        }
    }

    private Path resolvePath(String imageReference) {
        String normalizedReference = stripQuery(imageReference.trim());
        try {
            URI uri = new URI(normalizedReference);
            if (uri.getScheme() != null && uri.getPath() != null) {
                normalizedReference = uri.getPath();
            }
        } catch (URISyntaxException ignored) {
            // Treat malformed URI values as plain paths and validate them against uploadRoot below.
        }
        if (normalizedReference.startsWith(UPLOADS_PREFIX)) {
            normalizedReference = normalizedReference.substring(UPLOADS_PREFIX.length());
        }
        Path candidate = Path.of(normalizedReference);
        if (!candidate.isAbsolute()) {
            candidate = uploadRoot.resolve(candidate);
        }
        return candidate.toAbsolutePath().normalize();
    }

    private String stripQuery(String value) {
        int queryIndex = value.indexOf('?');
        return queryIndex >= 0 ? value.substring(0, queryIndex) : value;
    }
}
