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