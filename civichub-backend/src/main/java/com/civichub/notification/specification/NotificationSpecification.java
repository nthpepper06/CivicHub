package com.civichub.notification.specification;

import com.civichub.common.enums.NotificationType;
import com.civichub.notification.entity.Notification;
import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import org.springframework.data.jpa.domain.Specification;

public final class NotificationSpecification {

    private NotificationSpecification() {
    }

    public static Specification<Notification> filter(Long userId, Boolean unread, NotificationType type) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(criteriaBuilder.equal(root.get("user").get("id"), userId));
            if (unread != null) {
                predicates.add(unread
                        ? criteriaBuilder.isFalse(root.get("read"))
                        : criteriaBuilder.isTrue(root.get("read")));
            }
            if (type != null) {
                predicates.add(criteriaBuilder.equal(root.get("type"), type));
            }
            return criteriaBuilder.and(predicates.toArray(Predicate[]::new));
        };
    }
}
