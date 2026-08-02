package com.civichub.report.repository;

import com.civichub.report.entity.ReportResolution;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportResolutionRepository extends JpaRepository<ReportResolution, Long> {

    @EntityGraph(attributePaths = {"images", "resolvedBy"})
    Optional<ReportResolution> findByReportId(Long reportId);
}
