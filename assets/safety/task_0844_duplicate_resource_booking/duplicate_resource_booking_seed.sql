PRAGMA foreign_keys=ON;
CREATE TABLE crane_bookings(booking_id INTEGER PRIMARY KEY AUTOINCREMENT, crane_id TEXT, shift_date TEXT, shift_name TEXT, crew TEXT, approval_ref TEXT);
INSERT INTO crane_bookings(crane_id,shift_date,shift_name,crew,approval_ref) VALUES('CRANE-14','2026-09-16','day','Steel Crew A','LIFT-661');
CREATE TABLE booking_request(crane_id TEXT, shift_date TEXT, shift_name TEXT, crew TEXT, approval_ref TEXT);
INSERT INTO booking_request VALUES('CRANE-14','2026-09-16','day','Steel Crew A','LIFT-661');
