CREATE DATABASE TransactionsDB;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

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

CREATE MATERIALIZED VIEW mv_transaction_totals AS
SELECT
    message ->> 'clientId' AS client_id,
    message ->> 'operationType' AS operation_type,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY
    message ->> 'clientId',
    message ->> 'operationType';

CREATE UNIQUE INDEX idx_mv_transaction_totals
  ON mv_transaction_totals (client_id, operation_type);

CREATE OR REPLACE PROCEDURE mock_generate_transactions_data(num_rows INT)
LANGUAGE sql
AS $$
INSERT INTO transactions(datetime, amount, state, operationGuid, message)
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

REFRESH MATERIALIZED VIEW CONCURRENTLY mv_transaction_totals;
$$;

CREATE OR REPLACE PROCEDURE sp_insert_transaction(
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
    INSERT INTO transactions(datetime, amount, state, operationGuid, message)
    VALUES (p_datetime, p_amount, p_state, p_operation_guid, p_message)
    RETURNING id INTO p_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_update_transactions_states(
    p_target_state INT,       -- the new state to set
    p_current_state INT,      -- only update rows currently in this state
    p_update_even_ids BOOLEAN -- TRUE = update even ids, FALSE = update odd ids
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_update_even_ids THEN
        UPDATE transactions
        SET state = p_target_state
        WHERE is_even_id = TRUE AND state = p_current_state;
    ELSE
        UPDATE transactions
        SET state = p_target_state
        WHERE is_even_id = FALSE AND state = p_current_state;
    END IF;

    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_transaction_totals;
END;
$$;