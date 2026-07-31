-- seed_fare_settings.sql
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
