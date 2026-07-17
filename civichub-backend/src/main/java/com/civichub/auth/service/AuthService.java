package com.civichub.auth.service;

import com.civichub.auth.dto.request.LoginRequest;
import com.civichub.auth.dto.request.RegisterRequest;
import com.civichub.auth.dto.response.AuthResponse;
import com.civichub.auth.dto.response.CurrentUserResponse;

public interface AuthService {

    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    CurrentUserResponse getCurrentUser();
}
