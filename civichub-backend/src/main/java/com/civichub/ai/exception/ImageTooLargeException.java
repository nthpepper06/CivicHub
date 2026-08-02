package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class ImageTooLargeException extends AIException {

    public ImageTooLargeException(long maxSizeBytes) {
        super("AI_IMAGE_TOO_LARGE", "Image file must be " + maxSizeBytes + " bytes or smaller", HttpStatus.BAD_REQUEST);
    }
}
