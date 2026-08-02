package com.civichub.report.repository;

import com.civichub.report.entity.ReportRating;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportRatingRepository extends JpaRepository<ReportRating, Long> {

    Optional<ReportRating> findByReportId(Long reportId);
}
