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