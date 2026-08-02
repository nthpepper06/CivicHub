package com.civichub.report.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.common.exception.InvalidReportStateException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

class ReportImageUploadServiceImplTest {

    @TempDir
    Path tempDir;

    @Test
    void uploadsValidImageAndReturnsPublicUrl() throws Exception {
        ReportImageUploadServiceImpl service = service();
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setScheme("http");
        request.setServerName("localhost");
        request.setServerPort(8080);
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
        MockMultipartFile image = new MockMultipartFile("file", "street.png", "image/png", "image".getBytes());

        var response = service.upload(image);

        assertThat(response.getUrl()).startsWith("http://localhost:8080/uploads/report-images/");
        assertThat(response.getContentType()).isEqualTo("image/png");
        assertThat(Files.list(tempDir.resolve("report-images")).count()).isEqualTo(1);
        RequestContextHolder.resetRequestAttributes();
    }

    @Test
    void rejectsEmptyUpload() throws Exception {
        ReportImageUploadServiceImpl service = service();
        MockMultipartFile image = new MockMultipartFile("file", "street.png", "image/png", new byte[0]);

        assertThatThrownBy(() -> service.upload(image))
                .isInstanceOf(InvalidReportStateException.class)
                .hasMessage("Image file is required");
    }

    @Test
    void rejectsUnsupportedContentType() throws Exception {
        ReportImageUploadServiceImpl service = service();
        MockMultipartFile image = new MockMultipartFile("file", "street.gif", "image/gif", "image".getBytes());

        assertThatThrownBy(() -> service.upload(image))
                .isInstanceOf(InvalidReportStateException.class)
                .hasMessage("Only JPEG, PNG, or WebP images are supported");
    }

    private ReportImageUploadServiceImpl service() throws Exception {
        ReportImageUploadServiceImpl service = new ReportImageUploadServiceImpl();
        ReflectionTestUtils.setField(service, "uploadPath", tempDir.toString());
        service.init();
        return service;
    }
}
