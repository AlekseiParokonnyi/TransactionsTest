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