package com.civichub.ai.ops.rate;

import com.civichub.ai.config.AIProperties;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

@Component
public class AIRateLimiter {

    private final AIProperties properties;
    private final Clock clock;
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

    public AIRateLimiter(AIProperties properties) {
        this(properties, Clock.systemUTC());
    }

    AIRateLimiter(AIProperties properties, Clock clock) {
        this.properties = properties;
        this.clock = clock;
    }

    public boolean allow(String key) {
        Instant now = clock.instant();
        Bucket bucket = buckets.compute(key, (ignored, current) -> {
            if (current == null || !now.isBefore(current.windowEndsAt())) {
                return new Bucket(now.plus(properties.getRateLimitWindow()), 1);
            }
            return current.increment();
        });
        return bucket.requests() <= properties.getRateLimitRequests();
    }

    private record Bucket(Instant windowEndsAt, int requests) {
        Bucket increment() {
            return new Bucket(windowEndsAt, requests + 1);
        }
    }
}
