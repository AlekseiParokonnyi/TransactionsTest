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

    --From my point of view, one more denormalized table might be more efficient than this materialized view
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_transaction_totals;
END;
$$;