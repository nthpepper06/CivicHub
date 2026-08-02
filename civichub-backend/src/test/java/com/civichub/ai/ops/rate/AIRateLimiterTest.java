package com.civichub.ai.ops.rate;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.ai.config.AIProperties;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;

class AIRateLimiterTest {

    @Test
    void limitsRequestsPerUserWithinWindow() {
        AIProperties properties = properties(2, Duration.ofMinutes(1));
        AIRateLimiter limiter = new AIRateLimiter(properties);

        assertThat(limiter.allow("user-a")).isTrue();
        assertThat(limiter.allow("user-a")).isTrue();
        assertThat(limiter.allow("user-a")).isFalse();
        assertThat(limiter.allow("user-b")).isTrue();
    }

    @Test
    void resetsAfterWindowExpires() {
        AIProperties properties = properties(1, Duration.ofMinutes(1));
        MutableClock clock = new MutableClock(Instant.parse("2026-08-02T00:00:00Z"));
        AIRateLimiter limiter = new AIRateLimiter(properties, clock);

        assertThat(limiter.allow("user-a")).isTrue();
        assertThat(limiter.allow("user-a")).isFalse();
        clock.advance(Duration.ofMinutes(1));

        assertThat(limiter.allow("user-a")).isTrue();
    }

    private AIProperties properties(int requests, Duration window) {
        AIProperties properties = new AIProperties();
        properties.setRateLimitRequests(requests);
        properties.setRateLimitWindow(window);
        return properties;
    }

    private static final class MutableClock extends Clock {
        private Instant instant;

        private MutableClock(Instant instant) {
            this.instant = instant;
        }

        void advance(Duration duration) {
            instant = instant.plus(duration);
        }

        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return instant;
        }
    }
}
