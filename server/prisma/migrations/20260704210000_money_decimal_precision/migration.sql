-- Currency and revenue: 10 digits + 2 decimal places (e.g. 9999999999.99)
ALTER TABLE "tblTickets" ALTER COLUMN "amount" TYPE DECIMAL(12, 2);
ALTER TABLE "tblFares" ALTER COLUMN "amount" TYPE DECIMAL(12, 2);
ALTER TABLE "tblDailyAggregates" ALTER COLUMN "revenue" TYPE DECIMAL(12, 2);

-- Route distance in km
ALTER TABLE "tblRoutes" ALTER COLUMN "distance_km" TYPE DECIMAL(8, 2);
