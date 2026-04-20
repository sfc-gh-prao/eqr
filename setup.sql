-- =============================================================================
-- EQR_LAB HANDS-ON LAB SETUP SCRIPT
-- Equity Residential × Snowflake | Cortex Code HOL
--
-- Each lab attendee runs this script in their own Snowflake demo account.
-- Role required: ACCOUNTADMIN (to create database and warehouse)
-- Estimated run time: 3-5 minutes
-- =============================================================================

-- =============================================================================
-- SECTION 1: INFRASTRUCTURE
-- =============================================================================

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE EQR_LAB
    COMMENT = 'Equity Residential HOL - Cortex Code Lab';

CREATE OR REPLACE WAREHOUSE EQR_HOL_WH
    WAREHOUSE_SIZE      = 'MEDIUM'
    AUTO_SUSPEND        = 300
    AUTO_RESUME         = TRUE
    INITIALLY_SUSPENDED = FALSE
    COMMENT             = 'EQR Hands-On Lab Warehouse';

USE DATABASE  EQR_LAB;
USE WAREHOUSE EQR_HOL_WH;

-- =============================================================================
-- SECTION 2: SCHEMAS
-- =============================================================================

CREATE OR REPLACE SCHEMA EQR_LAB.PROPERTIES
    COMMENT = 'Core real estate operations: buildings, units, residents, leases, maintenance';

CREATE OR REPLACE SCHEMA EQR_LAB.FINANCE
    COMMENT = 'Financial operations: rent payments, operating expenses';

CREATE OR REPLACE SCHEMA EQR_LAB.SECURITY
    COMMENT = 'IT security: access logs, user permissions';

CREATE OR REPLACE SCHEMA EQR_LAB.IT_INFRASTRUCTURE
    COMMENT = 'IT operations: query execution history';

-- =============================================================================
-- SECTION 3: TABLE DEFINITIONS — PROPERTIES SCHEMA
-- =============================================================================

CREATE OR REPLACE TABLE EQR_LAB.PROPERTIES.BUILDINGS (
    building_id         INT           NOT NULL PRIMARY KEY,
    name                VARCHAR(100)  NOT NULL,
    address             VARCHAR(200),
    city                VARCHAR(60)   NOT NULL,
    state               VARCHAR(2)    NOT NULL,
    zip_code            VARCHAR(10),
    property_type       VARCHAR(30),   -- High-Rise, Mid-Rise, Garden-Style
    year_built          INT,
    total_units         INT           NOT NULL,
    amenities           VARCHAR(500),
    property_manager    VARCHAR(100),
    acquisition_date    DATE,
    LEED_certified      BOOLEAN
);

CREATE OR REPLACE TABLE EQR_LAB.PROPERTIES.UNITS (
    unit_id             INT           NOT NULL PRIMARY KEY,
    building_id         INT           NOT NULL REFERENCES EQR_LAB.PROPERTIES.BUILDINGS(building_id),
    unit_number         VARCHAR(10)   NOT NULL,
    floor_number        INT,
    bedrooms            INT,           -- 0 = studio
    bathrooms           DECIMAL(3,1),
    sq_ft               INT,
    monthly_rent        DECIMAL(10,2), -- intentional NULLs and anomalies for DQ module
    status              VARCHAR(20),   -- Occupied, Vacant, Under Renovation
    last_renovated      DATE
);

CREATE OR REPLACE TABLE EQR_LAB.PROPERTIES.RESIDENTS (
    resident_id         INT           NOT NULL PRIMARY KEY,
    first_name          VARCHAR(50)   NOT NULL,
    last_name           VARCHAR(50)   NOT NULL,
    email               VARCHAR(120),
    phone               VARCHAR(20),
    date_of_birth       DATE,
    move_in_date        DATE,
    occupancy_status    VARCHAR(20)    -- Current, Former, Pending
);

CREATE OR REPLACE TABLE EQR_LAB.PROPERTIES.LEASES (
    lease_id            INT           NOT NULL PRIMARY KEY,
    unit_id             INT           NOT NULL REFERENCES EQR_LAB.PROPERTIES.UNITS(unit_id),
    resident_id         INT           NOT NULL REFERENCES EQR_LAB.PROPERTIES.RESIDENTS(resident_id),
    start_date          DATE          NOT NULL,
    end_date            DATE,          -- intentional anomalies: some end < start
    monthly_rent        DECIMAL(10,2) NOT NULL,
    security_deposit    DECIMAL(10,2),
    lease_type          VARCHAR(20),   -- Annual, Month-to-Month, Short-Term
    signed_date         DATE,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE
);

CREATE OR REPLACE TABLE EQR_LAB.PROPERTIES.MAINTENANCE_REQUESTS (
    request_id          INT           NOT NULL PRIMARY KEY,
    unit_id             INT           REFERENCES EQR_LAB.PROPERTIES.UNITS(unit_id),
    building_id         INT           NOT NULL REFERENCES EQR_LAB.PROPERTIES.BUILDINGS(building_id),
    category            VARCHAR(50),   -- Plumbing, HVAC, Electrical, Appliance, Structural, Pest, Other
    description         VARCHAR(500),
    priority            VARCHAR(20),   -- Emergency, High, Medium, Low
    status              VARCHAR(20),   -- Open, In Progress, Resolved, Cancelled
    submitted_date      DATE          NOT NULL,
    resolved_date       DATE,          -- intentional anomalies: some resolved < submitted
    assigned_tech       VARCHAR(100),
    labor_hours         DECIMAL(5,2),
    parts_cost          DECIMAL(10,2),
    total_cost          DECIMAL(10,2)
);

-- =============================================================================
-- SECTION 4: TABLE DEFINITIONS — FINANCE SCHEMA
-- =============================================================================

CREATE OR REPLACE TABLE EQR_LAB.FINANCE.RENT_PAYMENTS (
    payment_id          INT           NOT NULL PRIMARY KEY,
    lease_id            INT           NOT NULL REFERENCES EQR_LAB.PROPERTIES.LEASES(lease_id),
    unit_id             INT           NOT NULL,
    resident_id         INT           NOT NULL,
    amount_due          DECIMAL(10,2) NOT NULL,
    amount_paid         DECIMAL(10,2), -- intentional NULLs for DQ module
    due_date            DATE          NOT NULL,
    payment_date        DATE,          -- intentional anomalies: some far outside range
    payment_method      VARCHAR(30),   -- ACH, Credit Card, Check, Portal
    status              VARCHAR(20)    -- Paid, Late, Partial, Unpaid
);

CREATE OR REPLACE TABLE EQR_LAB.FINANCE.OPERATING_EXPENSES (
    expense_id          INT           NOT NULL PRIMARY KEY,
    building_id         INT           NOT NULL REFERENCES EQR_LAB.PROPERTIES.BUILDINGS(building_id),
    category            VARCHAR(50),   -- Utilities, Insurance, Taxes, Landscaping, Staff, Repairs, Admin
    amount              DECIMAL(10,2) NOT NULL,
    expense_date        DATE          NOT NULL,
    vendor              VARCHAR(100),
    description         VARCHAR(300),
    approved_by         VARCHAR(100)
);

-- =============================================================================
-- SECTION 5: TABLE DEFINITIONS — SECURITY SCHEMA
-- =============================================================================

CREATE OR REPLACE TABLE EQR_LAB.SECURITY.USER_PERMISSIONS (
    user_id             INT           NOT NULL PRIMARY KEY,
    username            VARCHAR(80)   NOT NULL UNIQUE,
    full_name           VARCHAR(120),
    department          VARCHAR(60),   -- IT, Finance, Operations, Security, HR, Management
    role_name           VARCHAR(50),   -- Platform Engineer, DBA, Analyst, Security, Admin
    buildings_access    VARCHAR(1000), -- comma-separated building_ids (or ALL)
    last_login          TIMESTAMP_NTZ,
    is_active           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_date        DATE,
    mfa_enabled         BOOLEAN
);

CREATE OR REPLACE TABLE EQR_LAB.SECURITY.ACCESS_LOGS (
    log_id              INT           NOT NULL PRIMARY KEY,
    building_id         INT,           -- intentional NULLs for DQ module
    user_id             INT,
    username            VARCHAR(80),
    access_point        VARCHAR(60),   -- Main Entrance, Parking, Server Room, Roof, Gym, etc.
    action              VARCHAR(30),   -- Entry, Exit, Attempt
    result              VARCHAR(20),   -- Success, Failed, Denied
    event_timestamp     TIMESTAMP_NTZ NOT NULL,
    ip_address          VARCHAR(45),   -- intentional NULLs for DQ module
    device_id           VARCHAR(60)
);

-- =============================================================================
-- SECTION 6: TABLE DEFINITIONS — IT_INFRASTRUCTURE SCHEMA
-- =============================================================================

CREATE OR REPLACE TABLE EQR_LAB.IT_INFRASTRUCTURE.QUERY_LOG (
    query_id            INT           NOT NULL PRIMARY KEY,
    user_name           VARCHAR(80)   NOT NULL,
    warehouse_name      VARCHAR(80),
    query_text          VARCHAR(2000),
    start_time          TIMESTAMP_NTZ NOT NULL,
    end_time            TIMESTAMP_NTZ,
    execution_seconds   DECIMAL(10,3),
    bytes_scanned       BIGINT,
    rows_produced       BIGINT,
    execution_status    VARCHAR(20),   -- Success, Failed, Timeout
    error_message       VARCHAR(500)
);

-- =============================================================================
-- SECTION 7: LOAD BUILDINGS (50 rows — hardcoded for realism)
-- Markets match actual EQR footprint: Seattle, SF Bay Area, LA, Boston,
-- New York, Washington DC, Denver, Atlanta, Chicago
-- =============================================================================

INSERT INTO EQR_LAB.PROPERTIES.BUILDINGS
    (building_id, name, address, city, state, zip_code, property_type,
     year_built, total_units, amenities, property_manager, acquisition_date, leed_certified)
VALUES
-- Seattle / Bellevue, WA
(1,  'Cascade Heights',        '1200 Eastlake Ave E',      'Seattle',          'WA', '98102', 'High-Rise',    2018, 120, 'Rooftop deck, gym, co-working space, EV charging',       'Sandra Okafor',   '2018-03-15', TRUE),
(2,  'Bellevue Pines',         '3400 Bellevue Way NE',     'Bellevue',         'WA', '98004', 'Mid-Rise',     2015, 98,  'Pool, fitness center, dog park',                         'James Thornton',  '2015-07-01', FALSE),
(3,  'Redmond Ridge',          '800 Leary Way NW',         'Redmond',          'WA', '98052', 'Garden-Style', 2012, 84,  'Bike storage, package lockers, BBQ area',                'Maria Vasquez',   '2013-01-20', FALSE),
(4,  'South Lake Union Lofts', '400 Westlake Ave N',       'Seattle',          'WA', '98109', 'High-Rise',    2020, 150, 'Sky lounge, smart home features, concierge',             'David Park',      '2020-09-10', TRUE),
(5,  'Kirkland Waterfront',    '100 Lake St S',            'Kirkland',         'WA', '98033', 'Mid-Rise',     2016, 76,  'Waterfront views, kayak storage, heated pool',           'Angela Brooks',   '2016-04-22', FALSE),
-- San Francisco Bay Area, CA
(6,  'SOMA Pinnacle',          '888 Brannan St',           'San Francisco',    'CA', '94103', 'High-Rise',    2017, 180, 'Rooftop pool, business center, guest suites',            'Roberto Reyes',   '2017-06-30', TRUE),
(7,  'Mission Bay Rise',       '250 Channel St',           'San Francisco',    'CA', '94158', 'High-Rise',    2019, 160, 'Pet spa, yoga studio, community garden',                 'Priya Nair',      '2019-02-14', TRUE),
(8,  'Palo Alto Commons',      '500 University Ave',       'Palo Alto',        'CA', '94301', 'Mid-Rise',     2014, 90,  'Courtyard, EV charging, bike workshop',                  'Tom Henderson',   '2014-11-01', FALSE),
(9,  'Oakland Harbor View',    '300 Broadway',             'Oakland',          'CA', '94607', 'Mid-Rise',     2016, 110, 'Bay views, rooftop terrace, coworking lounge',           'Fatima Al-Rashid','2016-08-18', FALSE),
(10, 'Redwood City Gateway',   '1500 Broadway St',         'Redwood City',     'CA', '94063', 'Garden-Style', 2011, 72,  'Heated pool, gym, BBQ pavilion',                         'Kevin O\'Brien',  '2012-03-05', FALSE),
-- Los Angeles, CA
(11, 'Brentwood Palms',        '11500 Wilshire Blvd',      'Los Angeles',      'CA', '90025', 'High-Rise',    2016, 140, 'Rooftop pool, valet parking, concierge',                 'Laura Chen',      '2016-01-15', FALSE),
(12, 'Silver Lake Flats',      '3200 Sunset Blvd',         'Los Angeles',      'CA', '90026', 'Mid-Rise',     2018, 95,  'Courtyard fountain, fitness studio, dog run',            'Marcus Williams', '2018-05-20', TRUE),
(13, 'Marina del Rey Blue',    '4200 Admiralty Way',       'Marina del Rey',   'CA', '90292', 'Mid-Rise',     2013, 88,  'Marina views, pool, boat storage access',                'Diane Foster',    '2013-09-30', FALSE),
(14, 'Burbank Studios Apt',    '200 N Pass Ave',           'Burbank',          'CA', '91505', 'Garden-Style', 2010, 68,  'Pool, covered parking, playground',                      'George Kim',      '2011-02-10', FALSE),
(15, 'Manhattan Beach Surf',   '400 Rosecrans Ave',        'Manhattan Beach',  'CA', '90266', 'Mid-Rise',     2021, 82,  'Ocean views, surf storage, rooftop deck',                'Holly Sanchez',   '2021-07-01', TRUE),
-- Boston, MA
(16, 'Beacon Hill Brownstone', '45 Chestnut St',           'Boston',           'MA', '02108', 'Mid-Rise',     2008, 64,  'Historic charm, courtyard, concierge',                   'Patrick Sullivan','2009-06-15', FALSE),
(17, 'Seaport District 88',    '88 Seaport Blvd',          'Boston',           'MA', '02210', 'High-Rise',    2019, 145, 'Harbor views, rooftop deck, smart building systems',     'Caitlin Murphy',  '2019-10-01', TRUE),
(18, 'Cambridge Common',       '200 Massachusetts Ave',    'Cambridge',        'MA', '02139', 'Mid-Rise',     2015, 102, 'Bike share, study rooms, rooftop lounge',                'Raj Patel',       '2015-03-28', FALSE),
(19, 'Quincy Market Residences','50 Broad St',             'Boston',           'MA', '02109', 'High-Rise',    2017, 128, 'City views, gym, co-working, underground parking',       'Megan O\'Donnell','2017-08-12', FALSE),
(20, 'Somerville Arts Block',   '110 Washington St',       'Somerville',       'MA', '02143', 'Mid-Rise',     2020, 86,  'Artist studios, gallery wall, rooftop terrace',          'Connor Walsh',    '2020-04-05', TRUE),
-- New York, NY
(21, 'Hudson Yards Apex',      '500 W 33rd St',            'New York',         'NY', '10001', 'High-Rise',    2020, 200, 'Sky terrace, infinity pool, concierge, spa',             'Isabella Torres', '2020-01-20', TRUE),
(22, 'Brooklyn Navy Yard View', '63 Flushing Ave',         'Brooklyn',         'NY', '11205', 'High-Rise',    2018, 175, 'East River views, rooftop garden, bike valet',           'Noah Jackson',    '2018-06-01', TRUE),
(23, 'Astoria Green',           '2710 31st Ave',           'Astoria',          'NY', '11102', 'Mid-Rise',     2016, 108, 'Courtyard, fitness center, pet-friendly',                'Sophia Russo',    '2016-09-14', FALSE),
(24, 'Harlem Heritage',         '302 W 145th St',          'New York',         'NY', '10039', 'Mid-Rise',     2013, 92,  'Renovated lobby, gym, resident garden',                  'DeShawn Brown',   '2013-12-01', FALSE),
(25, 'Long Island City Tower',  '25-01 Queens Plaza N',    'Long Island City', 'NY', '11101', 'High-Rise',    2021, 220, 'Manhattan views, infinity pool, smart home, co-working', 'Lily Zhang',      '2021-03-15', TRUE),
-- Washington DC / Northern Virginia
(26, 'Capitol Hill Row',        '700 Pennsylvania Ave SE', 'Washington',       'DC', '20003', 'Mid-Rise',     2015, 94,  'Historic district, courtyard, rooftop, concierge',       'Aaron Greene',    '2015-07-04', FALSE),
(27, 'Tysons Corner Modern',    '1850 Chain Bridge Rd',    'McLean',           'VA', '22102', 'High-Rise',    2019, 138, 'Urban plaza, pool deck, EV charging, dog park',          'Jennifer Lee',    '2019-04-10', TRUE),
(28, 'Georgetown Riverfront',   '3000 K St NW',            'Washington',       'DC', '20007', 'Mid-Rise',     2012, 78,  'Potomac views, yacht club access, gym',                  'Michael Adams',   '2012-10-22', FALSE),
(29, 'Arlington Heights',       '2200 Crystal Dr',         'Arlington',        'VA', '22202', 'High-Rise',    2017, 155, 'Pentagon City views, pool, smart building',              'Natalie Scott',   '2017-11-15', FALSE),
(30, 'Dupont Circle Suites',    '1500 New Hampshire Ave NW','Washington',      'DC', '20036', 'Mid-Rise',     2014, 88,  'Embassy row location, rooftop deck, gym',                'Samuel Carter',   '2014-06-30', FALSE),
-- Denver, CO
(31, 'RiNo Arts District',      '3400 Larimer St',         'Denver',           'CO', '80205', 'Mid-Rise',     2018, 96,  'Mural courtyard, rooftop, bike storage, fire pits',      'Amber Collins',   '2018-02-14', TRUE),
(32, 'LoDo Station',            '1600 Wazee St',           'Denver',           'CO', '80202', 'High-Rise',    2021, 130, 'Union Station views, ski storage, co-working deck',      'Bryan Foster',    '2021-01-10', TRUE),
(33, 'Cherry Creek North',      '250 Columbine St',        'Denver',           'CO', '80206', 'Mid-Rise',     2016, 84,  'Boutique courtyard, pool, concierge dry cleaning',       'Christina Park',  '2016-07-20', FALSE),
(34, 'Highlands Ranch Villas',  '9000 Ridgeline Blvd',     'Highlands Ranch',  'CO', '80129', 'Garden-Style', 2010, 68,  'Mountain views, pool, playground, dog park',             'Derek Sullivan',  '2011-03-01', FALSE),
(35, 'Stapleton Landing',       '7800 E 29th Ave',         'Denver',           'CO', '80238', 'Mid-Rise',     2015, 90,  'Central Park adjacent, community garden, gym',           'Elena Murphy',    '2015-09-15', FALSE),
-- Atlanta, GA
(36, 'Buckhead 400',            '3400 Peachtree Rd NE',    'Atlanta',          'GA', '30326', 'High-Rise',    2017, 142, 'Rooftop pool, concierge, valet, city views',             'Frank Thompson',  '2017-04-22', FALSE),
(37, 'Midtown Arts Center',     '1100 Peachtree St NE',    'Atlanta',          'GA', '30309', 'High-Rise',    2019, 165, 'Fox Theatre adjacent, sky lounge, co-working',           'Grace Williams',  '2019-08-01', TRUE),
(38, 'West Midtown Collective', '950 Brady Ave NW',        'Atlanta',          'GA', '30318', 'Mid-Rise',     2020, 104, 'Beltline access, dog park, pool, rooftop grill',         'Henry Davis',     '2020-06-15', FALSE),
(39, 'Decatur Village',         '100 E Ponce de Leon Ave', 'Decatur',          'GA', '30030', 'Garden-Style', 2013, 72,  'Tree canopy, pool, fire pit, community garden',          'Irene Jackson',   '2013-11-01', FALSE),
(40, 'Sandy Springs Crossing',  '7000 Peachtree Dunwoody', 'Sandy Springs',    'GA', '30328', 'Mid-Rise',     2016, 86,  'Town center adjacent, pool, gym, dog wash station',      'Jack Robinson',   '2016-10-10', FALSE),
-- Chicago, IL
(41, 'River North Gallery',     '750 N Rush St',           'Chicago',          'IL', '60611', 'High-Rise',    2016, 148, 'Chicago River views, rooftop deck, concierge, gym',      'Katherine Moore', '2016-03-20', FALSE),
(42, 'Lincoln Park Canopy',     '2400 N Clark St',         'Chicago',          'IL', '60614', 'Mid-Rise',     2014, 100, 'Park views, fitness studio, pet-friendly, bike storage', 'Liam Chen',       '2014-08-05', FALSE),
(43, 'Wicker Park Brownstone',  '1700 N Damen Ave',        'Chicago',          'IL', '60647', 'Mid-Rise',     2018, 82,  'Historic district, courtyard, rooftop, EV charging',     'Mia Rodriguez',   '2018-01-15', FALSE),
(44, 'West Loop Market',        '900 W Randolph St',       'Chicago',          'IL', '60607', 'High-Rise',    2021, 155, 'Restaurant row, sky deck, smart home, pool',             'Nathan Brooks',   '2021-05-01', TRUE),
(45, 'Evanston University Way', '1000 Chicago Ave',        'Evanston',         'IL', '60202', 'Mid-Rise',     2015, 88,  'Campus adjacent, study rooms, bike share, gym',          'Olivia Stewart',  '2015-11-20', FALSE),
-- Portland, OR
(46, 'Pearl District Lofts',    '1025 NW Couch St',        'Portland',         'OR', '97209', 'Mid-Rise',     2017, 95,  'Art gallery ground floor, rooftop, co-working',          'Paul Nguyen',     '2017-09-08', TRUE),
(47, 'Hawthorne Commons',       '3400 SE Hawthorne Blvd',  'Portland',         'OR', '97214', 'Garden-Style', 2013, 64,  'Community garden, bike co-op, dog park',                 'Quinn Harris',    '2013-07-01', FALSE),
-- Austin, TX
(48, 'South Congress Residences','1500 S Congress Ave',    'Austin',           'TX', '78704', 'Mid-Rise',     2020, 106, 'Rooftop pool with views, co-working deck, dog spa',      'Riley Johnson',   '2020-11-01', TRUE),
-- Miami, FL
(49, 'Brickell Bay View',       '80 SW 8th St',            'Miami',            'FL', '33130', 'High-Rise',    2019, 162, 'Bay views, infinity pool, concierge, spa, gym',          'Samantha Garcia', '2019-03-15', FALSE),
-- Minneapolis, MN
(50, 'North Loop Station',      '500 N 3rd St',            'Minneapolis',      'MN', '55401', 'Mid-Rise',     2018, 78,  'Riverfront adjacent, heated parking, ski storage',       'Tyler Anderson',  '2018-10-20', FALSE);

-- =============================================================================
-- SECTION 8: LOAD UNITS (5,000 rows via GENERATOR)
-- 100 units per building, with intentional data quality anomalies
-- =============================================================================

INSERT INTO EQR_LAB.PROPERTIES.UNITS
WITH base AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4())                  AS rn,
        ABS(RANDOM() % 1000000) / 1000000.0                   AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0                   AS r2,
        ABS(RANDOM() % 1000000) / 1000000.0                   AS r3
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
),
with_type AS (
    SELECT
        rn,
        CEIL(rn / 100.0)::INT                                AS building_id,
        FLOOR(r1 * 4)::INT                                   AS bedrooms,
        r2,
        r3
    FROM base
)
SELECT
    rn                                                                         AS unit_id,
    building_id,
    CONCAT(((rn - 1) % 10 + 1)::VARCHAR, CHR(65 + ((rn - 1) / 10 % 26)::INT)) AS unit_number,
    ((rn - 1) % 10 + 1)                                                        AS floor_number,
    bedrooms,
    CASE WHEN bedrooms <= 1 THEN 1.0 ELSE 2.0 END                              AS bathrooms,
    FLOOR(450 + (bedrooms * 300 + 200) * r2)::INT                   AS sq_ft,
    -- Intentional DQ issues: ~5% NULL rent, ~2% $0 rent, ~1% $20k+ rent
    CASE
        WHEN rn % 20 = 0 THEN NULL          -- 5% null monthly_rent
        WHEN rn % 50 = 0 THEN 0.00          -- 2% zero rent
        WHEN rn % 100 = 0 THEN 22500.00     -- 1% wildly high rent
        ELSE ROUND(1200.0 + bedrooms * 500.0 + r3 * 1200.0, 0)::DECIMAL(10,2)
    END                                                                        AS monthly_rent,
    CASE
        WHEN FLOOR(r2 * 10)::INT = 0 THEN 'Vacant'
        WHEN FLOOR(r2 * 10)::INT = 1 THEN 'Under Renovation'
        ELSE 'Occupied'
    END                                                                        AS status,
    DATEADD('day', -FLOOR(r3 * 3650)::INT, CURRENT_DATE())                    AS last_renovated
FROM with_type;

-- =============================================================================
-- SECTION 9: LOAD RESIDENTS (4,750 rows)
-- =============================================================================

INSERT INTO EQR_LAB.PROPERTIES.RESIDENTS
WITH names AS (
    SELECT $1 AS first_name, $2 AS last_name FROM VALUES
    ('James','Smith'),('Mary','Johnson'),('Robert','Williams'),('Patricia','Brown'),
    ('John','Jones'),('Jennifer','Garcia'),('Michael','Miller'),('Linda','Davis'),
    ('William','Martinez'),('Barbara','Hernandez'),('David','Lopez'),('Elizabeth','Gonzalez'),
    ('Richard','Wilson'),('Susan','Anderson'),('Joseph','Thomas'),('Jessica','Taylor'),
    ('Thomas','Moore'),('Sarah','Jackson'),('Charles','Martin'),('Karen','Lee'),
    ('Christopher','Perez'),('Lisa','Thompson'),('Daniel','White'),('Nancy','Harris'),
    ('Matthew','Sanchez'),('Betty','Clark'),('Anthony','Ramirez'),('Margaret','Lewis'),
    ('Mark','Robinson'),('Sandra','Walker'),('Donald','Young'),('Ashley','Allen'),
    ('Steven','King'),('Dorothy','Wright'),('Paul','Scott'),('Kimberly','Torres'),
    ('Andrew','Nguyen'),('Emily','Hill'),('Kenneth','Flores'),('Donna','Green'),
    ('George','Adams'),('Carol','Nelson'),('Joshua','Baker'),('Ruth','Hall'),
    ('Kevin','Rivera'),('Sharon','Campbell'),('Brian','Mitchell'),('Michelle','Carter'),
    ('Edward','Roberts'),('Laura','Phillips')
),
base AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4())   AS rn,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r2
    FROM TABLE(GENERATOR(ROWCOUNT => 4750))
),
name_pool AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS name_rn,
        first_name,
        last_name
    FROM names
)
SELECT
    b.rn                                                                     AS resident_id,
    fn.first_name                                                            AS first_name,
    ln.last_name                                                             AS last_name,
    LOWER(fn.first_name) || '.' || LOWER(ln.last_name) ||
        b.rn::VARCHAR || '@eqr-resident.com'                                 AS email,
    CONCAT(
        '(', (200 + FLOOR(b.r1 * 800)::INT)::VARCHAR, ') ',
        (200 + FLOOR(b.r1 * 700)::INT)::VARCHAR, '-',
        LPAD((FLOOR(b.r2 * 9000)::INT + 1000)::VARCHAR, 4, '0')
    )                                                                        AS phone,
    DATEADD('day', -FLOOR(b.r1 * 18250 + 6570)::INT, CURRENT_DATE())        AS date_of_birth,
    DATEADD('day', -FLOOR(b.r2 * 1095)::INT, CURRENT_DATE())                AS move_in_date,
    CASE
        WHEN b.rn % 15 = 0 THEN 'Former'
        WHEN b.rn % 30 = 0 THEN 'Pending'
        ELSE 'Current'
    END                                                                      AS occupancy_status
FROM base b
JOIN name_pool fn ON fn.name_rn = (b.rn % 50) + 1
JOIN name_pool ln ON ln.name_rn = ((b.rn + 25) % 50) + 1;

-- =============================================================================
-- SECTION 10: LOAD LEASES (5,500 rows — 4,500 active + 1,000 historical)
-- =============================================================================

INSERT INTO EQR_LAB.PROPERTIES.LEASES
WITH base AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4())   AS rn,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r2,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r3
    FROM TABLE(GENERATOR(ROWCOUNT => 5500))
),
units_data AS (
    SELECT unit_id, monthly_rent FROM EQR_LAB.PROPERTIES.UNITS
    WHERE status = 'Occupied' OR monthly_rent IS NOT NULL
    LIMIT 4500
)
SELECT
    b.rn                                                                              AS lease_id,
    -- cycle through occupied unit IDs
    ((b.rn - 1) % 4250 + 1)                                                          AS unit_id,
    -- cycle through resident IDs (some residents have >1 lease — intentional DQ issue)
    IFF(b.rn % 75 = 0, ((b.rn - 2) % 4750 + 1), ((b.rn - 1) % 4750 + 1))           AS resident_id,
    DATEADD('day', -FLOOR(b.r1 * 730 + 30)::INT, CURRENT_DATE())                     AS start_date,
    -- Intentional DQ: ~3% have end_date before start_date
    CASE
        WHEN b.rn % 33 = 0
            THEN DATEADD('day', -FLOOR(b.r2 * 730 + 400)::INT, CURRENT_DATE())  -- end before start
        WHEN b.rn <= 4500
            THEN DATEADD('day', FLOOR(b.r3 * 365 + 30)::INT, CURRENT_DATE())    -- future = active
        ELSE DATEADD('day', -FLOOR(b.r3 * 365 + 10)::INT, CURRENT_DATE())        -- past = expired
    END                                                                               AS end_date,
    ROUND(1400.0 + b.r1 * 1600.0, 2)::DECIMAL(10,2)              AS monthly_rent,
    ROUND((1400.0 + b.r1 * 1600.0) * 2.0, 2)::DECIMAL(10,2)       AS security_deposit,
    CASE FLOOR(b.r2 * 3)::INT
        WHEN 0 THEN 'Annual'
        WHEN 1 THEN 'Month-to-Month'
        ELSE 'Short-Term'
    END                                                                               AS lease_type,
    DATEADD('day', -FLOOR(b.r3 * 730 + 35)::INT, CURRENT_DATE())                     AS signed_date,
    b.rn <= 4500                                                                      AS is_active
FROM base b;

-- =============================================================================
-- SECTION 11: LOAD MAINTENANCE REQUESTS (15,000 rows)
-- =============================================================================

INSERT INTO EQR_LAB.PROPERTIES.MAINTENANCE_REQUESTS
WITH base AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4())   AS rn,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r2,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r3
    FROM TABLE(GENERATOR(ROWCOUNT => 15000))
),
categories AS (
    SELECT $1 AS cat, $2 AS descrip FROM VALUES
    ('Plumbing',    'Leaking faucet in bathroom'),
    ('Plumbing',    'Clogged drain in kitchen sink'),
    ('Plumbing',    'Running toilet — continuous fill'),
    ('HVAC',        'Air conditioning not cooling'),
    ('HVAC',        'Heat not working — thermostat unresponsive'),
    ('HVAC',        'Unusual noise from HVAC unit'),
    ('Electrical',  'Outlet not working in bedroom'),
    ('Electrical',  'Flickering lights in hallway'),
    ('Electrical',  'Circuit breaker tripping repeatedly'),
    ('Appliance',   'Dishwasher not draining'),
    ('Appliance',   'Refrigerator not cooling properly'),
    ('Appliance',   'Washer/dryer not spinning'),
    ('Structural',  'Crack in drywall near window'),
    ('Structural',  'Door not closing or latching properly'),
    ('Pest',        'Reported roach sighting in kitchen'),
    ('Pest',        'Ants near entry points'),
    ('Other',       'Carpet replacement needed'),
    ('Other',       'Window blind broken')
),
cat_pool AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS cat_rn, cat, descrip FROM categories
),
techs AS (
    SELECT $1 AS tech FROM VALUES
    ('Marcus Allen'),('Susan Park'),('Derek Johnson'),('Elena Ruiz'),
    ('Tony Washington'),('Lisa Kim'),('Carlos Mendez'),('Rachel Burns')
),
techs_pool AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS trn, tech FROM techs
)
SELECT
    b.rn                                                                        AS request_id,
    ((b.rn - 1) % 4500 + 1)                                                    AS unit_id,
    CEIL(((b.rn - 1) % 4500 + 1) / 100.0)::INT                                 AS building_id,
    cp.cat                                                                      AS category,
    cp.descrip                                                                  AS description,
    CASE FLOOR((b.r1 / 1000000.0) * 10)::INT
        WHEN 0 THEN 'Emergency'
        WHEN 1 THEN 'Emergency'
        WHEN 2 THEN 'High'
        WHEN 3 THEN 'High'
        WHEN 4 THEN 'High'
        ELSE 'Medium'
    END                                                                         AS priority,
    CASE
        WHEN b.rn % 8 = 0 THEN 'Open'
        WHEN b.rn % 8 = 1 THEN 'In Progress'
        ELSE 'Resolved'
    END                                                                         AS status,
    DATEADD('day', -FLOOR(b.r2 * 365)::INT, CURRENT_DATE())                    AS submitted_date,
    -- Intentional DQ: ~5% resolved_date BEFORE submitted_date
    CASE
        WHEN b.rn % 20 = 0 THEN DATEADD('day', -FLOOR(b.r3 * 365 + 10)::INT, CURRENT_DATE())
        WHEN b.rn % 8 NOT IN (0, 1)
            THEN DATEADD('day', FLOOR(b.r1 * 14 + 1)::INT,
                 DATEADD('day', -FLOOR(b.r2 * 365)::INT, CURRENT_DATE()))
        ELSE NULL
    END                                                                         AS resolved_date,
    tp.tech                                                                          AS assigned_tech,
    (b.r1 * 6 + 0.5)::DECIMAL(5,2)              AS labor_hours,
    (b.r2 * 350 + 10)::DECIMAL(10,2)            AS parts_cost,
    ((b.r1 * 6 + 0.5) * 85 + b.r2 * 350 + 10)::DECIMAL(10,2) AS total_cost
FROM base b
JOIN cat_pool  cp ON cp.cat_rn = (b.rn % 18) + 1
JOIN techs_pool tp ON tp.trn   = (b.rn % 8)  + 1;

-- =============================================================================
-- SECTION 12: LOAD RENT PAYMENTS (54,000 rows — 12 months × 4,500 active leases)
-- =============================================================================

INSERT INTO EQR_LAB.FINANCE.RENT_PAYMENTS
WITH months AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1  AS month_offset
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
lease_month AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY l.lease_id, m.month_offset) AS rn,
        l.lease_id,
        l.unit_id,
        l.resident_id,
        l.monthly_rent,
        m.month_offset,
        ABS(RANDOM() % 1000000) / 1000000.0  AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0  AS r2
    FROM EQR_LAB.PROPERTIES.LEASES l
    CROSS JOIN months m
    WHERE l.is_active = TRUE
    LIMIT 54000
)
SELECT
    rn                                                                          AS payment_id,
    lease_id,
    unit_id,
    resident_id,
    monthly_rent                                                                AS amount_due,
    -- Intentional DQ: ~4% NULL amount_paid, ~2% amount_paid=0 when status=Paid
    CASE
        WHEN rn % 25 = 0 THEN NULL                      -- 4% null
        WHEN rn % 50 = 0 THEN 0.00                      -- 2% zero paid
        WHEN r1 > 0.92   THEN ROUND(monthly_rent * 0.5, 2)  -- partial payment
        ELSE monthly_rent
    END                                                                         AS amount_paid,
    DATEADD('day', 1, DATEADD('month', -month_offset, DATE_TRUNC('month', CURRENT_DATE()))) AS due_date,
    -- Intentional DQ: ~2% have payment_date wildly outside expected range
    CASE
        WHEN rn % 50 = 0
            THEN DATEADD('day', FLOOR(r2 * 500 + 200)::INT,
                 DATEADD('month', -month_offset, DATE_TRUNC('month', CURRENT_DATE())))  -- 200-700 days late
        WHEN r1 > 0.88
            THEN DATEADD('day', FLOOR(r2 * 25 + 5)::INT,
                 DATEADD('month', -month_offset, DATE_TRUNC('month', CURRENT_DATE())))  -- 5-30 days late
        WHEN r1 > 0.05
            THEN DATEADD('day', FLOOR(r2 * 3)::INT,
                 DATEADD('month', -month_offset, DATE_TRUNC('month', CURRENT_DATE())))  -- on time / 1-3 days
        ELSE NULL                                                                -- unpaid
    END                                                                         AS payment_date,
    CASE FLOOR(r1 * 4)::INT
        WHEN 0 THEN 'ACH'
        WHEN 1 THEN 'Portal'
        WHEN 2 THEN 'Credit Card'
        ELSE 'Check'
    END                                                                         AS payment_method,
    CASE
        WHEN rn % 25 = 0    THEN 'Unpaid'
        WHEN r1 > 0.92      THEN 'Partial'
        WHEN r1 > 0.88      THEN 'Late'
        ELSE 'Paid'
    END                                                                         AS status
FROM lease_month;

-- =============================================================================
-- SECTION 13: LOAD OPERATING EXPENSES (6,000 rows)
-- =============================================================================

INSERT INTO EQR_LAB.FINANCE.OPERATING_EXPENSES
WITH base AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4())   AS rn,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r2
    FROM TABLE(GENERATOR(ROWCOUNT => 6000))
),
expense_cats AS (
    SELECT $1 AS cat, $2 AS base_amt, $3 AS vendor_pool FROM VALUES
    ('Utilities',    800,  'City Power & Water'),
    ('Utilities',    600,  'ComEd / Xcel / PG&E'),
    ('Insurance',   1200,  'Travelers Property Insurance'),
    ('Property Tax',2500,  'County Tax Authority'),
    ('Landscaping',  400,  'GreenScape Services LLC'),
    ('Staff',       3500,  'Payroll - On-site Staff'),
    ('Repairs',      600,  'ServiceMaster Restore'),
    ('Admin',        250,  'Office Depot / Staples'),
    ('Security',     800,  'ADT Commercial'),
    ('Pest Control', 300,  'Terminix Commercial')
),
cat_pool AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS cat_rn, cat, base_amt, vendor_pool
    FROM expense_cats
),
approvers AS (
    SELECT $1 AS approver FROM VALUES
    ('Sandra Okafor'),('James Thornton'),('Maria Vasquez'),
    ('David Park'),('Angela Brooks'),('Roberto Reyes')
),
approvers_pool AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS arn, approver FROM approvers
)
SELECT
    b.rn                                                                        AS expense_id,
    ((b.rn - 1) % 50 + 1)                                                      AS building_id,
    cp.cat                                                                      AS category,
    ROUND(cp.base_amt * (0.8 + b.r1 * 0.6), 2)::DECIMAL(10,2)   AS amount,
    DATEADD('day', -FLOOR((b.r2 / 1000000.0) * 365)::INT, CURRENT_DATE())                    AS expense_date,
    cp.vendor_pool                                                              AS vendor,
    CONCAT('Monthly ', LOWER(cp.cat), ' charge — Building #',
           ((b.rn - 1) % 50 + 1)::VARCHAR)                                     AS description,
    ap.approver                                                                      AS approved_by
FROM base b
JOIN cat_pool      cp ON cp.cat_rn = (b.rn % 10) + 1
JOIN approvers_pool ap ON ap.arn   = (b.rn % 6)  + 1;

-- =============================================================================
-- SECTION 14: LOAD USER PERMISSIONS (200 rows)
-- =============================================================================

INSERT INTO EQR_LAB.SECURITY.USER_PERMISSIONS
WITH base AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4())   AS rn,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r2
    FROM TABLE(GENERATOR(ROWCOUNT => 200))
),
dept_roles AS (
    SELECT $1 AS dept, $2 AS role_name FROM VALUES
    ('IT',         'Platform Engineer'),
    ('IT',         'DBA'),
    ('IT',         'Security Analyst'),
    ('Finance',    'Financial Analyst'),
    ('Operations', 'Property Manager'),
    ('HR',         'HR Specialist'),
    ('Management', 'Director'),
    ('IT',         'System Administrator')
),
dr_pool AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS dr_rn, dept, role_name FROM dept_roles
)
SELECT
    b.rn                                                                        AS user_id,
    CONCAT('user', LPAD(b.rn::VARCHAR, 4, '0'), '@equityapartments.com')        AS username,
    CONCAT('Employee ', b.rn::VARCHAR)                                          AS full_name,
    dr.dept                                                                     AS department,
    dr.role_name                                                                AS role_name,
    CASE FLOOR(b.r1 * 4)::INT
        WHEN 0 THEN 'ALL'
        WHEN 1 THEN ARRAY_TO_STRING(ARRAY_CONSTRUCT(
                    (FLOOR(b.r1 * 50) + 1)::INT::VARCHAR,
                    (FLOOR(b.r2 * 50) + 1)::INT::VARCHAR), ',')
        ELSE (FLOOR(b.r1 * 50) + 1)::INT::VARCHAR
    END                                                                         AS buildings_access,
    -- Intentional: ~20% of users have not logged in 90+ days
    CASE
        WHEN b.rn % 5 = 0
            THEN DATEADD('day', -FLOOR(b.r2 * 300 + 90)::INT, CURRENT_TIMESTAMP())
        ELSE DATEADD('day', -FLOOR(b.r1 * 30)::INT, CURRENT_TIMESTAMP())
    END                                                                         AS last_login,
    b.rn % 7 != 0                                                               AS is_active,
    DATEADD('day', -FLOOR(b.r2 * 1095)::INT, CURRENT_DATE())                   AS created_date,
    b.r1 > 0.3                                                                  AS mfa_enabled
FROM base b
JOIN dr_pool dr ON dr.dr_rn = (b.rn % 8) + 1;

-- =============================================================================
-- SECTION 15: LOAD ACCESS LOGS (100,000 rows)
-- =============================================================================

INSERT INTO EQR_LAB.SECURITY.ACCESS_LOGS
WITH base AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4())   AS rn,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r2,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r3
    FROM TABLE(GENERATOR(ROWCOUNT => 100000))
),
access_points AS (
    SELECT $1 AS ap FROM VALUES
    ('Main Entrance'),('Parking Garage'),('Gym'),
    ('Pool Area'),('Rooftop Deck'),('Server Room'),
    ('Package Room'),('Bike Storage'),('Laundry Room')
),
ap_pool AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS apn, ap FROM access_points
)
SELECT
    b.rn                                                                        AS log_id,
    -- Intentional DQ: ~3% NULL building_id
    IFF(b.rn % 33 = 0, NULL, (FLOOR(b.r1 * 50) + 1)::INT)       AS building_id,
    (FLOOR(b.r2 * 200) + 1)::INT                                 AS user_id,
    CONCAT('user', LPAD((FLOOR(b.r2 * 200) + 1)::INT::VARCHAR, 4, '0'),
           '@equityapartments.com')                                             AS username,
    CASE ((b.rn - 1) % 9 + 1)
        WHEN 1 THEN 'Main Entrance'
        WHEN 2 THEN 'Parking Garage'
        WHEN 3 THEN 'Gym'
        WHEN 4 THEN 'Pool Area'
        WHEN 5 THEN 'Rooftop Deck'
        WHEN 6 THEN 'Server Room'
        WHEN 7 THEN 'Package Room'
        WHEN 8 THEN 'Bike Storage'
        ELSE 'Laundry Room'
    END                                                                          AS access_point,
    CASE FLOOR(b.r1 * 10)::INT
        WHEN 0 THEN 'Exit'
        ELSE 'Entry'
    END                                                                         AS action,
    -- ~8% failures (good for security module)
    CASE
        WHEN b.rn % 12 = 0 THEN 'Failed'
        WHEN b.rn % 25 = 0 THEN 'Denied'
        ELSE 'Success'
    END                                                                         AS result,
    DATEADD('second',
        -FLOOR(b.r2 * 2592000)::INT,    -- last 30 days
        CURRENT_TIMESTAMP())                                                    AS event_timestamp,
    -- Intentional DQ: ~5% NULL ip_address
    IFF(b.rn % 20 = 0, NULL,
        CONCAT(
            (10 + FLOOR(b.r1 * 240)::INT)::VARCHAR, '.',
            FLOOR(b.r2 * 255)::INT::VARCHAR, '.',
            FLOOR(b.r3 * 255)::INT::VARCHAR, '.',
            (1 + FLOOR(b.r1 * 254)::INT)::VARCHAR
        ))                                                                      AS ip_address,
    CONCAT('DEVICE-', LPAD((FLOOR(b.r3 * 500) + 1)::INT::VARCHAR, 5, '0'))    AS device_id
FROM base b;

-- =============================================================================
-- SECTION 16: LOAD QUERY LOG (10,000 rows — mix of fast and slow queries)
-- =============================================================================

INSERT INTO EQR_LAB.IT_INFRASTRUCTURE.QUERY_LOG
WITH base AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4())   AS rn,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r1,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r2,
        ABS(RANDOM() % 1000000) / 1000000.0    AS r3
    FROM TABLE(GENERATOR(ROWCOUNT => 10000))
),
users AS (
    SELECT $1 AS uname FROM VALUES
    ('user0001@equityapartments.com'),('user0012@equityapartments.com'),
    ('user0034@equityapartments.com'),('user0056@equityapartments.com'),
    ('user0078@equityapartments.com'),('user0099@equityapartments.com'),
    ('user0143@equityapartments.com'),('user0167@equityapartments.com'),
    ('user0188@equityapartments.com'),('analyst_batch@equityapartments.com'),
    ('reporting_svc@equityapartments.com'),('etl_service@equityapartments.com')
),
query_templates AS (
    SELECT $1 AS tmpl, $2 AS base_bytes, $3 AS base_seconds FROM VALUES
    ('SELECT * FROM EQR_LAB.FINANCE.RENT_PAYMENTS WHERE due_date >= DATEADD(month,-1,CURRENT_DATE())', 52000000, 1.2),
    ('SELECT building_id, SUM(amount_paid) FROM EQR_LAB.FINANCE.RENT_PAYMENTS GROUP BY 1', 890000000, 45.3),
    ('SELECT * FROM EQR_LAB.PROPERTIES.UNITS WHERE status = ''Vacant''', 12000000, 0.4),
    ('SELECT b.name, COUNT(*) cnt FROM EQR_LAB.PROPERTIES.BUILDINGS b JOIN EQR_LAB.PROPERTIES.UNITS u ON b.building_id=u.building_id GROUP BY 1', 18000000, 0.8),
    ('SELECT * FROM EQR_LAB.SECURITY.ACCESS_LOGS', 2400000000, 132.7),  -- full table scan
    ('SELECT * FROM EQR_LAB.FINANCE.RENT_PAYMENTS rp JOIN EQR_LAB.PROPERTIES.LEASES l ON rp.lease_id=l.lease_id JOIN EQR_LAB.PROPERTIES.UNITS u ON l.unit_id=u.unit_id JOIN EQR_LAB.PROPERTIES.BUILDINGS b ON u.building_id=b.building_id JOIN EQR_LAB.PROPERTIES.MAINTENANCE_REQUESTS mr ON b.building_id=mr.building_id', 5100000000, 187.4),  -- the bad query
    ('SELECT resident_id, first_name, last_name, email FROM EQR_LAB.PROPERTIES.RESIDENTS LIMIT 100', 800000, 0.1),
    ('SELECT category, AVG(total_cost) FROM EQR_LAB.PROPERTIES.MAINTENANCE_REQUESTS GROUP BY 1 ORDER BY 2 DESC', 145000000, 3.2),
    ('SELECT * FROM EQR_LAB.SECURITY.ACCESS_LOGS WHERE result = ''Failed''', 2400000000, 98.1),  -- another full scan
    ('SELECT state, COUNT(*) FROM EQR_LAB.PROPERTIES.BUILDINGS GROUP BY state', 450000, 0.1)
),
qt_pool AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS qt_rn, tmpl, base_bytes, base_seconds FROM query_templates
),
u_pool AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS u_rn, uname FROM users
)
SELECT
    b.rn                                                                        AS query_id,
    u.uname                                                                     AS user_name,
    CASE FLOOR(b.r2 * 3)::INT
        WHEN 0 THEN 'EQR_HOL_WH'
        WHEN 1 THEN 'EQR_REPORTING_WH'
        ELSE 'EQR_ETL_WH'
    END                                                                         AS warehouse_name,
    qt.tmpl                                                                     AS query_text,
    DATEADD('second', -FLOOR(b.r3 * 604800)::INT, CURRENT_TIMESTAMP())         AS start_time,
    DATEADD('second',
        FLOOR(b.r3 * 604800)::INT + CEIL(qt.base_seconds * (0.8 + b.r2 * 0.5))::INT,
        DATEADD('second', -FLOOR(b.r3 * 604800)::INT, CURRENT_TIMESTAMP()))    AS end_time,
    ROUND(qt.base_seconds * (0.8 + b.r2 * 0.5), 3)                            AS execution_seconds,
    FLOOR(qt.base_bytes * (0.9 + b.r1 * 0.3))::BIGINT                         AS bytes_scanned,
    CASE
        WHEN qt.base_seconds < 5 THEN FLOOR(b.r2 * 50000 + 1)::BIGINT
        ELSE FLOOR(b.r1 * 5000000 + 100)::BIGINT
    END                                                                         AS rows_produced,
    CASE WHEN b.rn % 20 = 0 THEN 'Failed' ELSE 'Success' END                  AS execution_status,
    CASE WHEN b.rn % 20 = 0 THEN 'Query exceeded resource limit' ELSE NULL END AS error_message
FROM base b
JOIN qt_pool qt ON qt.qt_rn = (b.rn % 10) + 1
JOIN u_pool   u  ON u.u_rn   = (b.rn % 12) + 1;

-- =============================================================================
-- SECTION 17: VALIDATION QUERIES
-- Run these after setup to confirm row counts
-- =============================================================================

SELECT 'BUILDINGS'           AS tbl, COUNT(*) AS row_count FROM EQR_LAB.PROPERTIES.BUILDINGS      UNION ALL
SELECT 'UNITS',                       COUNT(*)            FROM EQR_LAB.PROPERTIES.UNITS         UNION ALL
SELECT 'RESIDENTS',                   COUNT(*)            FROM EQR_LAB.PROPERTIES.RESIDENTS     UNION ALL
SELECT 'LEASES',                      COUNT(*)            FROM EQR_LAB.PROPERTIES.LEASES        UNION ALL
SELECT 'MAINTENANCE_REQUESTS',        COUNT(*)            FROM EQR_LAB.PROPERTIES.MAINTENANCE_REQUESTS UNION ALL
SELECT 'RENT_PAYMENTS',               COUNT(*)            FROM EQR_LAB.FINANCE.RENT_PAYMENTS    UNION ALL
SELECT 'OPERATING_EXPENSES',          COUNT(*)            FROM EQR_LAB.FINANCE.OPERATING_EXPENSES UNION ALL
SELECT 'USER_PERMISSIONS',            COUNT(*)            FROM EQR_LAB.SECURITY.USER_PERMISSIONS UNION ALL
SELECT 'ACCESS_LOGS',                 COUNT(*)            FROM EQR_LAB.SECURITY.ACCESS_LOGS     UNION ALL
SELECT 'QUERY_LOG',                   COUNT(*)            FROM EQR_LAB.IT_INFRASTRUCTURE.QUERY_LOG
ORDER BY tbl;

-- =============================================================================
-- SECTION 18: SWITCH TO SYSADMIN FOR THE REST OF THE LAB
-- In a personal demo account you already own everything created above.
-- Switch to SYSADMIN now — this is the role you'll use in Cortex Code.
-- =============================================================================

USE ROLE SYSADMIN;
USE DATABASE  EQR_LAB;
USE WAREHOUSE EQR_HOL_WH;

-- =============================================================================
-- SETUP COMPLETE
-- =============================================================================
