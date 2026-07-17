package com.civichub.auth.service;

import com.civichub.auth.dto.request.LoginRequest;
import com.civichub.auth.dto.request.RegisterRequest;
import com.civichub.auth.dto.response.AuthResponse;
import com.civichub.auth.dto.response.CurrentUserResponse;
import com.civichub.auth.mapper.AuthMapper;
import com.civichub.common.Constants;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.AccountDisabledException;
import com.civichub.common.exception.ResourceAlreadyExistsException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.security.JwtService;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AccountStatusException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final AuthMapper authMapper;

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (userRepository.existsByEmail(email)) {
            throw new ResourceAlreadyExistsException("Email already exists");
        }

        User user = User.builder()
                .fullName(request.getFullName().trim())
                .email(email)
                .password(passwordEncoder.encode(request.getPassword()))
                .phone(normalizeOptional(request.getPhone()))
                .role(UserRole.CITIZEN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .department(null)
                .build();

        User savedUser = userRepository.save(user);
        CivicHubUserPrincipal principal = CivicHubUserPrincipal.from(savedUser);
        String token = jwtService.generateToken(principal);
        return buildAuthResponse(token, savedUser);
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.getEmail());
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, request.getPassword()));

            CivicHubUserPrincipal principal = (CivicHubUserPrincipal) authentication.getPrincipal();
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));
            String token = jwtService.generateToken(principal);
            return buildAuthResponse(token, user);
        } catch (AccountStatusException exception) {
            throw new AccountDisabledException("Account is disabled or blocked");
        } catch (BadCredentialsException exception) {
            throw new BadCredentialsException("Invalid email or password");
        }
    }

    @Override
    @Transactional(readOnly = true)
    public CurrentUserResponse getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new ResourceNotFoundException("Current user not found");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));
        return authMapper.toCurrentUserResponse(user);
    }

    private AuthResponse buildAuthResponse(String token, User user) {
        return AuthResponse.builder()
                .accessToken(token)
                .tokenType(Constants.BEARER_TOKEN_TYPE)
                .expiresIn(jwtService.getExpirationSeconds())
                .user(authMapper.toCurrentUserResponse(user))
                .build();
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase();
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }
}
