alter table audit_logs
    drop constraint if exists audit_logs_action_check;

alter table audit_logs
    add constraint audit_logs_action_check
        check (action in (
            'CATEGORY_CREATED',
            'CATEGORY_UPDATED',
            'CATEGORY_ACTIVATED',
            'CATEGORY_DEACTIVATED',
            'DEPARTMENT_CREATED',
            'DEPARTMENT_UPDATED',
            'DEPARTMENT_ACTIVATED',
            'DEPARTMENT_DEACTIVATED',
            'REPORT_ASSIGNED',
            'REPORT_REASSIGNED',
            'REPORT_STATUS_CHANGED',
            'REPORT_CANCELLED',
            'PROFILE_UPDATED',
            'PASSWORD_CHANGED',
            'USER_STATUS_CHANGED',
            'USER_DEPARTMENT_CHANGED'
        ));

alter table audit_logs
    drop constraint if exists audit_logs_entity_type_check;

alter table audit_logs
    add constraint audit_logs_entity_type_check
        check (entity_type in (
            'CATEGORY',
            'DEPARTMENT',
            'REPORT',
            'USER'
        ));
