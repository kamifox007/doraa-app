-- 1. Advanced RLS Policies
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;

-- لا يمكن حذف رحلة مكتملة
CREATE POLICY "no_delete_completed_rides" ON rides
  FOR DELETE USING (status != 'completed');

-- لا يمكن تعديل الأجرة بعد الاتفاق
CREATE POLICY "no_fare_change_after_accepted" ON rides
  FOR UPDATE USING (status NOT IN ('accepted', 'started', 'completed'));

-- 2. Audit Trigger (غير قابل للحذف)
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (admin_id, action, entity_type, entity_id, old_values, new_values)
  VALUES (
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: Make sure the 'rides' table exists before creating this trigger
-- CREATE TRIGGER rides_audit AFTER INSERT OR UPDATE OR DELETE ON rides
--   FOR EACH ROW EXECUTE FUNCTION log_audit();

-- 3. Commission Auto-Calculation
CREATE OR REPLACE FUNCTION calculate_commission()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO commissions (ride_id, driver_id, gross_amount, commission_rate, commission_amount, net_amount)
  VALUES (
    NEW.id,
    NEW.driver_id,
    NEW.agreed_fare,
    0.15,
    NEW.agreed_fare * 0.15,
    NEW.agreed_fare * 0.85
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: Make sure 'rides' and 'commissions' tables exist before creating this trigger
-- CREATE TRIGGER commission_trigger AFTER UPDATE OF status ON rides
--   FOR EACH ROW WHEN (NEW.status = 'completed')
--   EXECUTE FUNCTION calculate_commission();

-- 4. Driver Rating Auto-Update
CREATE OR REPLACE FUNCTION update_driver_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET average_rating = (
    SELECT AVG(rating) FROM ratings WHERE to_user_id = NEW.to_user_id
  ),
  total_rides = total_rides + 1
  WHERE id = NEW.to_user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: Make sure 'ratings' and 'profiles' tables exist before creating this trigger
-- CREATE TRIGGER rating_trigger AFTER INSERT ON ratings
--   FOR EACH ROW EXECUTE FUNCTION update_driver_rating();
