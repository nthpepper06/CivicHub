package com.civichub.report.mapper;

import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.dto.response.ReportImageResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.entity.Report;
import com.civichub.report.entity.ReportImage;
import java.util.Comparator;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface ReportMapper {

    default ReportSummaryResponse toSummaryResponse(Report report) {
        return ReportSummaryResponse.builder()
                .id(report.getId())
                .title(report.getTitle())
                .address(report.getAddress())
                .status(report.getStatus())
                .categoryId(report.getCategory().getId())
                .categoryName(report.getCategory().getName())
                .departmentId(report.getDepartment() == null ? null : report.getDepartment().getId())
                .departmentName(report.getDepartment() == null ? null : report.getDepartment().getName())
                .citizenId(report.getUser().getId())
                .citizenName(report.getUser().getFullName())
                .primaryImageUrl(resolvePrimaryImageUrl(report))
                .createdAt(report.getCreatedAt())
                .updatedAt(report.getUpdatedAt())
                .build();
    }

    default ReportDetailResponse toDetailResponse(Report report) {
        return ReportDetailResponse.builder()
                .id(report.getId())
                .title(report.getTitle())
                .description(report.getDescription())
                .address(report.getAddress())
                .latitude(report.getLatitude())
                .longitude(report.getLongitude())
                .status(report.getStatus())
                .categoryId(report.getCategory().getId())
                .categoryName(report.getCategory().getName())
                .departmentId(report.getDepartment() == null ? null : report.getDepartment().getId())
                .departmentName(report.getDepartment() == null ? null : report.getDepartment().getName())
                .citizenId(report.getUser().getId())
                .citizenName(report.getUser().getFullName())
                .images(report.getImages()
                        .stream()
                        .sorted(Comparator.comparingInt(ReportImage::getDisplayOrder))
                        .map(this::toImageResponse)
                        .toList())
                .createdAt(report.getCreatedAt())
                .updatedAt(report.getUpdatedAt())
                .build();
    }

    default ReportImageResponse toImageResponse(ReportImage image) {
        return ReportImageResponse.builder()
                .id(image.getId())
                .url(image.getImageUrl())
                .displayOrder(image.getDisplayOrder())
                .build();
    }

    private String resolvePrimaryImageUrl(Report report) {
        return report.getImages()
                .stream()
                .min(Comparator.comparingInt(ReportImage::getDisplayOrder))
                .map(ReportImage::getImageUrl)
                .orElse(null);
    }
}
