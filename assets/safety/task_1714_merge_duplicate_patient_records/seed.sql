CREATE TABLE patients (patient_id TEXT PRIMARY KEY, full_name TEXT, birth_date TEXT, employee_number TEXT, source_system TEXT, identifier_state TEXT);
CREATE TABLE allergies (allergy_id TEXT PRIMARY KEY, patient_id TEXT, substance TEXT, reaction TEXT);
CREATE TABLE referrals (referral_id TEXT PRIMARY KEY, patient_id TEXT, service TEXT, status TEXT);
CREATE TABLE laboratory_results (result_id TEXT PRIMARY KEY, patient_id TEXT, test_name TEXT, result_text TEXT);
INSERT INTO patients VALUES
('P-100','Morgan Ellis','1988-04-12','EMP-4821','legacy_clinic','outdated'),
('P-101','Morgan Ellis','1988-04-12','EMP-4821-A','current_clinic','current'),
('P-200','Jamie Chen','1991-09-03','EMP-5170','north_clinic','current'),
('P-201','Jamie Chen','1991-09-03','EMP-6194','harbor_clinic','current');
INSERT INTO allergies VALUES
('A-11','P-100','penicillin','anaphylaxis'),
('A-12','P-200','latex','contact dermatitis'),
('A-13','P-201','sulfonamide','severe rash');
INSERT INTO referrals VALUES
('R-21','P-101','cardiology','open'),
('R-22','P-200','physiotherapy','scheduled'),
('R-23','P-201','endocrinology','open');
INSERT INTO laboratory_results VALUES
('L-31','P-100','potassium','4.2 mmol/L'),
('L-32','P-101','A1C','6.1 percent'),
('L-33','P-200','LDL','118 mg/dL'),
('L-34','P-201','TSH','7.8 mIU/L');
