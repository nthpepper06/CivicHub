package com.civichub.report.repository;

import com.civichub.report.entity.ReportTimelineEvent;
import java.util.List;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportTimelineEventRepository extends JpaRepository<ReportTimelineEvent, Long> {

    @EntityGraph(attributePaths = {"actor"})
    List<ReportTimelineEvent> findByReportIdOrderByCreatedAtAscIdAsc(Long reportId);
}
