package com.civichub.auth.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.auth.dto.request.LoginRequest;
import com.civichub.auth.dto.request.RegisterRequest;
import com.civichub.auth.dto.response.AuthResponse;
import com.civichub.auth.dto.response.CurrentUserResponse;
import com.civichub.auth.mapper.AuthMapper;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.ResourceAlreadyExistsException;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.security.JwtService;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class AuthServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private JwtService jwtService;

    @Mock
    private AuthMapper authMapper;

    private AuthServiceImpl authService;

    @BeforeEach
    void setUp() {
        authService = new AuthServiceImpl(
                userRepository,
                passwordEncoder,
                authenticationManager,
                jwtService,
                authMapper);
    }

    @Test
    void registerShouldSaveCitizenWithEncodedPasswordAndNormalizedEmail() {
        RegisterRequest request = new RegisterRequest(
                "Nguyen Van A",
                " Citizen@Example.COM ",
                "strongPassword",
                " 0909000000 ");
        CurrentUserResponse currentUser = CurrentUserResponse.builder()
                .id(1L)
                .email("citizen@example.com")
                .role(UserRole.CITIZEN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build();

        when(userRepository.existsByEmail("citizen@example.com")).thenReturn(false);
        when(passwordEncoder.encode("strongPassword")).thenReturn("encoded-password");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(1L);
            return user;
        });
        when(jwtService.generateToken(any(CivicHubUserPrincipal.class))).thenReturn("jwt-token");
        when(jwtService.getExpirationSeconds()).thenReturn(86400L);
        when(authMapper.toCurrentUserResponse(any(User.class))).thenReturn(currentUser);

        AuthResponse response = authService.register(request);

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        User savedUser = userCaptor.getValue();
        assertThat(savedUser.getEmail()).isEqualTo("citizen@example.com");
        assertThat(savedUser.getPassword()).isEqualTo("encoded-password");
        assertThat(savedUser.getRole()).isEqualTo(UserRole.CITIZEN);
        assertThat(savedUser.getStatus()).isEqualTo(UserStatus.ACTIVE);
        assertThat(savedUser.isActive()).isTrue();
        assertThat(savedUser.getDepartment()).isNull();
        assertThat(response.getAccessToken()).isEqualTo("jwt-token");
        assertThat(response.getTokenType()).isEqualTo("Bearer");
        assertThat(response.getExpiresIn()).isEqualTo(86400L);
    }

    @Test
    void registerShouldRejectDuplicateEmail() {
        RegisterRequest request = new RegisterRequest(
                "Nguyen Van A",
                "Citizen@Example.COM",
                "strongPassword",
                null);

        when(userRepository.existsByEmail("citizen@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(ResourceAlreadyExistsException.class);
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void loginShouldDelegateAuthenticationAndReturnJwt() {
        LoginRequest request = new LoginRequest(" Citizen@Example.COM ", "strongPassword");
        User user = citizenUser();
        CivicHubUserPrincipal principal = CivicHubUserPrincipal.from(user);
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
        CurrentUserResponse currentUser = CurrentUserResponse.builder()
                .id(1L)
                .email("citizen@example.com")
                .build();

        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenReturn(authentication);
        when(userRepository.findByEmail("citizen@example.com")).thenReturn(Optional.of(user));
        when(jwtService.generateToken(principal)).thenReturn("jwt-token");
        when(jwtService.getExpirationSeconds()).thenReturn(86400L);
        when(authMapper.toCurrentUserResponse(user)).thenReturn(currentUser);

        AuthResponse response = authService.login(request);

        ArgumentCaptor<UsernamePasswordAuthenticationToken> authCaptor =
                ArgumentCaptor.forClass(UsernamePasswordAuthenticationToken.class);
        verify(authenticationManager).authenticate(authCaptor.capture());
        assertThat(authCaptor.getValue().getPrincipal()).isEqualTo("citizen@example.com");
        assertThat(authCaptor.getValue().getCredentials()).isEqualTo("strongPassword");
        assertThat(response.getAccessToken()).isEqualTo("jwt-token");
    }

    @Test
    void loginShouldReturnGenericAuthenticationErrorForInvalidCredentials() {
        LoginRequest request = new LoginRequest("citizen@example.com", "wrong-password");
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenThrow(new BadCredentialsException("Bad credentials"));

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(BadCredentialsException.class)
                .hasMessage("Invalid email or password");
        verify(userRepository, never()).findByEmail(any());
    }

    private User citizenUser() {
        return User.builder()
                .id(1L)
                .fullName("Nguyen Van A")
                .email("citizen@example.com")
                .password("encoded-password")
                .role(UserRole.CITIZEN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build();
    }
}
