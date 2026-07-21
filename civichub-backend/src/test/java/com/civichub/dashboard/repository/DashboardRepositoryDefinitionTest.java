package com.civichub.dashboard.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.report.repository.ReportRepository;
import java.lang.reflect.Method;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Query;

class DashboardRepositoryDefinitionTest {

    @Test
    void adminSummaryQueryShouldUseDatabaseAggregation() throws Exception {
        Query query = queryAnnotation("countReportsByStatus");

        assertThat(query.value())
                .contains("new com.civichub.dashboard.dto.response.ReportStatusStatisticResponse")
                .contains("count(r)")
                .contains("sum(case when r.status");
    }

    @Test
    void categoryAndDepartmentQueriesShouldGroupInsideDatabase() throws Exception {
        assertThat(queryAnnotation("countReportsByCategory").value())
                .contains("new com.civichub.dashboard.dto.response.CategoryStatisticResponse")
                .contains("group by c.id, c.name")
                .contains("order by count(r) desc");

        assertThat(queryAnnotation("countReportsByDepartment").value())
                .contains("new com.civichub.dashboard.dto.response.DepartmentStatisticResponse")
                .contains("group by d.id, d.name")
                .contains("order by count(r) desc");
    }

    @Test
    void monthlyQueryShouldAggregateByMonthAndFilterYear() throws Exception {
        Query query = queryAnnotation("countReportsByMonth", int.class);

        assertThat(query.value())
                .contains("new com.civichub.dashboard.dto.response.MonthlyStatisticResponse")
                .contains("where extract(year from r.createdAt) = :year")
                .contains("group by extract(month from r.createdAt)");
    }

    @Test
    void dateRangeQueriesShouldUseTypedComparisonsWithoutNullableParameterBranches() throws Exception {
        assertThat(queryAnnotation("countReportsByStatus", java.time.LocalDateTime.class, java.time.LocalDateTime.class)
                .value())
                .contains("r.createdAt >= :createdFrom")
                .contains("r.createdAt <= :createdTo")
                .doesNotContain(":createdFrom is null")
                .doesNotContain(":createdTo is null");

        assertThat(queryAnnotation("countReportsByCategory", java.time.LocalDateTime.class, java.time.LocalDateTime.class)
                .value())
                .contains("r.createdAt >= :createdFrom")
                .contains("r.createdAt <= :createdTo")
                .doesNotContain(":createdFrom is null")
                .doesNotContain(":createdTo is null");

        assertThat(queryAnnotation(
                        "countReportsByDepartment",
                        java.time.LocalDateTime.class,
                        java.time.LocalDateTime.class)
                .value())
                .contains("r.createdAt >= :createdFrom")
                .contains("r.createdAt <= :createdTo")
                .doesNotContain(":createdFrom is null")
                .doesNotContain(":createdTo is null");

        assertThat(queryAnnotation(
                        "countReportsByMonth",
                        int.class,
                        java.time.LocalDateTime.class,
                        java.time.LocalDateTime.class)
                .value())
                .contains("r.createdAt >= :createdFrom")
                .contains("r.createdAt <= :createdTo")
                .doesNotContain(":createdFrom is null")
                .doesNotContain(":createdTo is null");
    }

    @Test
    void staffSummaryQueryShouldFilterByDepartment() throws Exception {
        Query query = queryAnnotation("countReportsByStatusAndDepartmentId", Long.class);

        assertThat(query.value())
                .contains("new com.civichub.dashboard.dto.response.StaffDashboardSummaryResponse")
                .contains("where r.department.id = :departmentId");
    }

    @Test
    void recentQueriesShouldUseSummaryProjectionAndCreatedAtDescending() throws Exception {
        assertThat(queryAnnotation("findRecentReportSummaries", org.springframework.data.domain.Pageable.class)
                .value())
                .contains("new com.civichub.report.dto.response.ReportSummaryResponse")
                .contains("order by r.createdAt desc");

        assertThat(queryAnnotation(
                "findRecentReportSummariesByDepartmentId",
                Long.class,
                org.springframework.data.domain.Pageable.class).value())
                .contains("where d.id = :departmentId")
                .contains("order by r.createdAt desc");
    }

    private Query queryAnnotation(String methodName, Class<?>... parameterTypes) throws Exception {
        Method method = ReportRepository.class.getMethod(methodName, parameterTypes);
        Query query = method.getAnnotation(Query.class);
        assertThat(query).isNotNull();
        return query;
    }
}
