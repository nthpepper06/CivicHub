package com.civichub.tools;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith({MockitoExtension.class, OutputCaptureExtension.class})
class LocalAdminPasswordResetRunnerTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private ConfigurableApplicationContext applicationContext;

    @Test
    void resetUsesConfiguredPasswordAndPreservesAdminEnabledState(CapturedOutput output) {
        PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
        LocalAdminPasswordResetRunner runner = runner(passwordEncoder, "local-secret-password");
        User admin = adminUser();
        when(userRepository.findByEmail("hieuadmin@test.com")).thenReturn(Optional.of(admin));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        runner.run(new DefaultApplicationArguments());

        ArgumentCaptor<User> savedUser = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(savedUser.capture());
        User saved = savedUser.getValue();

        assertThat(passwordEncoder.matches("local-secret-password", saved.getPassword())).isTrue();
        assertThat(saved.getRole()).isEqualTo(UserRole.ADMIN);
        assertThat(saved.getStatus()).isEqualTo(UserStatus.ACTIVE);
        assertThat(saved.isActive()).isTrue();
        assertThat(output).contains("Generated BCrypt hash: $2a$");
        assertThat(output).doesNotContain("Temporary password");
        assertThat(output).doesNotContain("local-secret-password");
        assertThat(output).contains("UPDATE users SET password = '$2a$");
        assertThat(output).contains("WHERE email = 'hieuadmin@test.com' AND role = 'ADMIN' AND status = 'ACTIVE' AND is_active = true;");
        verify(applicationContext).close();
    }

    @Test
    void resetFailsWhenTargetAccountIsNotAdmin() {
        LocalAdminPasswordResetRunner runner = runner(new BCryptPasswordEncoder(), "local-secret-password");
        User user = adminUser();
        user.setRole(UserRole.CITIZEN);
        when(userRepository.findByEmail("hieuadmin@test.com")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> runner.run(new DefaultApplicationArguments()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("non-admin");

        verify(userRepository, never()).save(any(User.class));
        verify(applicationContext, never()).close();
    }

    @Test
    void resetFailsWhenTargetAccountWouldNotBeEnabled() {
        LocalAdminPasswordResetRunner runner = runner(new BCryptPasswordEncoder(), "local-secret-password");
        User user = adminUser();
        user.setActive(false);
        when(userRepository.findByEmail("hieuadmin@test.com")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> runner.run(new DefaultApplicationArguments()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("disabled");

        verify(userRepository, never()).save(any(User.class));
        verify(applicationContext, never()).close();
    }

    @Test
    void resetRequiresExplicitLocalPassword() {
        LocalAdminPasswordResetRunner runner = runner(new BCryptPasswordEncoder(), " ");

        assertThatThrownBy(() -> runner.run(new DefaultApplicationArguments()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("local.admin-reset.password");

        verify(userRepository, never()).findByEmail("hieuadmin@test.com");
        verify(userRepository, never()).save(any(User.class));
        verify(applicationContext, never()).close();
    }

    private LocalAdminPasswordResetRunner runner(PasswordEncoder passwordEncoder, String password) {
        LocalAdminPasswordResetRunner runner = new LocalAdminPasswordResetRunner(
                passwordEncoder,
                userRepository,
                applicationContext);
        ReflectionTestUtils.setField(runner, "configuredPassword", password);
        return runner;
    }

    private User adminUser() {
        return User.builder()
                .id(1L)
                .fullName("Hieu Admin")
                .email("hieuadmin@test.com")
                .password("old-hash")
                .role(UserRole.ADMIN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build();
    }
}
