package com.civichub.auth.dto.response;

import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CurrentUserResponse {

    private Long id;
    private String fullName;
    private String email;
    private String phone;
    private String avatar;
    private UserRole role;
    private UserStatus status;
    @JsonProperty("isActive")
    private boolean isActive;
    private Long departmentId;
    private String departmentName;
}
