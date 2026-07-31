-- calculate_fare.sql
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
