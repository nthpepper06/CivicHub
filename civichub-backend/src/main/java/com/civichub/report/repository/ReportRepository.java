package com.civichub.report.repository;

import com.civichub.dashboard.dto.response.CategoryStatisticResponse;
import com.civichub.dashboard.dto.response.DepartmentStatisticResponse;
import com.civichub.dashboard.dto.response.MonthlyStatisticResponse;
import com.civichub.dashboard.dto.response.ReportStatusStatisticResponse;
import com.civichub.dashboard.dto.response.StaffDashboardSummaryResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.entity.Report;
import java.util.List;
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

    @Query("""
            select new com.civichub.dashboard.dto.response.ReportStatusStatisticResponse(
                count(r),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.PENDING then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.RECEIVED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.IN_PROGRESS then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.RESOLVED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.REJECTED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.CANCELLED then 1 else 0 end), 0)
            )
            from Report r
            where r.createdAt >= :createdFrom
              and r.createdAt <= :createdTo
            """)
    ReportStatusStatisticResponse countReportsByStatus(
            @Param("createdFrom") java.time.LocalDateTime createdFrom,
            @Param("createdTo") java.time.LocalDateTime createdTo);

    @Query("""
            select new com.civichub.dashboard.dto.response.ReportStatusStatisticResponse(
                count(r),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.PENDING then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.RECEIVED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.IN_PROGRESS then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.RESOLVED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.REJECTED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.CANCELLED then 1 else 0 end), 0)
            )
            from Report r
            """)
    ReportStatusStatisticResponse countReportsByStatus();

    @Query("""
            select new com.civichub.dashboard.dto.response.CategoryStatisticResponse(
                c.id,
                c.name,
                count(r)
            )
            from Report r
            join r.category c
            where r.createdAt >= :createdFrom
              and r.createdAt <= :createdTo
            group by c.id, c.name
            order by count(r) desc, c.name asc
            """)
    List<CategoryStatisticResponse> countReportsByCategory(
            @Param("createdFrom") java.time.LocalDateTime createdFrom,
            @Param("createdTo") java.time.LocalDateTime createdTo);

    @Query("""
            select new com.civichub.dashboard.dto.response.CategoryStatisticResponse(
                c.id,
                c.name,
                count(r)
            )
            from Report r
            join r.category c
            group by c.id, c.name
            order by count(r) desc, c.name asc
            """)
    List<CategoryStatisticResponse> countReportsByCategory();

    @Query("""
            select new com.civichub.dashboard.dto.response.DepartmentStatisticResponse(
                d.id,
                d.name,
                count(r)
            )
            from Report r
            join r.department d
            where r.createdAt >= :createdFrom
              and r.createdAt <= :createdTo
            group by d.id, d.name
            order by count(r) desc, d.name asc
            """)
    List<DepartmentStatisticResponse> countReportsByDepartment(
            @Param("createdFrom") java.time.LocalDateTime createdFrom,
            @Param("createdTo") java.time.LocalDateTime createdTo);

    @Query("""
            select new com.civichub.dashboard.dto.response.DepartmentStatisticResponse(
                d.id,
                d.name,
                count(r)
            )
            from Report r
            join r.department d
            group by d.id, d.name
            order by count(r) desc, d.name asc
            """)
    List<DepartmentStatisticResponse> countReportsByDepartment();

    @Query("""
            select new com.civichub.dashboard.dto.response.MonthlyStatisticResponse(
                extract(month from r.createdAt),
                count(r),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.RESOLVED then 1 else 0 end), 0)
            )
            from Report r
            where extract(year from r.createdAt) = :year
              and r.createdAt >= :createdFrom
              and r.createdAt <= :createdTo
            group by extract(month from r.createdAt)
            order by extract(month from r.createdAt) asc
            """)
    List<MonthlyStatisticResponse> countReportsByMonth(
            @Param("year") int year,
            @Param("createdFrom") java.time.LocalDateTime createdFrom,
            @Param("createdTo") java.time.LocalDateTime createdTo);

    @Query("""
            select new com.civichub.dashboard.dto.response.MonthlyStatisticResponse(
                extract(month from r.createdAt),
                count(r),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.RESOLVED then 1 else 0 end), 0)
            )
            from Report r
            where extract(year from r.createdAt) = :year
            group by extract(month from r.createdAt)
            order by extract(month from r.createdAt) asc
            """)
    List<MonthlyStatisticResponse> countReportsByMonth(@Param("year") int year);

    @Query("""
            select new com.civichub.dashboard.dto.response.StaffDashboardSummaryResponse(
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.PENDING then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.RECEIVED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.IN_PROGRESS then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.RESOLVED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.REJECTED then 1 else 0 end), 0),
                coalesce(sum(case when r.status = com.civichub.common.enums.ReportStatus.CANCELLED then 1 else 0 end), 0),
                count(r)
            )
            from Report r
            where r.department.id = :departmentId
            """)
    StaffDashboardSummaryResponse countReportsByStatusAndDepartmentId(@Param("departmentId") Long departmentId);

    @Query("""
            select new com.civichub.report.dto.response.ReportSummaryResponse(
                r.id,
                r.title,
                r.address,
                r.status,
                c.id,
                c.name,
                d.id,
                d.name,
                u.id,
                u.fullName,
                null,
                r.createdAt,
                r.updatedAt
            )
            from Report r
            join r.category c
            left join r.department d
            join r.user u
            order by r.createdAt desc
            """)
    Page<ReportSummaryResponse> findRecentReportSummaries(Pageable pageable);

    @Query("""
            select new com.civichub.report.dto.response.ReportSummaryResponse(
                r.id,
                r.title,
                r.address,
                r.status,
                c.id,
                c.name,
                d.id,
                d.name,
                u.id,
                u.fullName,
                null,
                r.createdAt,
                r.updatedAt
            )
            from Report r
            join r.category c
            join r.department d
            join r.user u
            where d.id = :departmentId
            order by r.createdAt desc
            """)
    Page<ReportSummaryResponse> findRecentReportSummariesByDepartmentId(
            @Param("departmentId") Long departmentId,
            Pageable pageable);
}
