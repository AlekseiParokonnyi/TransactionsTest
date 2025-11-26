CREATE OR REPLACE PROCEDURE ts.sp_update_transactions_states(
    p_target_state INT,       -- the new state to set
    p_current_state INT,      -- only update rows currently in this state
    p_update_even_ids BOOLEAN -- TRUE = update even ids, FALSE = update odd ids
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE ts.transactions
    SET state = p_target_state
    WHERE state = p_current_state
      AND id % 2 = CASE WHEN p_update_even_ids THEN 0 ELSE 1 END;

    --From my point of view, one more denormalized table might be more efficient than this materialized view
    REFRESH MATERIALIZED VIEW CONCURRENTLY ts.mv_transaction_totals;
END;
$$;