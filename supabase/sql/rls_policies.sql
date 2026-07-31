-- rls_policies.sql
-- NOTE: Supabase exposes auth.uid() and jwt claims. Adjust admin checks to your JWT claims setup.

-- Enable RLS for tables that need it
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- Only enable RLS and create policies for driver_profiles if the table exists
DO $$
BEGIN
  IF to_regclass('public.driver_profiles') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE driver_profiles ENABLE ROW LEVEL SECURITY;';
  END IF;
END$$;
ALTER TABLE rider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fare_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- users: user can read own row
DROP POLICY IF EXISTS users_self_select ON users;
CREATE POLICY users_self_select ON users
  FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS users_self_update ON users;
CREATE POLICY users_self_update ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND verification_status = (
      SELECT verification_status FROM users u WHERE u.id = id
    )
    AND role = (
      SELECT role FROM users u WHERE u.id = id
    )
  );

DROP POLICY IF EXISTS users_admin_verify ON users;
CREATE POLICY users_admin_verify ON users
  FOR UPDATE
  USING (current_setting('jwt.claims.role', true) = 'admin')
  WITH CHECK (current_setting('jwt.claims.role', true) = 'admin');

-- driver_profiles: driver reads/updates own, riders can read online drivers
DO $$
BEGIN
  IF to_regclass('public.driver_profiles') IS NOT NULL THEN
    EXECUTE $policy$
      DROP POLICY IF EXISTS driver_profiles_owner_select ON driver_profiles;
      DROP POLICY IF EXISTS driver_profiles_owner_update ON driver_profiles;
      DROP POLICY IF EXISTS driver_profiles_admin_update ON driver_profiles;
      DROP POLICY IF EXISTS driver_profiles_read_online ON driver_profiles;

      CREATE POLICY driver_profiles_owner_select ON driver_profiles
        FOR SELECT
        USING (auth.uid() = user_id);

      CREATE POLICY driver_profiles_owner_update ON driver_profiles
        FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);

      CREATE POLICY driver_profiles_admin_update ON driver_profiles
        FOR UPDATE
        USING (current_setting('jwt.claims.role', true) = 'admin')
        WITH CHECK (current_setting('jwt.claims.role', true) = 'admin');

      CREATE POLICY driver_profiles_read_online ON driver_profiles
        FOR SELECT
        USING (is_online = true OR auth.uid() = user_id);
    $policy$;
  END IF;
END$$;

-- rider_profiles: rider reads/updates own
DROP POLICY IF EXISTS rider_profiles_owner ON rider_profiles;
CREATE POLICY rider_profiles_owner ON rider_profiles
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- emergency_contacts: user manages own contacts
DROP POLICY IF EXISTS emergency_contacts_owner ON emergency_contacts;
CREATE POLICY emergency_contacts_owner ON emergency_contacts
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- rides:
-- select: rider sees own, driver sees assigned
DROP POLICY IF EXISTS rides_select_participant ON rides;
CREATE POLICY rides_select_participant ON rides
  FOR SELECT
  USING (rider_id = auth.uid() OR driver_id = auth.uid());

-- insert: allow riders to create rides where rider_id == auth.uid()
DROP POLICY IF EXISTS rides_insert_rider ON rides;
CREATE POLICY rides_insert_rider ON rides
  FOR INSERT
  WITH CHECK (rider_id = auth.uid());

-- update: allow rider or assigned driver to update (status changes)
DROP POLICY IF EXISTS rides_update_participant ON rides;
CREATE POLICY rides_update_participant ON rides
  FOR UPDATE
  USING (rider_id = auth.uid() OR driver_id = auth.uid())
  WITH CHECK (rider_id = auth.uid() OR driver_id = auth.uid());

-- ride_locations: only ride participants can insert/select location points
DROP POLICY IF EXISTS ride_locations_participant_select ON ride_locations;
CREATE POLICY ride_locations_participant_select ON ride_locations
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM rides r
        WHERE r.id = ride_id
        AND (r.rider_id = auth.uid() OR r.driver_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS ride_locations_participant_insert ON ride_locations;
CREATE POLICY ride_locations_participant_insert ON ride_locations
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM rides r
        WHERE r.id = ride_id
        AND (r.rider_id = auth.uid() OR r.driver_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS ride_locations_participant_update ON ride_locations;
CREATE POLICY ride_locations_participant_update ON ride_locations
  FOR UPDATE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM rides r
        WHERE r.id = ride_id
        AND (r.rider_id = auth.uid() OR r.driver_id = auth.uid())
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM rides r
        WHERE r.id = ride_id
        AND (r.rider_id = auth.uid() OR r.driver_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS ride_locations_participant_delete ON ride_locations;
CREATE POLICY ride_locations_participant_delete ON ride_locations
  FOR DELETE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM rides r
      WHERE r.id = ride_id
        AND (r.rider_id = auth.uid() OR r.driver_id = auth.uid())
    )
  );

-- fare_settings: public read, admin write
DROP POLICY IF EXISTS fare_settings_public_read ON fare_settings;
CREATE POLICY fare_settings_public_read ON fare_settings
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS fare_settings_admin_insert ON fare_settings;
CREATE POLICY fare_settings_admin_insert ON fare_settings
  FOR INSERT
  WITH CHECK (current_setting('jwt.claims.role', true) = 'admin');

DROP POLICY IF EXISTS fare_settings_admin_update ON fare_settings;
CREATE POLICY fare_settings_admin_update ON fare_settings
  FOR UPDATE
  USING (current_setting('jwt.claims.role', true) = 'admin')
  WITH CHECK (current_setting('jwt.claims.role', true) = 'admin');

DROP POLICY IF EXISTS fare_settings_admin_delete ON fare_settings;
CREATE POLICY fare_settings_admin_delete ON fare_settings
  FOR DELETE
  USING (current_setting('jwt.claims.role', true) = 'admin');

-- ratings: read own ratings, write once per ride
DROP POLICY IF EXISTS ratings_read_own ON ratings;
CREATE POLICY ratings_read_own ON ratings
  FOR SELECT
  USING (reviewer_id = auth.uid() OR reviewed_id = auth.uid());

DROP POLICY IF EXISTS ratings_insert_reviewer ON ratings;
CREATE POLICY ratings_insert_reviewer ON ratings
  FOR INSERT
  WITH CHECK (
    reviewer_id = auth.uid()
  );

-- commissions: driver sees own, admin sees all
DROP POLICY IF EXISTS commissions_driver ON commissions;
CREATE POLICY commissions_driver ON commissions
  FOR SELECT
  USING (driver_id = auth.uid() OR current_setting('jwt.claims.role', true) = 'admin');

DROP POLICY IF EXISTS commissions_admin_update ON commissions;
CREATE POLICY commissions_admin_update ON commissions
  FOR UPDATE
  USING (current_setting('jwt.claims.role', true) = 'admin')
  WITH CHECK (current_setting('jwt.claims.role', true) = 'admin');

DROP POLICY IF EXISTS commissions_admin_delete ON commissions;
CREATE POLICY commissions_admin_delete ON commissions
  FOR DELETE
  USING (current_setting('jwt.claims.role', true) = 'admin');

-- documents: user sees own, admin sees all
DROP POLICY IF EXISTS documents_owner_select ON documents;
CREATE POLICY documents_owner_select ON documents
  FOR SELECT
  USING (user_id = auth.uid() OR current_setting('jwt.claims.role', true) = 'admin');

DROP POLICY IF EXISTS documents_owner_update ON documents;
CREATE POLICY documents_owner_update ON documents
  FOR UPDATE
  USING (user_id = auth.uid() OR current_setting('jwt.claims.role', true) = 'admin')
    WITH CHECK (
    (user_id = auth.uid() AND status = (
        SELECT status FROM documents d WHERE d.id = id
      ))
    OR current_setting('jwt.claims.role', true) = 'admin'
  );

DROP POLICY IF EXISTS documents_owner_delete ON documents;
CREATE POLICY documents_owner_delete ON documents
  FOR DELETE
  USING (user_id = auth.uid() OR current_setting('jwt.claims.role', true) = 'admin');

DROP POLICY IF EXISTS documents_insert_owner ON documents;
CREATE POLICY documents_insert_owner ON documents
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- safety_reports: user sees own, admin sees all
DROP POLICY IF EXISTS safety_reports_select ON safety_reports;
CREATE POLICY safety_reports_select ON safety_reports
  FOR SELECT
  USING (reporter_id = auth.uid() OR current_setting('jwt.claims.role', true) = 'admin');

DROP POLICY IF EXISTS safety_reports_insert ON safety_reports;
CREATE POLICY safety_reports_insert ON safety_reports
  FOR INSERT
  WITH CHECK (reporter_id = auth.uid() OR current_setting('jwt.claims.role', true) = 'admin');

DROP POLICY IF EXISTS safety_reports_update ON safety_reports;
CREATE POLICY safety_reports_update ON safety_reports
  FOR UPDATE
  USING (reporter_id = auth.uid() OR current_setting('jwt.claims.role', true) = 'admin')
  WITH CHECK (
    (reporter_id = auth.uid() AND status = (
        SELECT status FROM safety_reports s WHERE s.id = id
      ))
    OR current_setting('jwt.claims.role', true) = 'admin'
  );

DROP POLICY IF EXISTS safety_reports_delete ON safety_reports;
CREATE POLICY safety_reports_delete ON safety_reports
  FOR DELETE
  USING (reporter_id = auth.uid() OR current_setting('jwt.claims.role', true) = 'admin');

-- notifications: user sees own
DROP POLICY IF EXISTS notifications_owner ON notifications;
CREATE POLICY notifications_owner ON notifications
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Trigger to ensure only admins can modify vehicle approval fields
DO $$
BEGIN
  IF to_regclass('public.driver_profiles') IS NOT NULL THEN
    EXECUTE $func$
      CREATE OR REPLACE FUNCTION enforce_driver_approval_admin_only()
      RETURNS trigger AS $fn$
      BEGIN
        IF (TG_OP = 'UPDATE') THEN
          IF (NEW.vehicle_approval_status IS DISTINCT FROM OLD.vehicle_approval_status
              OR NEW.vehicle_approved_at IS DISTINCT FROM OLD.vehicle_approved_at
              OR NEW.vehicle_approved_by IS DISTINCT FROM OLD.vehicle_approved_by
              OR NEW.vehicle_approval_notes IS DISTINCT FROM OLD.vehicle_approval_notes) THEN
            IF current_setting('jwt.claims.role', true) IS NULL OR current_setting('jwt.claims.role', true) <> 'admin' THEN
              RAISE EXCEPTION 'Only admins can change vehicle approval fields';
            END IF;
          END IF;
        END IF;
        RETURN NEW;
      END;
      $fn$ LANGUAGE plpgsql;
    $func$;

    EXECUTE 'DROP TRIGGER IF EXISTS enforce_driver_approval_admin_only_trig ON driver_profiles';
    EXECUTE 'CREATE TRIGGER enforce_driver_approval_admin_only_trig BEFORE UPDATE ON driver_profiles FOR EACH ROW EXECUTE FUNCTION enforce_driver_approval_admin_only()';
  END IF;
END$$;
