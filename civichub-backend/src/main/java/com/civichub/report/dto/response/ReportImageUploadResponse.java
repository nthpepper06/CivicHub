package com.civichub.report.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReportImageUploadResponse {

    private String url;
    private String fileName;
    private String contentType;
    private long size;
}
