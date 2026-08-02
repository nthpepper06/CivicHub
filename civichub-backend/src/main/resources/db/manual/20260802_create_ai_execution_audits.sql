create table if not exists ai_execution_audits (
    id bigserial primary key,
    request_id varchar(100),
    correlation_id varchar(100),
    task_type varchar(80),
    provider varchar(50),
    model varchar(120),
    template_id varchar(120),
    template_version varchar(40),
    schema_id varchar(120),
    schema_version varchar(40),
    status varchar(30) not null,
    error_code varchar(80),
    latency_ms bigint,
    prompt_tokens integer,
    completion_tokens integer,
    total_tokens integer,
    estimated_cost double precision,
    created_at timestamp not null,
    updated_at timestamp not null
);

create index if not exists idx_ai_execution_audits_created_at
    on ai_execution_audits (created_at);

create index if not exists idx_ai_execution_audits_task_created_at
    on ai_execution_audits (task_type, created_at);

create index if not exists idx_ai_execution_audits_provider_created_at
    on ai_execution_audits (provider, created_at);

create index if not exists idx_ai_execution_audits_correlation_id
    on ai_execution_audits (correlation_id);
