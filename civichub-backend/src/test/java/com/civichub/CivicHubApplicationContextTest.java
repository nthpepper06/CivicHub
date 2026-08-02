package com.civichub;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.ops.rate.AIRateLimiter;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
        "app.ai.provider=LOCAL",
        "app.ai.model=local-test",
        "app.database.auto-sync-audit-log-actions=false"
})
class CivicHubApplicationContextTest {

    @Autowired
    private AIProperties aiProperties;

    @Autowired
    private AIRateLimiter aiRateLimiter;

    @Test
    void fullApplicationContextStartsWithAiRateLimiterAndProperties() {
        assertThat(aiProperties.getProvider()).isEqualTo("LOCAL");
        assertThat(aiRateLimiter).isNotNull();
    }
}
