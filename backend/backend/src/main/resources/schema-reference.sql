-- 1. Create Colleges Table
CREATE TABLE IF NOT EXISTS colleges (
    college_id BIGSERIAL PRIMARY KEY,
    college_name VARCHAR(255) NOT NULL,
    college_type VARCHAR(100),
    district VARCHAR(100),
    city VARCHAR(100),
    hostel_available BOOLEAN DEFAULT FALSE,
    transport_available BOOLEAN DEFAULT FALSE
);

-- 2. Create Branch Master Table
CREATE TABLE IF NOT EXISTS branch_master (
    branch_code VARCHAR(50) PRIMARY KEY,
    branch_name VARCHAR(255) NOT NULL
);

-- 3. Create Cutoff History Table (Community-wise Cutoff)
CREATE TABLE IF NOT EXISTS cutoff_history (
    college_id BIGINT NOT NULL,
    branch_code VARCHAR(50) NOT NULL,
    oc DOUBLE PRECISION,
    bc DOUBLE PRECISION,
    bcm DOUBLE PRECISION,
    mbc DOUBLE PRECISION,
    sc DOUBLE PRECISION,
    sca DOUBLE PRECISION,
    st DOUBLE PRECISION,
    PRIMARY KEY (college_id, branch_code),
    CONSTRAINT fk_college FOREIGN KEY(college_id) REFERENCES colleges(college_id) ON DELETE CASCADE,
    CONSTRAINT fk_branch FOREIGN KEY(branch_code) REFERENCES branch_master(branch_code) ON DELETE CASCADE
);

-- CREATE INDEXES for performance
CREATE INDEX IF NOT EXISTS idx_cutoff_oc ON cutoff_history(oc);
CREATE INDEX IF NOT EXISTS idx_cutoff_bc ON cutoff_history(bc);
CREATE INDEX IF NOT EXISTS idx_cutoff_mbc ON cutoff_history(mbc);

-- ============================================
-- SAMPLE DATA FOR TESTING
-- ============================================

-- Clear existing data (safe for Cloud SQL)
DELETE FROM cutoff_history WHERE 1=1;
DELETE FROM branch_master WHERE 1=1;
DELETE FROM colleges WHERE 1=1;

-- Reset sequences
ALTER SEQUENCE colleges_college_id_seq RESTART WITH 1;

-- Insert Sample Colleges
INSERT INTO colleges (college_name, college_type, district, city, hostel_available, transport_available)
VALUES 
    ('Anna University - MIT Campus', 'Engineering', 'Chennai', 'Chennai', true, true),
    ('Sri Sairam Institute of Technology', 'Engineering', 'Chennai', 'Chennai', true, true),
    ('SRM Institute of Science and Technology', 'Engineering', 'Kancheepuram', 'Chengalpattu', true, true),
    ('Vellore Institute of Technology', 'Engineering', 'Vellore', 'Vellore', true, true),
    ('IIT Madras', 'Engineering', 'Chennai', 'Chennai', true, true),
    ('NIT Trichy', 'Engineering', 'Tiruchirappalli', 'Tiruchirappalli', true, true),
    ('PSG College of Technology', 'Engineering', 'Coimbatore', 'Coimbatore', true, true),
    ('College of Engineering Guindy', 'Engineering', 'Chennai', 'Chennai', true, true),
    ('Saveetha Institute of Medical and Technical Sciences', 'Engineering', 'Chennai', 'Chennai', true, true),
    ('REC Trichy', 'Engineering', 'Tiruchirappalli', 'Tiruchirappalli', true, true);

-- Insert Sample Branches
INSERT INTO branch_master (branch_code, branch_name)
VALUES 
    ('CS', 'Computer Science Engineering'),
    ('EC', 'Electronics and Communication Engineering'),
    ('EE', 'Electrical and Electronics Engineering'),
    ('ME', 'Mechanical Engineering'),
    ('CE', 'Civil Engineering'),
    ('IT', 'Information Technology'),
    ('EI', 'Electronics and Instrumentation Engineering'),
    ('BT', 'Biotechnology'),
    ('AD', 'Artificial Intelligence and Data Science'),
    ('AU', 'Automobile Engineering');

-- Insert Sample Cutoff Data
INSERT INTO cutoff_history (college_id, branch_code, oc, bc, bcm, mbc, sc, sca, st)
SELECT 
    c.college_id, 
    b.branch_code,
    CASE WHEN b.branch_code = 'CS' THEN 198.5 WHEN b.branch_code = 'IT' THEN 195.0 WHEN b.branch_code = 'EC' THEN 190.0 ELSE 180.0 END,
    CASE WHEN b.branch_code = 'CS' THEN 185.0 WHEN b.branch_code = 'IT' THEN 180.0 WHEN b.branch_code = 'EC' THEN 175.0 ELSE 165.0 END,
    CASE WHEN b.branch_code = 'CS' THEN 180.0 WHEN b.branch_code = 'IT' THEN 175.0 WHEN b.branch_code = 'EC' THEN 170.0 ELSE 160.0 END,
    CASE WHEN b.branch_code = 'CS' THEN 182.0 WHEN b.branch_code = 'IT' THEN 177.0 WHEN b.branch_code = 'EC' THEN 172.0 ELSE 162.0 END,
    CASE WHEN b.branch_code = 'CS' THEN 175.0 WHEN b.branch_code = 'IT' THEN 170.0 WHEN b.branch_code = 'EC' THEN 165.0 ELSE 155.0 END,
    CASE WHEN b.branch_code = 'CS' THEN 172.0 WHEN b.branch_code = 'IT' THEN 167.0 WHEN b.branch_code = 'EC' THEN 162.0 ELSE 152.0 END,
    CASE WHEN b.branch_code = 'CS' THEN 170.0 WHEN b.branch_code = 'IT' THEN 165.0 WHEN b.branch_code = 'EC' THEN 160.0 ELSE 150.0 END
FROM colleges c 
CROSS JOIN branch_master b
WHERE c.college_id <= 5;
