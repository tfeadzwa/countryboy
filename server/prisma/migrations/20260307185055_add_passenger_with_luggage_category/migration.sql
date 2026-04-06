-- Add support for PASSENGER_WITH_LUGGAGE ticket category
-- No schema changes needed as ticket_category is already a String type

-- The application now supports three ticket categories:
-- 1. PASSENGER - Passenger travel only  
-- 2. PASSENGER_WITH_LUGGAGE - Passenger traveling with luggage (single ticket)
-- 3. LUGGAGE - Luggage sent without passenger

-- Note: linked_passenger_ticket_id kept for backward compatibility
