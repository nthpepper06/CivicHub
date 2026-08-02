create table if not exists report_timeline_events (
    id bigserial primary key,
    report_id bigint not null references reports(id) on delete cascade,
    actor_user_id bigint references users(id) on delete set null,
    event_type varchar(40) not null,
    title varchar(255) not null,
    description text,
    actor_role varchar(20),
    actor_name varchar(120),
    created_at timestamp not null,
    updated_at timestamp not null,
    constraint report_timeline_events_type_check check (
        event_type in (
            'REPORT_CREATED',
            'DEPARTMENT_ASSIGNED',
            'STAFF_ACCEPTED',
            'STATUS_IN_PROGRESS',
            'STAFF_NOTE_ADDED',
            'RESOLUTION_IMAGES_UPLOADED',
            'RESOLVED',
            'REJECTED',
            'CANCELLED',
            'CITIZEN_CONFIRMED',
            'RATING_SUBMITTED'
        )
    )
);

create index if not exists idx_report_timeline_events_report_id_created_at
    on report_timeline_events(report_id, created_at, id);

create table if not exists report_resolutions (
    id bigserial primary key,
    report_id bigint not null unique references reports(id) on delete cascade,
    resolved_by_user_id bigint references users(id) on delete set null,
    summary varchar(1000) not null,
    work_performed text,
    public_note text,
    citizen_confirmed_at timestamp,
    created_at timestamp not null,
    updated_at timestamp not null
);

create table if not exists report_resolution_images (
    id bigserial primary key,
    resolution_id bigint not null references report_resolutions(id) on delete cascade,
    image_url varchar(2000) not null,
    display_order integer not null,
    created_at timestamp not null,
    updated_at timestamp not null
);

create index if not exists idx_report_resolution_images_resolution_order
    on report_resolution_images(resolution_id, display_order, id);

create table if not exists report_ratings (
    id bigserial primary key,
    report_id bigint not null unique references reports(id) on delete cascade,
    user_id bigint not null references users(id) on delete cascade,
    rating integer not null,
    comment text,
    created_at timestamp not null,
    updated_at timestamp not null,
    constraint report_ratings_rating_check check (rating between 1 and 5)
);
