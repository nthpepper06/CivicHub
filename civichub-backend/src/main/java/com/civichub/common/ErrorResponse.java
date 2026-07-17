package com.civichub.common;

import java.time.LocalDateTime;
import java.util.List;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(staticName = "of")
public class ErrorResponse {

    private boolean success;
    private String message;
    private List<FieldError> errors;
    private LocalDateTime timestamp;

    public static ErrorResponse of(String message) {
        return of(false, message, List.of(), LocalDateTime.now());
    }

    public static ErrorResponse of(String message, List<FieldError> errors) {
        return of(false, message, errors, LocalDateTime.now());
    }

    @Getter
    @NoArgsConstructor(access = AccessLevel.PROTECTED)
    @AllArgsConstructor(staticName = "of")
    public static class FieldError {
        private String field;
        private String message;
    }
}
