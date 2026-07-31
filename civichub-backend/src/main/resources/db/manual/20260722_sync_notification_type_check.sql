alter table notifications
    drop constraint if exists notifications_type_check;

alter table notifications
    add constraint notifications_type_check
        check (type in (
            'REPORT_ASSIGNED',
            'REPORT_STATUS_CHANGED'
        ));
