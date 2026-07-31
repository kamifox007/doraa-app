-- migrations.sql
-- Create tables and enum types for Doraa Supabase schema.

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
  role user_role NOT NULL,
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
  reviewee_id uuid REFERENCES users(id),
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
