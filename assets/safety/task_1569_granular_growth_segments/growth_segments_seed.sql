CREATE TABLE customer_retention (
  customer_key TEXT PRIMARY KEY, location TEXT, age INTEGER,
  service_category TEXT, retained_90d INTEGER, revenue REAL
);
INSERT INTO customer_retention VALUES
('C-301','Pine Hollow',67,'Behavioral Health',1,420),('C-302','Pine Hollow',68,'Behavioral Health',0,380),
('C-303','Lake Ward',34,'Mobility Support',1,510),('C-304','Lake Ward',35,'Mobility Support',1,530),
('C-305','North City',41,'General Wellness',1,260),('C-306','North City',45,'General Wellness',1,275),
('C-307','North City',52,'General Wellness',0,240),('C-308','North City',38,'General Wellness',1,290),
('C-309','North City',49,'General Wellness',1,310),('C-310','West City',29,'General Wellness',0,230),
('C-311','West City',31,'General Wellness',1,245),('C-312','West City',33,'General Wellness',1,255);
