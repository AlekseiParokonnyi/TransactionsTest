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