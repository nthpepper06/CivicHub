package com.civichub.report.service;

import com.civichub.common.exception.InvalidReportStateException;
import com.civichub.report.dto.response.ReportImageUploadResponse;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@Service
@RequiredArgsConstructor
public class ReportImageUploadServiceImpl implements ReportImageUploadService {

    private static final long MAX_IMAGE_SIZE_BYTES = 5L * 1024L * 1024L;
    private static final String REPORT_IMAGE_FOLDER = "report-images";
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of("image/jpeg", "image/png", "image/webp");

    @Value("${app.upload.path:uploads}")
    private String uploadPath;

    private Path reportImagePath;

    @PostConstruct
    void init() throws IOException {
        reportImagePath = Path.of(uploadPath).toAbsolutePath().normalize().resolve(REPORT_IMAGE_FOLDER);
        Files.createDirectories(reportImagePath);
    }

    @Override
    public ReportImageUploadResponse upload(MultipartFile file) {
        validate(file);
        String contentType = file.getContentType();
        String fileName = "%s.%s".formatted(UUID.randomUUID(), extension(file));
        Path target = reportImagePath.resolve(fileName).normalize();
        if (!target.startsWith(reportImagePath)) {
            throw new InvalidReportStateException("Invalid image file name");
        }
        try {
            file.transferTo(target);
        } catch (IOException exception) {
            throw new InvalidReportStateException("Image upload failed");
        }

        String url = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/uploads/report-images/")
                .path(fileName)
                .toUriString();
        return ReportImageUploadResponse.builder()
                .url(url)
                .fileName(fileName)
                .contentType(contentType)
                .size(file.getSize())
                .build();
    }

    private void validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new InvalidReportStateException("Image file is required");
        }
        if (file.getSize() > MAX_IMAGE_SIZE_BYTES) {
            throw new InvalidReportStateException("Image file must be 5 MB or smaller");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType.toLowerCase(Locale.ROOT))) {
            throw new InvalidReportStateException("Only JPEG, PNG, or WebP images are supported");
        }
    }

    private String extension(MultipartFile file) {
        String contentType = file.getContentType();
        if ("image/png".equalsIgnoreCase(contentType)) {
            return "png";
        }
        if ("image/webp".equalsIgnoreCase(contentType)) {
            return "webp";
        }
        String original = StringUtils.cleanPath(file.getOriginalFilename() == null ? "" : file.getOriginalFilename());
        String extension = StringUtils.getFilenameExtension(original);
        return extension == null || extension.isBlank() ? "jpg" : extension.toLowerCase(Locale.ROOT);
    }
}
