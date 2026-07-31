package com.civichub.tools;

import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Profile("local-admin-password-reset")
@RequiredArgsConstructor
public class LocalAdminPasswordResetRunner implements ApplicationRunner {

    private static final String ADMIN_EMAIL = "hieuadmin@test.com";

    private final PasswordEncoder passwordEncoder;
    private final UserRepository userRepository;
    private final ConfigurableApplicationContext applicationContext;

    @Value("${local.admin-reset.password:}")
    private String configuredPassword;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        String rawPassword = resolvePassword();
        String bcryptHash = passwordEncoder.encode(rawPassword);
        String sql = sqlFor(bcryptHash);

        User user = userRepository.findByEmail(ADMIN_EMAIL)
                .orElseThrow(() -> new IllegalStateException("Admin account not found: " + ADMIN_EMAIL));

        verifyAdminCanRemainEnabled(user);
        user.setPassword(bcryptHash);
        userRepository.save(user);
        verifyAdminCanRemainEnabled(user);

        System.out.println();
        System.out.println("CivicHub local admin password reset complete.");
        System.out.println("Email: " + ADMIN_EMAIL);
        System.out.println("Generated BCrypt hash: " + bcryptHash);
        System.out.println("SQL update statement:");
        System.out.println(sql);
        System.out.println("Verified role=ADMIN, status=ACTIVE, is_active=true, enabled=true.");
        System.out.println();

        applicationContext.close();
    }

    private String resolvePassword() {
        String password = configuredPassword.trim();
        if (password.isEmpty()) {
            throw new IllegalStateException(
                    "Set local.admin-reset.password to the temporary local admin password before running.");
        }
        if (password.length() < 8 || password.length() > 72) {
            throw new IllegalStateException("Local admin reset password must be between 8 and 72 characters.");
        }
        return password;
    }

    private void verifyAdminCanRemainEnabled(User user) {
        if (!ADMIN_EMAIL.equalsIgnoreCase(user.getEmail())) {
            throw new IllegalStateException("Refusing to reset unexpected account: " + user.getEmail());
        }
        if (!UserRole.ADMIN.equals(user.getRole())) {
            throw new IllegalStateException("Refusing to reset non-admin account: " + user.getEmail());
        }
        if (!UserStatus.ACTIVE.equals(user.getStatus())) {
            throw new IllegalStateException("Refusing to reset inactive-status admin account: " + user.getEmail());
        }
        if (!user.isActive()) {
            throw new IllegalStateException("Refusing to reset disabled admin account: " + user.getEmail());
        }
        if (!CivicHubUserPrincipal.from(user).isEnabled()) {
            throw new IllegalStateException("Refusing to reset admin account that would not remain enabled.");
        }
    }

    private String sqlFor(String bcryptHash) {
        return "UPDATE users SET password = '" + bcryptHash.replace("'", "''")
                + "' WHERE email = '" + ADMIN_EMAIL
                + "' AND role = 'ADMIN' AND status = 'ACTIVE' AND is_active = true;";
    }
}
