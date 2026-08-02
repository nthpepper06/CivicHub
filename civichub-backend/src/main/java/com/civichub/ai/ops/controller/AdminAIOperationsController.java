package com.civichub.ai.ops.controller;

import com.civichub.ai.ops.dto.AIHealthResponse;
import com.civichub.ai.ops.dto.AIProviderOperationsResponse;
import com.civichub.ai.ops.dto.AIRecentExecutionResponse;
import com.civichub.ai.ops.dto.AIUsageSummaryResponse;
import com.civichub.ai.ops.service.AIOperationsService;
import com.civichub.common.ApiResponse;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/ai")
@RequiredArgsConstructor
public class AdminAIOperationsController {

    private final AIOperationsService operationsService;

    @GetMapping("/usage")
    public ResponseEntity<ApiResponse<AIUsageSummaryResponse>> usage() {
        return ResponseEntity.ok(ApiResponse.success("AI usage metrics", operationsService.usage()));
    }

    @GetMapping("/recent")
    public ResponseEntity<ApiResponse<List<AIRecentExecutionResponse>>> recent(
            @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(ApiResponse.success("Recent AI executions", operationsService.recent(limit)));
    }

    @GetMapping("/providers")
    public ResponseEntity<ApiResponse<AIProviderOperationsResponse>> providers() {
        return ResponseEntity.ok(ApiResponse.success("AI provider operations", operationsService.providers()));
    }

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<AIHealthResponse>> health() {
        return ResponseEntity.ok(ApiResponse.success("AI health", operationsService.health()));
    }
}
