package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class UnsupportedImageFormatException extends AIException {

    public UnsupportedImageFormatException(String mimeType) {
        super("AI_UNSUPPORTED_IMAGE_FORMAT", "Unsupported image format: " + mimeType, HttpStatus.BAD_REQUEST);
    }
}
