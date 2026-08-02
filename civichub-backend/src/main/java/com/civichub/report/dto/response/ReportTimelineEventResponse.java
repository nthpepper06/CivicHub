package com.civichub.report.dto.response;

import com.civichub.common.enums.ReportTimelineEventType;
import com.civichub.common.enums.UserRole;
import java.time.LocalDateTime;
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
public class ReportTimelineEventResponse {

    private Long id;
    private ReportTimelineEventType type;
    private String title;
    private String description;
    private UserRole actorRole;
    private String actorName;
    private LocalDateTime createdAt;
}
