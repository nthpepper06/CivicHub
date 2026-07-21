package com.civichub.audit.controller;

import com.civichub.audit.dto.response.AuditLogDetailResponse;
import com.civichub.audit.dto.response.AuditLogSummaryResponse;
import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import com.civichub.audit.service.AuditService;
import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.UserRole;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/audit-logs")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "bearerAuth")
public class AdminAuditController {

    private final AuditService auditService;

    @Operation(
            summary = "List audit logs",
            description = "ADMIN-only append-only audit history. Supports filters, date range, search, pagination, and safe sorting.")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<AuditLogSummaryResponse>>> getAuditLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) AuditAction action,
            @RequestParam(required = false) AuditEntityType entityType,
            @RequestParam(required = false) Long entityId,
            @RequestParam(required = false) Long actorId,
            @RequestParam(required = false) UserRole actorRole,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdTo,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok(ApiResponse.success(
                "Audit logs",
                auditService.getAuditLogs(
                        page,
                        size,
                        action,
                        entityType,
                        entityId,
                        actorId,
                        actorRole,
                        createdFrom,
                        createdTo,
                        search,
                        sortBy,
                        direction)));
    }

    @Operation(summary = "Export filtered audit logs as CSV")
    @GetMapping(value = "/export", produces = "text/csv")
    public ResponseEntity<String> exportAuditLogs(
            @RequestParam(required = false) AuditAction action,
            @RequestParam(required = false) AuditEntityType entityType,
            @RequestParam(required = false) Long entityId,
            @RequestParam(required = false) Long actorId,
            @RequestParam(required = false) UserRole actorRole,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdTo,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"civichub-audit-logs.csv\"")
                .contentType(new MediaType("text", "csv"))
                .body(auditService.exportAuditLogsCsv(
                        action,
                        entityType,
                        entityId,
                        actorId,
                        actorRole,
                        createdFrom,
                        createdTo,
                        search,
                        sortBy,
                        direction));
    }

    @Operation(
            summary = "Get audit log detail",
            description = "ADMIN-only audit detail. Audit logs are append-only; no update or delete endpoint is exposed.")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AuditLogDetailResponse>> getAuditLog(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Audit log", auditService.getAuditLog(id)));
    }
}
