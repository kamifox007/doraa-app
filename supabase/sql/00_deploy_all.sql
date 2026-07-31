-- 00_deploy_all.sql
-- Combined deployment script: migrations -> rls policies -> functions -> seeds
-- Run this file after setting DATABASE_URL or paste into Supabase SQL editor.

-- ===== migrations.sql =====

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    EXECUTE 'CREATE TYPE user_role AS ENUM (''rider'',''driver'')';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_status') THEN
    EXECUTE 'CREATE TYPE verification_status AS ENUM (''pending'',''approved'',''rejected'')';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ride_status') THEN
    EXECUTE 'CREATE TYPE ride_status AS ENUM (''searching'',''negotiating'',''accepted'',''arrived_pickup'',''started'',''completed'',''cancelled'')';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cancelled_by_enum') THEN
    EXECUTE 'CREATE TYPE cancelled_by_enum AS ENUM (''rider'',''driver'')';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_type') THEN
    EXECUTE 'CREATE TYPE document_type AS ENUM (''cni'',''selfie'',''car_photo'',''license'')';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_status') THEN
    EXECUTE 'CREATE TYPE document_status AS ENUM (''pending'',''approved'',''rejected'')';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'safety_status') THEN
    EXECUTE 'CREATE TYPE safety_status AS ENUM (''open'',''reviewing'',''resolved'',''dismissed'')';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'commission_status') THEN
    EXECUTE 'CREATE TYPE commission_status AS ENUM (''pending'',''paid'')';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'approval_status') THEN
    EXECUTE 'CREATE TYPE approval_status AS ENUM (''pending'',''approved'',''rejected'')';
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role user_role NOT NULL DEFAULT 'rider',
  full_name text,
  phone text UNIQUE,
  email text,
  gender_verified boolean DEFAULT false,
  verification_status verification_status DEFAULT 'pending',
  wilaya text,
  verification_reviewed_at timestamptz,
  verification_reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS driver_profiles (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  car_brand text,
  car_model text,
  car_year int,
  car_color text,
  car_plate text,
  car_photo_url text,
  commission_rate numeric DEFAULT 0.15,
  rating numeric DEFAULT 5.0,
  average_rating numeric DEFAULT 5.0,
  total_rides int DEFAULT 0,
  is_online boolean DEFAULT false,
  vehicle_approval_status approval_status DEFAULT 'pending',
  vehicle_approved_at timestamptz,
  vehicle_approved_by uuid REFERENCES users(id) ON DELETE SET NULL,
  vehicle_approval_notes text,
  current_lat numeric,
  current_lng numeric,
  last_location_update timestamptz
);

CREATE TABLE IF NOT EXISTS rider_profiles (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  rating numeric DEFAULT 5.0,
  average_rating numeric DEFAULT 5.0,
  total_rides int DEFAULT 0
);

CREATE TABLE IF NOT EXISTS emergency_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  contact_name text,
  contact_phone text,
  relationship text,
  is_primary boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  full_name text,
  email text,
  phone text,
  wilaya text,
  role user_role DEFAULT 'rider',
  verification_status verification_status DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS rides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id uuid REFERENCES users(id) ON DELETE SET NULL,
  driver_id uuid REFERENCES users(id),
  status ride_status DEFAULT 'searching',
  pickup_address text,
  pickup_lat numeric,
  pickup_lng numeric,
  dropoff_address text,
  dropoff_lat numeric,
  dropoff_lng numeric,
  suggested_fare numeric,
  proposed_fare numeric,
  agreed_fare numeric,
  negotiation_history jsonb DEFAULT '[]'::jsonb,
  last_message text,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancelled_by cancelled_by_enum,
  cancellation_reason text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ride_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid REFERENCES rides(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id),
  latitude numeric,
  longitude numeric,
  timestamp timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fare_settings (
  wilaya text PRIMARY KEY,
  base_fare numeric,
  per_km_rate numeric,
  per_min_rate numeric,
  min_fare numeric,
  night_multiplier numeric DEFAULT 1.5,
  night_start time DEFAULT '22:00'::time,
  night_end time DEFAULT '06:00'::time
);

CREATE TABLE IF NOT EXISTS ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid REFERENCES rides(id) ON DELETE CASCADE,
  reviewer_id uuid REFERENCES users(id),
  reviewed_id uuid REFERENCES users(id),
  rating int CHECK (rating >= 1 AND rating <= 5),
  is_driver_rating boolean DEFAULT false,
  comment text,
  created_at timestamptz DEFAULT now(),
  UNIQUE (ride_id, reviewer_id)
);

CREATE TABLE IF NOT EXISTS commissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id uuid REFERENCES rides(id),
  driver_id uuid REFERENCES users(id),
  fare numeric,
  commission_rate numeric,
  commission_amount numeric,
  net_earnings numeric,
  status commission_status DEFAULT 'pending',
  paid_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id),
  type document_type,
  file_url text,
  status document_status DEFAULT 'pending',
  admin_notes text,
  uploaded_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS safety_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES users(id),
  reported_id uuid REFERENCES users(id),
  ride_id uuid REFERENCES rides(id),
  reason text,
  details text,
  status safety_status DEFAULT 'open',
  admin_resolution text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id),
  type text,
  title text,
  body text,
  data jsonb,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rides_rider_id ON rides(rider_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver_id ON rides(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_profiles_is_online ON driver_profiles(is_online);

-- ===== rls_policies.sql =====

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF to_regclass('public.driver_profiles') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE driver_profiles ENABLE ROW LEVEL SECURITY;';
  END IF;
END$$;
ALTER TABLE rider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fare_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_self_select ON users;
CREATE POLICY users_self_select ON users
  FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS users_self_insert ON users;
CREATE POLICY users_self_insert ON users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

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

DO $$
BEGIN
  IF to_regclass('public.driver_profiles') IS NOT NULL THEN
    EXECUTE $policy$
      DROP POLICY IF EXISTS driver_profiles_owner_select ON driver_profiles;
      DROP POLICY IF EXISTS driver_profiles_owner_insert ON driver_profiles;
      DROP POLICY IF EXISTS driver_profiles_owner_update ON driver_profiles;
      DROP POLICY IF EXISTS driver_profiles_admin_update ON driver_profiles;
      DROP POLICY IF EXISTS driver_profiles_read_online ON driver_profiles;

      CREATE POLICY driver_profiles_owner_select ON driver_profiles
        FOR SELECT
        USING (auth.uid() = user_id);

      CREATE POLICY driver_profiles_owner_insert ON driver_profiles
        FOR INSERT
        WITH CHECK (auth.uid() = user_id);

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

DROP POLICY IF EXISTS rider_profiles_owner ON rider_profiles;
CREATE POLICY rider_profiles_owner ON rider_profiles
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_profiles_owner ON user_profiles;
CREATE POLICY user_profiles_owner ON user_profiles
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS emergency_contacts_owner ON emergency_contacts;
CREATE POLICY emergency_contacts_owner ON emergency_contacts
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS rides_select_participant ON rides;
CREATE POLICY rides_select_participant ON rides
  FOR SELECT
  USING (rider_id = auth.uid() OR driver_id = auth.uid());

DROP POLICY IF EXISTS rides_insert_rider ON rides;
CREATE POLICY rides_insert_rider ON rides
  FOR INSERT
  WITH CHECK (rider_id = auth.uid());

DROP POLICY IF EXISTS rides_update_participant ON rides;
CREATE POLICY rides_update_participant ON rides
  FOR UPDATE
  USING (rider_id = auth.uid() OR driver_id = auth.uid())
  WITH CHECK (rider_id = auth.uid() OR driver_id = auth.uid());

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

DROP POLICY IF EXISTS notifications_owner ON notifications;
CREATE POLICY notifications_owner ON notifications
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

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

-- ===== calculate_fare.sql =====

CREATE OR REPLACE FUNCTION calculate_fare(
  pickup_lat numeric,
  pickup_lng numeric,
  dropoff_lat numeric,
  dropoff_lng numeric,
  wilaya_name text
) RETURNS TABLE (
  distance_km double precision,
  duration_minutes double precision,
  calculated_fare numeric
) AS $$
DECLARE
  earth_radius_km double precision := 6371.0;
  lat1 double precision := radians(pickup_lat::double precision);
  lon1 double precision := radians(pickup_lng::double precision);
  lat2 double precision := radians(dropoff_lat::double precision);
  lon2 double precision := radians(dropoff_lng::double precision);
  dlat double precision := lat2 - lat1;
  dlon double precision := lon2 - lon1;
  a double precision;
  c double precision;
  fs RECORD;
  base numeric;
  per_km numeric;
  per_min numeric;
  min_f numeric;
  night_multiplier_val numeric := 1.0;
  now_local time := (now() at time zone 'UTC')::time;
BEGIN
  a := sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlon/2)^2;
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  distance_km := earth_radius_km * c;

  SELECT base_fare, per_km_rate, per_min_rate, min_fare, night_multiplier, night_start, night_end
    INTO fs
    FROM fare_settings
    WHERE wilaya = wilaya_name
    LIMIT 1;

  IF FOUND THEN
    base := COALESCE(fs.base_fare, 0);
    per_km := COALESCE(fs.per_km_rate, 0);
    per_min := COALESCE(fs.per_min_rate, 0);
    min_f := COALESCE(fs.min_fare, 0);
    night_multiplier_val := COALESCE(fs.night_multiplier, 1.0);
    IF fs.night_start IS NOT NULL AND fs.night_end IS NOT NULL THEN
      IF fs.night_start < fs.night_end THEN
        IF now_local >= fs.night_start AND now_local < fs.night_end THEN
          night_multiplier_val := fs.night_multiplier;
        END IF;
      ELSE
        IF now_local >= fs.night_start OR now_local < fs.night_end THEN
          night_multiplier_val := fs.night_multiplier;
        END IF;
      END IF;
    END IF;
  ELSE
    base := 70;
    per_km := 18;
    per_min := 3.5;
    min_f := 100;
    night_multiplier_val := 1.5;
  END IF;

  duration_minutes := (distance_km / 30.0) * 60.0;
  calculated_fare := base + (distance_km * per_km) + (duration_minutes * per_min);
  calculated_fare := calculated_fare * night_multiplier_val;

  IF calculated_fare < min_f THEN
    calculated_fare := min_f;
  ELSE
    calculated_fare := round(calculated_fare::numeric, 2);
  END IF;

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql STABLE;

-- ===== seed_fare_settings.sql =====

WITH wilayas(w) AS (
  VALUES
  ('Adrar'),('Chlef'),('Laghouat'),('Oum El Bouaghi'),('Batna'),('Béjaïa'),('Biskra'),('Béchar'),('Blida'),
  ('Bouira'),('Tamanrasset'),('Tébessa'),('Tlemcen'),('Tiaret'),('Tizi Ouzou'),('Algiers'),('Djelfa'),('Jijel'),
  ('Sétif'),('Saïda'),('Skikda'),('Sidi Bel Abbès'),('Annaba'),('Guelma'),('Constantine'),('Médéa'),('Mostaganem'),
  ('M''Sila'),('Mascara'),('Ouargla'),('Oran'),('El Bayadh'),('Illizi'),('Bordj Bou Arreridj'),('Boumerdès'),
  ('El Tarf'),('Tindouf'),('Tissemsilt'),('El Oued'),('Khenchela'),('Souk Ahras'),('Tipaza'),('Mila'),
  ('Aïn Defla'),('Naâma'),('Aïn Témouchent'),('Ghardaïa'),('Relizane'),('Timimoun'),('Bordj Badji Mokhtar'),
  ('Ouled Djellal'),('Béni Abbès'),('In Salah'),('In Guezzam'),('Touggourt'),('El M''Ghair'),('El Meniaa')
)
INSERT INTO fare_settings(wilaya, base_fare, per_km_rate, per_min_rate, min_fare, night_multiplier, night_start, night_end)
SELECT
  w,
  CASE
    WHEN w IN ('Algiers','Oran','Constantine') THEN 100
    WHEN w IN ('Annaba','Blida','Sétif','Batna','Béjaïa','Jijel','Skikda','Tlemcen','Mostaganem','Sidi Bel Abbès','Mascara','Boumerdès','Guelma','Médéa','Ouargla') THEN 80
    ELSE 70
  END AS base_fare,
  CASE
    WHEN w IN ('Algiers','Oran','Constantine') THEN 25
    WHEN w IN ('Annaba','Blida','Sétif','Batna','Béjaïa','Jijel','Skikda','Tlemcen','Mostaganem','Sidi Bel Abbès','Mascara','Boumerdès','Guelma','Médéa','Ouargla') THEN 20
    ELSE 18
  END AS per_km_rate,
  CASE
    WHEN w IN ('Algiers','Oran','Constantine') THEN 5
    WHEN w IN ('Annaba','Blida','Sétif','Batna','Béjaïa','Jijel','Skikda','Tlemcen','Mostaganem','Sidi Bel Abbès','Mascara','Boumerdès','Guelma','Médéa','Ouargla') THEN 4
    ELSE 3.5
  END AS per_min_rate,
  CASE
    WHEN w IN ('Algiers','Oran','Constantine') THEN 150
    WHEN w IN ('Annaba','Blida','Sétif','Batna','Béjaïa','Jijel','Skikda','Tlemcen','Mostaganem','Sidi Bel Abbès','Mascara','Boumerdès','Guelma','Médéa','Ouargla') THEN 120
    ELSE 100
  END AS min_fare,
  1.5 AS night_multiplier,
  '22:00'::time AS night_start,
  '06:00'::time AS night_end
FROM wilayas
ON CONFLICT (wilaya) DO UPDATE SET
  base_fare = EXCLUDED.base_fare,
  per_km_rate = EXCLUDED.per_km_rate,
  per_min_rate = EXCLUDED.per_min_rate,
  min_fare = EXCLUDED.min_fare,
  night_multiplier = EXCLUDED.night_multiplier,
  night_start = EXCLUDED.night_start,
  night_end = EXCLUDED.night_end;
