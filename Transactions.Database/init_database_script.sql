CREATE DATABASE TransactionsDB;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA ts;

CREATE TABLE ts.transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 10000),
    datetime TIMESTAMPTZ NOT NULL,
    amount NUMERIC(18, 2) NOT NULL,
    state INT NOT NULL,
    operationGuid UUID NOT NULL,
    message JSONB NOT NULL,
    PRIMARY KEY (id, datetime)
) PARTITION BY RANGE (datetime);

CREATE INDEX idx_transactions_state ON ts.transactions (state);

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

CREATE MATERIALIZED VIEW ts.mv_transaction_totals AS
SELECT
    message ->> 'clientId' AS client_id,
    message ->> 'operationType' AS operation_type,
    SUM(amount) AS total_amount
FROM ts.transactions
GROUP BY
    message ->> 'clientId',
    message ->> 'operationType';

CREATE UNIQUE INDEX idx_mv_transaction_totals
  ON ts.mv_transaction_totals (client_id, operation_type);

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

CREATE OR REPLACE FUNCTION ts.check_operationguid_unique()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM ts.transactions
        WHERE operationGuid = NEW.operationGuid
    ) THEN
        RAISE EXCEPTION 'check_unique_id: Duplicate id value: %', NEW.operationGuid;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE ts.mock_generate_transactions_data(num_rows INT)
LANGUAGE sql
AS $$
INSERT INTO ts.transactions(datetime, amount, state, operationGuid, message)
SELECT *
FROM (
    SELECT
        TIMESTAMP '2025-08-01 00:00:00' + random() * (TIMESTAMP '2025-11-03 23:59:59' - TIMESTAMP '2025-08-01 00:00:00') AS datetime,
        round((random() * 9999 + 1)::numeric, 2) AS amount, 
        1 AS state, 
        gen_random_uuid() AS operationGuid,
        jsonb_build_object(
            'accountId', floor(random() * 1000000)::int,
            'clientId', floor(random() * 10000)::int,
            'operationType', CASE WHEN random() < 0.5 THEN 'online' ELSE 'offline' END
        ) AS message
    FROM generate_series(1, num_rows)
    ORDER BY datetime
) sub;

REFRESH MATERIALIZED VIEW CONCURRENTLY ts.mv_transaction_totals;
$$;

CREATE OR REPLACE PROCEDURE ts.sp_insert_transaction(
    p_datetime TIMESTAMPTZ,
    p_amount NUMERIC(18, 2),
    p_state INT,
    p_operation_guid UUID,
    p_message JSONB,
    OUT p_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO ts.transactions(datetime, amount, state, operationGuid, message)
    VALUES (p_datetime, p_amount, p_state, p_operation_guid, p_message)
    RETURNING id INTO p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE ts.sp_update_transactions_states(
    p_target_state INT,       -- the new state to set
    p_current_state INT,      -- only update rows currently in this state
    p_update_even_ids BOOLEAN -- TRUE = update even ids, FALSE = update odd ids
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_update_even_ids THEN
        UPDATE ts.transactions
        SET state = p_target_state
        WHERE id % 2 = 0 AND state = p_current_state;
    ELSE
        UPDATE ts.transactions
        SET state = p_target_state
        WHERE id % 2 = 0 AND state = p_current_state;
    END IF;

    --From my point of view, one more denormalized table might be more efficient than this materialized view
    REFRESH MATERIALIZED VIEW CONCURRENTLY ts.mv_transaction_totals;
END;
$$;

CREATE TRIGGER enforce_unique_id
BEFORE INSERT ON ts.transactions
FOR EACH ROW EXECUTE FUNCTION ts.check_operationguid_unique();