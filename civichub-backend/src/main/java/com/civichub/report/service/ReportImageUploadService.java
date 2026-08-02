package com.civichub.report.service;

import com.civichub.report.dto.response.ReportImageUploadResponse;
import org.springframework.web.multipart.MultipartFile;

public interface ReportImageUploadService {

    ReportImageUploadResponse upload(MultipartFile file);
}
