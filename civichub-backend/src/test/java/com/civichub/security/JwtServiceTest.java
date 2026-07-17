package com.civichub.security;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.common.enums.UserRole;
import io.jsonwebtoken.io.Encoders;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

class JwtServiceTest {

    private static final String SECRET = Encoders.BASE64.encode(
            "12345678901234567890123456789012".getBytes(StandardCharsets.UTF_8));

    @Test
    void generateTokenShouldIncludeSubjectUserIdAndRole() {
        JwtService jwtService = new JwtService(SECRET, 86400000);
        CivicHubUserPrincipal principal = new CivicHubUserPrincipal(
                10L,
                "citizen@example.com",
                "encoded-password",
                UserRole.CITIZEN,
                true);

        String token = jwtService.generateToken(principal);

        assertThat(jwtService.extractUsername(token)).isEqualTo("citizen@example.com");
        assertThat(jwtService.extractUserId(token)).isEqualTo(10L);
        assertThat(jwtService.extractRole(token)).isEqualTo("CITIZEN");
        assertThat(jwtService.isTokenValid(token, principal)).isTrue();
    }

    @Test
    void invalidOrExpiredTokenShouldBeRejected() {
        JwtService jwtService = new JwtService(SECRET, 86400000);
        JwtService expiredJwtService = new JwtService(SECRET, -1000);
        CivicHubUserPrincipal principal = new CivicHubUserPrincipal(
                10L,
                "citizen@example.com",
                "encoded-password",
                UserRole.CITIZEN,
                true);

        String expiredToken = expiredJwtService.generateToken(principal);

        assertThat(jwtService.isTokenValid("not-a-jwt", principal)).isFalse();
        assertThat(jwtService.isTokenValid(expiredToken, principal)).isFalse();
    }
}
