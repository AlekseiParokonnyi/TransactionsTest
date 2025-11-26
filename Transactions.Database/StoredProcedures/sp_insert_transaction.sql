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
