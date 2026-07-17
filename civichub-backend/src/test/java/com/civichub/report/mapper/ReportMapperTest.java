package com.civichub.report.mapper;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.category.entity.Category;
import com.civichub.common.enums.Priority;
import com.civichub.common.enums.ReportStatus;
import com.civichub.department.entity.Department;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.entity.Report;
import com.civichub.report.entity.ReportImage;
import com.civichub.user.entity.User;
import org.junit.jupiter.api.Test;

class ReportMapperTest {

    private final ReportMapper reportMapper = new ReportMapperImpl();

    @Test
    void shouldMapRelationshipIdsNamesAndDeterministicPrimaryImage() {
        Report report = report();
        report.addImage(ReportImage.builder().id(2L).imageUrl("https://a.test/2.png").displayOrder(1).build());
        report.addImage(ReportImage.builder().id(1L).imageUrl("https://a.test/1.png").displayOrder(0).build());

        ReportSummaryResponse summary = reportMapper.toSummaryResponse(report);
        ReportDetailResponse detail = reportMapper.toDetailResponse(report);

        assertThat(summary.getCategoryId()).isEqualTo(10L);
        assertThat(summary.getCategoryName()).isEqualTo("Lighting");
        assertThat(summary.getDepartmentId()).isEqualTo(5L);
        assertThat(summary.getDepartmentName()).isEqualTo("Urban Services");
        assertThat(summary.getCitizenId()).isEqualTo(1L);
        assertThat(summary.getCitizenName()).isEqualTo("Citizen");
        assertThat(summary.getPrimaryImageUrl()).isEqualTo("https://a.test/1.png");
        assertThat(detail.getImages()).extracting("url")
                .containsExactly("https://a.test/1.png", "https://a.test/2.png");
    }

    @Test
    void responseShouldNotExposeSensitiveCitizenFields() throws NoSuchFieldException {
        assertThat(ReportDetailResponse.class.getDeclaredField("citizenName")).isNotNull();
        assertThatThrownByField("citizenEmail");
        assertThatThrownByField("citizenPhone");
    }

    private void assertThatThrownByField(String fieldName) {
        try {
            ReportDetailResponse.class.getDeclaredField(fieldName);
            org.assertj.core.api.Assertions.fail("Field should not exist: " + fieldName);
        } catch (NoSuchFieldException exception) {
            assertThat(exception).isNotNull();
        }
    }

    private Report report() {
        User user = User.builder().id(1L).fullName("Citizen").email("citizen@example.com").build();
        Category category = Category.builder().id(10L).name("Lighting").isActive(true).build();
        Department department = Department.builder().id(5L).name("Urban Services").isActive(true).build();
        return Report.builder()
                .id(99L)
                .title("Report")
                .description("Description")
                .address("Address")
                .status(ReportStatus.PENDING)
                .priority(Priority.MEDIUM)
                .user(user)
                .category(category)
                .department(department)
                .build();
    }
}
