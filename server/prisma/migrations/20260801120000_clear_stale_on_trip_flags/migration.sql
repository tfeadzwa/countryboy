-- Cashier end-trip historically left fleet/driver on_trip=true after the trip
-- became ENDED. Clear sticky flags for any fleet/driver with no ACTIVE trip.
UPDATE "tblFleets" f
SET on_trip = false
WHERE f.on_trip = true
  AND NOT EXISTS (
    SELECT 1
    FROM "tblTrips" t
    WHERE t.fleet_id = f.id
      AND t.status = 'ACTIVE'
  );

UPDATE "tblDrivers" d
SET on_trip = false
WHERE d.on_trip = true
  AND NOT EXISTS (
    SELECT 1
    FROM "tblTrips" t
    WHERE t.driver_id = d.id
      AND t.status = 'ACTIVE'
  );
