CREATE TABLE transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    datetime TIMESTAMPTZ NOT NULL,
    amount NUMERIC(18, 2) NOT NULL,
    state INT NOT NULL,
    operationGuid UUID NOT NULL,
    message JSONB NOT NULL,
    is_even_id BOOLEAN GENERATED ALWAYS AS (id % 2 = 0) STORED,
    PRIMARY KEY (id, datetime)
) PARTITION BY RANGE (datetime);

CREATE INDEX idx_transactions_state_even_id ON transactions (state, is_even_id);

CREATE SCHEMA IF NOT EXISTS partman;

CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman;

SELECT partman.create_parent(
    p_parent_table := 'public.transactions',
    p_control := 'datetime',
    p_type := 'range',
    p_interval := '1 month',
    p_premake := 3,
    p_start_partition := to_char(
        date_trunc('month', now()) - interval '3 months',
        'YYYY-MM-DD'
    )
);
