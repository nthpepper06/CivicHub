package com.civichub.ai.ops.repository;

import com.civichub.ai.ops.entity.AIExecutionAudit;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface AIExecutionAuditRepository extends JpaRepository<AIExecutionAudit, Long> {

    List<AIExecutionAudit> findAllByOrderByCreatedAtDesc(Pageable pageable);

    long countByCreatedAtAfter(LocalDateTime createdAt);

    long countByStatusAndCreatedAtAfter(String status, LocalDateTime createdAt);

    @Query("""
            select coalesce(avg(a.latencyMs), 0)
            from AIExecutionAudit a
            where a.createdAt >= :createdAt
            """)
    Double averageLatencySince(LocalDateTime createdAt);
}
