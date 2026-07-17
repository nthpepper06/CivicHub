package com.civichub.report.repository;

import com.civichub.report.entity.Report;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReportRepository extends JpaRepository<Report, Long>, JpaSpecificationExecutor<Report> {

    @Override
    @EntityGraph(attributePaths = {"category", "department", "user"})
    Page<Report> findAll(Specification<Report> specification, Pageable pageable);

    Optional<Report> findByIdAndUserId(Long reportId, Long userId);

    Optional<Report> findByIdAndDepartmentId(Long reportId, Long departmentId);

    @EntityGraph(attributePaths = {"category", "department", "user", "images"})
    @Query("select r from Report r where r.id = :id")
    Optional<Report> findDetailById(@Param("id") Long id);

    @EntityGraph(attributePaths = {"category", "department", "user", "images"})
    @Query("select r from Report r where r.id = :reportId and r.user.id = :userId")
    Optional<Report> findDetailByIdAndUserId(@Param("reportId") Long reportId, @Param("userId") Long userId);

    @EntityGraph(attributePaths = {"category", "department", "user", "images"})
    @Query("select r from Report r where r.id = :reportId and r.department.id = :departmentId")
    Optional<Report> findDetailByIdAndDepartmentId(
            @Param("reportId") Long reportId,
            @Param("departmentId") Long departmentId);
}
