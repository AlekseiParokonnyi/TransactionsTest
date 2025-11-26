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