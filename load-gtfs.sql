/* Required GTFS tables */

DROP TABLE IF EXISTS `agency`;

CREATE TABLE `agency` (
    agency_id VARCHAR(255),
    agency_name VARCHAR(255) NOT NULL,
    agency_url VARCHAR(255) NOT NULL,
    agency_timezone VARCHAR(255) NOT NULL,
    agency_lang VARCHAR(255),
    agency_phone VARCHAR(255)
);

DROP TABLE IF EXISTS `stops`;

CREATE TABLE `stops` (
    stop_id VARCHAR(255) NOT NULL PRIMARY KEY,
    stop_code VARCHAR(255),
	stop_name VARCHAR(255) NOT NULL,
	stop_desc VARCHAR(255),
	stop_lat DECIMAL(8,6) NOT NULL,
	stop_lon DECIMAL(8,6) NOT NULL,
	zone_id VARCHAR(255),
    stop_url VARCHAR(255),
    location_type ENUM ('0','1'),
    parent_station VARCHAR(255),
	KEY `zone_id` (zone_id),
	KEY `stop_lat` (stop_lat),
	KEY `stop_lon` (stop_lon)
);

DROP TABLE IF EXISTS `routes`;

CREATE TABLE `routes` (
    route_id VARCHAR(255) NOT NULL PRIMARY KEY,
	agency_id VARCHAR(255),
	route_short_name VARCHAR(255),
	route_long_name VARCHAR(255),
    route_desc VARCHAR(255),
	route_type ENUM ('0','1','2','3','4','5','6','7') NOT NULL,
    route_url VARCHAR(255),
    route_color VARCHAR(255),
    route_text_color VARCHAR(255)
);

DROP TABLE IF EXISTS trips;

CREATE TABLE `trips` (
    route_id VARCHAR(255) NOT NULL,
	service_id VARCHAR(255) NOT NULL,
	trip_id VARCHAR(255) NOT NULL PRIMARY KEY,
	trip_headsign VARCHAR(255),
    trip_short_name VARCHAR(255),
	direction_id ENUM ('0','1'),
	block_id VARCHAR(255),
    shape_id VARCHAR(255),
	pattern_id VARCHAR(255),
	KEY `route_id` (route_id),
	KEY `service_id` (service_id),
	KEY `direction_id` (direction_id),
	KEY `block_id` (block_id)
);

DROP TABLE IF EXISTS stop_times;

CREATE TABLE `stop_times` (
    trip_id VARCHAR(255) NOT NULL,
	arrival_time TIME,
	departure_time TIME,
	stop_id VARCHAR(255) NOT NULL,
	stop_sequence SMALLINT UNSIGNED NOT NULL,
    stop_headsign VARCHAR(255),
	pickup_type ENUM ('0','1','2','3'),
	drop_off_type ('0','1','2','3'),
    shape_dist_traveled DECIMAL(10,4),
	KEY `trip_id` (trip_id),
	KEY `stop_id` (stop_id),
	KEY `stop_sequence` (stop_sequence),
	KEY `pickup_type` (pickup_type),
	KEY `drop_off_type` (drop_off_type)
);

DROP TABLE IF EXISTS calendar;

CREATE TABLE `calendar` (
    service_id VARCHAR(255) NOT NULL PRIMARY KEY,
	monday ENUM ('0','1') NOT NULL,
	tuesday ENUM ('0','1') NOT NULL,
	wednesday ENUM ('0','1') NOT NULL,
	thursday ENUM ('0','1') NOT NULL,
	friday ENUM ('0','1') NOT NULL,
	saturday ENUM ('0','1') NOT NULL,
	sunday ENUM ('0','1') NOT NULL,
	start_date DATE NOT NULL,	
	end_date DATE NOT NULL
);

/* Optional GTFS tables */

DROP TABLE IF EXISTS calendar_dates;

CREATE TABLE `calendar_dates` (
    service_id VARCHAR(255) NOT NULL,
    `date` DATE NOT NULL,
    exception_type ENUM ('1','2') NOT NULL,
    KEY `service_id` (service_id),
    KEY `exception_type` (exception_type)    
);

DROP TABLE IF EXISTS fare_attributes;

CREATE TABLE fare_attributes (
    fare_id VARCHAR(255) NOT NULL,
    price VARCHAR(255) NOT NULL,
    currency_type VARCHAR(255) NOT NULL,
    payment_method ENUM ('0','1') NOT NULL,
    transfers ENUM ('0','1','2',''),
    transfer_duration MEDIUMINT UNSIGNED
);

DROP TABLE IF EXISTS fare_rules;

CREATE TABLE fare_rules (
    fare_id VARCHAR(255) NOT NULL,
    route_id VARCHAR(255),
    origin_id VARCHAR(255),
    destination_id VARCHAR(255),
    contains_id VARCHAR(255)
);

DROP TABLE IF EXISTS shapes;

CREATE TABLE shapes (
    shape_id VARCHAR(255) NOT NULL,
    shape_pt_lat DECIMAL(8,6) NOT NULL,
    shape_pt_lon DECIMAL(8,6) NOT NULL,
    shape_pt_sequence SMALLINT UNSIGNED NOT NULL, 
    shape_dist_traveled DECIMAL(10,4)
);

DROP TABLE IF EXISTS frequencies;

CREATE TABLE frequencies (
    trip_id VARCHAR(255) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    headway_secs MEDIUMINT NOT NULL
);

DROP TABLE IF EXISTS transfers;

CREATE TABLE transfers (
    from_stop_id VARCHAR(255) NOT NULL,
    to_stop_id VARCHAR(255) NOT NULL,
    transfer_type ENUM ('0','1','2','3') NOT NULL,
    min_transfer_time MEDIUMINT NOT NULL
);

/* non-GTFS standard tables go here */

DROP TABLE IF EXISTS patterns;

CREATE TABLE `patterns` (
	route_id VARCHAR(255),
	pattern_id VARCHAR(255),
	stop_sequence SMALLINT UNSIGNED,
	stop_id VARCHAR(255),
    distance DECIMAL(10,4) UNSIGNED
);

/*

LOAD DATA LOCAL INFILE 'input/wmata_gtfs/agency.txt' INTO TABLE agency FIELDS TERMINATED BY ',' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'input/wmata_gtfs/calendar_dates.txt' INTO TABLE calendar_dates FIELDS TERMINATED BY ',' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'input/wmata_gtfs/calendar.txt' INTO TABLE calendar FIELDS TERMINATED BY ',' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'input/wmata_gtfs/routes.txt' INTO TABLE routes FIELDS TERMINATED BY ',' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'input/wmata_gtfs/stops.txt' INTO TABLE stops FIELDS TERMINATED BY ',' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'input/wmata_gtfs/trips.txt' INTO TABLE trips FIELDS TERMINATED BY ',' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'input/wmata_gtfs/stop_times.txt' INTO TABLE stop_times FIELDS TERMINATED BY ',' IGNORE 1 LINES;

*/
