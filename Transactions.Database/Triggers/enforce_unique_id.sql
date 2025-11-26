CREATE TRIGGER enforce_unique_id
BEFORE INSERT ON ts.transactions
FOR EACH ROW EXECUTE FUNCTION ts.check_operationguid_unique();