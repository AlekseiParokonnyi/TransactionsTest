CREATE TABLE ts.transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 10000),
    datetime TIMESTAMPTZ NOT NULL,
    amount NUMERIC(18, 2) NOT NULL,
    state INT NOT NULL,
    operationGuid UUID NOT NULL,
    message JSONB NOT NULL,
    PRIMARY KEY (id, datetime)
) PARTITION BY RANGE (datetime);

CREATE INDEX idx_transactions_state
    ON ts.transactions (state);

CREATE INDEX idx_transactions_message_gin
    ON ts.transactions USING GIN (message);

CREATE TABLE ts.transactions_default PARTITION OF ts.transactions
    DEFAULT;

CREATE TABLE ts.transactions_08_2025 PARTITION OF ts.transactions
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE ts.transactions_09_2025 PARTITION OF ts.transactions
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE ts.transactions_10_2025 PARTITION OF ts.transactions
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE ts.transactions_11_2025 PARTITION OF ts.transactions
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE OR REPLACE FUNCTION ts.create_next_transactions_partitions()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    i INT;
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
BEGIN
    FOR i IN 1..3 LOOP
        start_date := date_trunc('month', now()) + (interval '1 month' * i);
        end_date := start_date + interval '1 month';
        partition_name := 'transactions_' || to_char(start_date, 'MM_YYYY');

        EXECUTE format('
            CREATE TABLE IF NOT EXISTS ts.%I PARTITION OF ts.transactions
            FOR VALUES FROM (%L) TO (%L);',
            partition_name,
            start_date::text,
            end_date::text
        );
    END LOOP;

    -- ensure default partition exists
    EXECUTE 'CREATE TABLE IF NOT EXISTS ts.transactions_default PARTITION OF ts.transactions DEFAULT;';
END;
$$;