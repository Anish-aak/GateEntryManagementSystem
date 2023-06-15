drop database gate;
create database gate;

use gate;

create table if not exists managers (
	emp_id		varchar(5) NOT NULL UNIQUE,
    pwd			varchar(20) NOT NULL DEFAULT 123,
    first_name	varchar(50) NOT NULL,
    last_name	varchar(50) NOT NULL,
    phone_no	varchar(20) NOT NULL UNIQUE,
    email		varchar(100) NOT NULL UNIQUE,
    sex			char(1),
    dob			date,
    aadhar		varchar(12) NOT NULL UNIQUE,
    primary key(emp_id)
);


create table if not exists guards (
	emp_id		varchar(5) NOT NULL UNIQUE,
    pwd			varchar(20) NOT NULL DEFAULT 123,
    first_name	varchar(50) NOT NULL,
    last_name	varchar(50) NOT NULL,
    phone_no	varchar(20) NOT NULL UNIQUE,
    email		varchar(100) NOT NULL UNIQUE,
    sex			char(1),
    dob			date,
    aadhar		varchar(12) NOT NULL UNIQUE,
    manager_id varchar(5) NOT NULL,
    primary key(emp_id),
    foreign key(manager_id) references managers(emp_id) ON DELETE CASCADE
);
create table if not exists cities (
	pincode int,
    city varchar(10),
    primary key(pincode)
);

create table if not exists drivers (
	driver_id	varchar(5) NOT NULL,
    pwd			varchar(20) NOT NULL default 123,
    first_name	varchar(50) NOT NULL,
    last_name	varchar(50) NOT NULL,
    phone_no	varchar(20) NOT NULL UNIQUE,
    email		varchar(100) NOT NULL UNIQUE,
    sex			char(1),
    house_no	int,
    street_name varchar(20),
    pincode		int,
    dob			date,
    aadhar		varchar(12) NOT NULL UNIQUE,
    created_by_id varchar(5) NOT NULL,
    primary key(driver_id),
    foreign key(created_by_id) references managers(emp_id),
    foreign key(pincode) references cities(pincode) ON DELETE CASCADE
);


create table if not exists model_type (
	model varchar(10) NOT NULL,
    vehicle_type varchar(10) NOT NULL,
    primary key(model)
);

create table if not exists vehicles (
	vin_no varchar(10) NOT NULL UNIQUE,
    model varchar(10) NOT NULL,
    color varchar(10),
    owner_id varchar(5) NOT NULL,
    primary key(vin_no),
    foreign key(owner_id) references drivers(driver_id) ON DELETE CASCADE,
    foreign key(model) references model_type(model) ON DELETE CASCADE
);


create table log (
    vin_no varchar(10) NOT NULL,
    stat int NOT NULL default 0,
    log_time time,
    log_date date,
    logged_by_id varchar(5) NOT NULL,
    primary key(logged_by_id, log_time, log_date),
    foreign key(vin_no) references vehicles(vin_no) ON DELETE CASCADE,
	foreign key(logged_by_id) references guards(emp_id) ON DELETE CASCADE
);


-- PROCEDURES --
DROP FUNCTION IF EXISTS auth_driver;
DELIMITER $$
CREATE FUNCTION auth_driver(id VARCHAR(5), pass VARCHAR(20))
    RETURNS INT
    READS SQL DATA
BEGIN
    DECLARE auth_value INT;
    SELECT COUNT(*) INTO auth_value FROM drivers WHERE driver_id = id AND pwd = pass;
    RETURN auth_value;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS auth_manager;
DELIMITER $$
CREATE FUNCTION auth_manager(id VARCHAR(5), pass VARCHAR(20))
    RETURNS INT
    READS SQL DATA
BEGIN
    DECLARE auth_value INT;
    SELECT COUNT(*) INTO auth_value FROM managers WHERE emp_id = id AND pwd = pass;
    RETURN auth_value;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS auth_guard;
DELIMITER $$
CREATE FUNCTION auth_guard(id VARCHAR(5), pass VARCHAR(20))
    RETURNS INT
    READS SQL DATA
BEGIN
    DECLARE auth_value INT;
    SELECT COUNT(*) INTO auth_value FROM guards WHERE emp_id = id AND pwd = pass;
    RETURN auth_value;
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS reset_password_drivers;
DELIMITER $$
CREATE FUNCTION reset_password_drivers(id varchar(5), sec_aadhar VARCHAR(12), new_pass VARCHAR(20))
    RETURNS INT
    DETERMINISTIC
BEGIN
	declare auth INT;
	IF (sec_aadhar = (SELECT aadhar from drivers where driver_id = id)) THEN
		UPDATE drivers SET drivers.pwd = new_pass where drivers.aadhar = sec_aadhar;
        SET auth = 1;
        return auth;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "FAILED TO UPDATE PASSWORD! PLEASE CHECK DETAILS!";
        SET auth = -1;
        return auth;
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS reset_password_manager;
DELIMITER $$
CREATE PROCEDURE reset_password_manager(id varchar(5), sec_aadhar VARCHAR(12), new_pass VARCHAR(20))
    MODIFIES SQL DATA
BEGIN
	IF (sec_aadhar = (SELECT aadhar from managers where emp_id = id)) THEN
		UPDATE managers SET managers.pwd = new_pass where managers.aadhar = sec_aadhar;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "FAILED TO UPDATE PASSWORD! PLEASE CHECK DETAILS!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS reset_password_guard;
DELIMITER $$
CREATE PROCEDURE reset_password_guard(id varchar(5), sec_aadhar VARCHAR(12), new_pass VARCHAR(20))
    MODIFIES SQL DATA
BEGIN
	IF (sec_aadhar = (SELECT aadhar from guards where emp_id = id)) THEN
		UPDATE guards SET guards.pwd = new_pass where guards.aadhar = sec_aadhar;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "FAILED TO UPDATE PASSWORD! PLEASE CHECK DETAILS!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS register_vehicle;
DELIMITER $$
CREATE PROCEDURE register_vehicle(id varchar(5), new_vin_no varchar(10), new_model varchar(10), new_type varchar(10), new_color varchar(10))
	MODIFIES SQL DATA
BEGIN
	IF (id IN (SELECT driver_id FROM drivers)) THEN
		IF (new_model IN (SELECT model FROM model_type) AND new_type IN (SELECT vehicle_type FROM model_type WHERE new_model = model_type.model)) THEN
			INSERT INTO vehicles(owner_id, vin_no, model, color) values (id, new_vin_no, new_model, new_color);
		ELSEIF (new_model IN (SELECT model FROM model_type) AND new_type NOT IN (SELECT vehicle_type FROM model_type WHERE new_model = model_type.model)) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "INVALID MODEL TYPE!";
		ELSE
			INSERT INTO model_type(model, vehicle_type) values (new_model, new_type);
			INSERT INTO vehicles(owner_id, vin_no, model, color) values (id, new_vin_no, new_model, new_color);
		END IF;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "FAILED TO REGISTER VEHICLE!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS deregister_vehicle;
DELIMITER $$
CREATE PROCEDURE deregister_vehicle(id varchar(5), dereg_vin_no varchar(10))
	MODIFIES SQL DATA
BEGIN
	IF (dereg_vin_no NOT IN (SELECT vin_no from vehicles)) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "VEHICLE DOESN'T EXIST!";
	ELSEIF (dereg_vin_no IN (SELECT vin_no from vehicles) AND id = (SELECT owner_id FROM vehicles WHERE vin_no = dereg_vin_no)) THEN
		-- DELETE FROM log WHERE log.vin_no = dereg_vin_no;
		DELETE FROM vehicles WHERE vehicles.vin_no = dereg_vin_no;
	ELSE 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "FAILED TO DEREGISTER VEHICLE!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS search_vin_no;
DELIMITER $$
CREATE PROCEDURE search_vin_no(s_vin_no varchar(10))
	READS SQL DATA
BEGIN
	IF (s_vin_no IN (SELECT vin_no FROM vehicles)) THEN
		SELECT a.vin_no, a.model, b.vehicle_type, a.color, a.owner_id from vehicles a INNER JOIN model_type b ON a.model = b.model and a.vin_no = s_vin_no;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "NO VEHICLE FOUND!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS search_owner_name;
DELIMITER $$
CREATE PROCEDURE search_owner_name(o_first_name varchar(50), o_last_name varchar(50))
	READS SQL DATA
BEGIN
	IF (o_first_name in (SELECT first_name from drivers) AND o_last_name in (SELECT last_name from drivers where first_name = o_first_name)) THEN
		SELECT a.vin_no, a.model, b.vehicle_type, a.color, a.owner_id from vehicles a INNER JOIN model_type b ON a.model = b.model and a.owner_id in (SELECT driver_id FROM drivers WHERE drivers.first_name = o_first_name and drivers.last_name = o_last_name);
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "NO VEHICLE FOUND!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS search_vehicle_by_pin;
DELIMITER $$
CREATE PROCEDURE search_vehicle_by_pin(pin int)
	READS SQL DATA
BEGIN
	IF (pin IN (SELECT pincode FROM drivers)) THEN
		SELECT a.vin_no, a.model, b.vehicle_type, a.color, a.owner_id FROM vehicles a INNER JOIN model_type b ON a.model = b.model AND a.owner_id IN (SELECT driver_id FROM drivers WHERE drivers.pincode = pin);
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "NO VEHICLE FOUND!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS record_entry_time;
DELIMITER $$
CREATE PROCEDURE record_entry_time(guard_id varchar(5), vehicle_no varchar(10))
	MODIFIES SQL DATA
BEGIN
	IF (vehicle_no IN (SELECT vin_no FROM vehicles)) THEN
		IF ((SELECT  d1.stat FROM log AS d1 LEFT OUTER JOIN log AS d2 ON d1.log_date < d2.log_date OR d1.log_date = d2.log_date and d1.log_time < d2.log_time WHERE (d2.vin_no IS NULL)) = 0) THEN
			INSERT INTO log(vin_no, stat, log_time, log_date, logged_by_id) VALUES (vehicle_no, 1, current_time(), current_date(), guard_id);
		ELSE
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "VEHICLE STILL IN LOT!";
		END IF;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "VEHICLE NOT REGISTERED!";
	END IF;
	
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS record_exit_time;
DELIMITER $$
CREATE PROCEDURE record_exit_time(guard_id varchar(5), vehicle_no varchar(10))
	MODIFIES SQL DATA
BEGIN
	IF (vehicle_no IN (SELECT vin_no FROM vehicles)) THEN
		IF ((SELECT  d1.stat FROM log AS d1 LEFT OUTER JOIN log AS d2 ON d1.log_date < d2.log_date OR d1.log_date = d2.log_date and d1.log_time < d2.log_time WHERE (d2.vin_no IS NULL)) = 1) THEN
			INSERT INTO log(vin_no, stat, log_time, log_date, logged_by_id) VALUES (vehicle_no, 0, current_time(), current_date(), guard_id);
		ELSE
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "VEHICLE ALREADY OUTSIDE LOT!";
		END IF;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "VEHICLE NOT REGISTERED!";
	END IF;
	
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS obtain_logs;
DELIMITER $$
CREATE PROCEDURE obtain_logs(user_id varchar(5))
	READS SQL DATA
BEGIN
	IF (user_id IN (SELECT driver_id FROM drivers)) THEN
		SELECT a.vin_no, a.stat, a.log_time, a.log_date from log a INNER JOIN vehicles b ON a.vin_no = b.vin_no and b.owner_id = user_id;
	ELSE 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "UNABLE TO RETRIEVE LOGS";
	END IF;
END$$
DELIMITER  ;

DROP PROCEDURE IF EXISTS update_user_phone;
DELIMITER $$
CREATE PROCEDURE update_user_phone(id varchar(5), new_number varchar(20))
	MODIFIES SQL DATA
BEGIN
	IF (id in (SELECT driver_id FROM drivers)) THEN
		UPDATE drivers SET drivers.phone_no = new_number where drivers.driver_id = id;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "FAILED TO UPDATE NUMBER!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS update_user_email;
DELIMITER $$
CREATE PROCEDURE update_user_email(id varchar(5), new_email varchar(100))
	MODIFIES SQL DATA
BEGIN
	IF (id in (SELECT driver_id FROM drivers)) THEN
		UPDATE drivers SET drivers.email = new_email where drivers.driver_id = id;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "FAILED TO UPDATE EMAIL!";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS update_user_address;
DELIMITER $$
CREATE PROCEDURE update_user_address(id varchar(5), new_house int, new_street varchar(20), new_city varchar(20), new_pincode int)
	MODIFIES SQL DATA
BEGIN
	IF (id in (SELECT driver_id FROM drivers)) THEN
		IF (new_pincode IN (SELECT pincode from cities) AND new_city IN (SELECT city FROM cities WHERE new_pincode = cities.pincode)) THEN
			UPDATE drivers SET drivers.house_no = new_house, drivers.street_name = new_street, drivers.pincode = new_pincode where drivers.driver_id = id;
		ELSEIF (new_pincode IN (SELECT pincode from cities) AND new_city NOT IN (SELECT city FROM cities WHERE new_pincode = cities.pincode)) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="INCORRECT CITY!";
		ELSE
			INSERT INTO cities(pincode, city) values(new_pincode, new_city);
			UPDATE drivers SET drivers.house_no = new_house, drivers.street_name = new_street, drivers.pincode = new_pincode where drivers.driver_id = id;
		END IF;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "FAILED TO UPDATE ADDRESS!";
	END IF;
END$$
DELIMITER ;

CREATE VIEW viewGuardData as
	SELECT emp_id, first_name, last_name, phone_no, email, sex, dob, aadhar from guards;
    
CREATE VIEW initUserData as
		SELECT a.driver_id, a.first_name, a.last_name, a.phone_no, a.email, a.sex, a.house_no, a.street_name, b.city, a.pincode, a.dob from drivers a INNER JOIN cities b ON  a.pincode = b.pincode ;

CREATE VIEW driverVehicleCount as 
	SELECT owner_id, count(vin_no) as vehicle_count from vehicles GROUP BY owner_id;

CREATE VIEW viewUserData as
	SELECT a.driver_id, a.first_name, a.last_name, a.phone_no, a.email, a.sex, a.house_no, a.street_name, a.city, a.pincode, a.dob, b.vehicle_count from initUserData a INNER JOIN driverVehicleCount b ON a.driver_id = b.owner_id;

DROP PROCEDURE IF EXISTS obtain_user_data;
DELIMITER $$
CREATE PROCEDURE obtain_user_data(id varchar(5))
	READS SQL DATA
BEGIN
	IF (id in (SELECT driver_id from drivers)) THEN
		SELECT driver_id, first_name, last_name, phone_no, email, sex, house_no, street_name, city, pincode, dob, vehicle_count from viewUserData where driver_id = id;
	ELSE
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "UNABLE TO RETRIEVE INFO";
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS obtain_peak_hour;
DELIMITER $$
CREATE PROCEDURE obtain_peak_hour()
	READS SQL DATA
BEGIN
	select date_format( log_time, '%H' ) as `hour`, count('hour') from log group by date_format( log_time, '%H' ) order by count(*) desc limit 1;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS obtain_registered_models;
DELIMITER $$
CREATE PROCEDURE obtain_registered_models()
	READS SQL DATA
BEGIN
 select vehicle_type, count(vehicle_type) from model_type group by vehicle_type order by count(*) desc;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS obtain_vehicles_in;
DELIMITER $$
CREATE PROCEDURE obtain_vehicles_in()
	READS SQL DATA
BEGIN
	SELECT count(stat) FROM(SELECT m.*, ROW_NUMBER() OVER (PARTITION BY vin_no ORDER BY log_date DESC, log_time DESC) as n from log as m) AS P where n = 1 and stat = 1;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS obtain_vehicles_out;
DELIMITER $$
CREATE PROCEDURE obtain_vehicles_out()
	READS SQL DATA
BEGIN
	SELECT count(stat) FROM(SELECT m.*, ROW_NUMBER() OVER (PARTITION BY vin_no ORDER BY log_date DESC, log_time DESC) as n from log as m) AS P where n = 1 and stat = 0;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS create_user;
DELIMITER $$
CREATE PROCEDURE create_user(id varchar(5), fname varchar(50), lname varchar(50), phone varchar(20), mail varchar(50), sex varchar(1), house int, road varchar(20), new_city varchar(10), new_pincode int, birth date, aadhar_no varchar(12), man_id varchar(5))
	MODIFIES SQL DATA
BEGIN
	IF (new_pincode IN (SELECT pincode from cities) AND new_city IN (SELECT city FROM cities WHERE new_pincode = cities.pincode)) THEN
		INSERT INTO drivers (driver_id, first_name, last_name, phone_no, email, sex, house_no, street_name, pincode, dob, aadhar, created_by_id) VALUES (id, fname, lname, phone, mail, sex, house, road, new_pincode, birth, aadhar_no, man_id);
	ELSEIF (new_pincode IN (SELECT pincode from cities) AND new_city NOT IN (SELECT city FROM cities WHERE new_pincode = cities.pincode)) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="INCORRECT CITY!";
	ELSE
		INSERT INTO cities(pincode, city) values(new_pincode, new_city);
		INSERT INTO drivers (driver_id, first_name, last_name, phone_no, email, sex, house_no, street_name, pincode, dob, aadhar, created_by_id) VALUES (id, fname, lname, phone, mail, sex, house, road, new_pincode, birth, aadhar_no, man_id);
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS create_guard;
DELIMITER $$
CREATE PROCEDURE create_guard(id varchar(5), fname varchar(50), lname varchar(50), phone varchar(20), mail varchar(50), sex varchar(1), birth date, aadhar_no varchar(12), man_id varchar(5))
	MODIFIES SQL DATA
BEGIN	
		IF (id IN (SELECT emp_id from guards) and man_id in (select emp_id from managers)) THEN
			IF (aadhar IN (SELECT aadhar from guards)) THEN
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="GUARD EXISTS!";
			ELSE
				INSERT INTO guards (emp_id, first_name, last_name, phone_no, email, sex, dob, aadhar, manager_id) VALUES (id, fname, lname, phone, mail, sex, birth, aadhar_no, man_id);
			END IF;
		END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS delete_user;
DELIMITER $$
CREATE PROCEDURE delete_user(id varchar(5))
	MODIFIES SQL DATA
BEGIN
	IF (id NOT IN (SELECT driver_id from drivers)) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="USER DOESN'T EXIST!";
	ELSE
		delete from drivers where id = driver_id;
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS delete_guard;
DELIMITER $$
CREATE PROCEDURE delete_guard(id varchar(5))
	MODIFIES SQL DATA
BEGIN
	IF (id NOT IN (SELECT emp_id from guards)) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT="USER DOESN'T EXIST!";
	ELSE
		delete from guards where id = emp_id;
	END IF;
END$$
DELIMITER ;

-- PROCEDURES END --

-- DATA INSERTION --
INSERT INTO managers (emp_id, pwd, first_name, last_name, phone_no, email, sex, dob, aadhar)
VALUES
('M001', 'manager001', 'John', 'Doe', '9876543210', 'john.doe@example.com', 'M', '1980-01-01', '123456789012'),
('M002', 'manager002', 'Jane', 'Smith', '9876543211', 'jane.smith@example.com', 'F', '1985-02-15', '345678901234'),
('M003', 'manager003', 'Robert', 'Johnson', '9876543212', 'robert.johnson@example.com', 'M', '1976-10-21', '567890123456'),
('M004', 'manager004', 'Jake', 'Thomson', '9880078723', 'jake.thomson@example.com', 'M', '1965-02-20', '678946783769'),
('M005', 'manager005', 'Andrea', 'McKinney', '8125077890', 'andrea.mckinney@example.com', 'F', '1990-08-28', '124685707987'),
('M006', 'manager006', 'David', 'Lee', '8125077891', 'david.lee@example.com', 'M', '1988-05-14', '389472910238'),
('M007', 'manager007', 'Linda', 'Nguyen', '8765432101', 'linda.nguyen@example.com', 'F', '1983-09-03', '238479102938'),
('M008', 'manager008', 'Michael', 'Garcia', '7712495098', 'michael.garcia@example.com', 'M', '1978-11-30', '749203849012'),
('M009', 'manager009', 'Emily', 'Chen', '9993914807', 'emily.chen@example.com', 'F', '1995-04-18', '039485739482'),
('M010', 'manager010', 'William', 'Davis', '9297004138', 'william.davis@example.com', 'M', '1972-12-22', '748291048593');

INSERT INTO guards (emp_id, pwd, first_name, last_name, phone_no, email, sex, dob, aadhar, manager_id)
VALUES
('G001', 'guard001', 'David', 'Lee', '9880231476', 'david.lee@example.com', 'M', '1990-06-07', '897491230097', 'M001'),
('G002', 'guard002', 'Emily', 'Wang', '9993918807', 'emily.wang@example.com', 'F', '1992-08-12', '146723804390', 'M001'),
('G003', 'guard003', 'Jason', 'Chen', '9889078723', 'jason.chen@example.com', 'M', '1988-12-30', '698321427098', 'M002'),
('G004', 'guard004', 'Sarah', 'Lin', '8765412101', 'sarah.lin@example.com', 'F', '1993-04-17', '379499182498', 'M003'),
('G005', 'guard005', 'Mark', 'Wong', '8125077301', 'mark.wong@example.com', 'M', '1991-03-22', '934857034980', 'M003'),
('G006', 'guard006', 'Olivia', 'Zhang', '8293710392', 'olivia.zhang@example.com', 'F', '1995-12-01', '103948573947', 'M004'),
('G007', 'guard007', 'William', 'Cheng', '9880079901', 'william.cheng@example.com', 'M', '1990-07-14', '342341289058', 'M005'),
('G008', 'guard008', 'Julia', 'Wu', '9882309988', 'julia.wu@example.com', 'F', '1993-11-17', '237940184729', 'M005'),
('G009', 'guard009', 'Brian', 'Liu', '8765123201', 'brian.liu@example.com', 'M', '1992-02-28', '789012348579', 'M006'),
('G010', 'guard010', 'Sophia', 'Sun', '8125077200', 'sophia.sun@example.com', 'F', '1997-09-08', '109485739285', 'M006'),
('G011', 'guard011', 'Matthew', 'Yu', '9889078123', 'matthew.yu@example.com', 'M', '1994-05-11', '430198572309', 'M007'),
('G012', 'guard012', 'Karen', 'Zhou', '9993911234', 'karen.zhou@example.com', 'F', '1998-01-05', '348091238475', 'M007'),
('G013', 'guard013', 'Luke', 'Chang', '8765439901', 'luke.chang@example.com', 'M', '1996-08-15', '348091234578', 'M008'),
('G014', 'guard014', 'Michelle', 'Yang', '8293710495', 'michelle.yang@example.com', 'F', '1991-06-20', '239487239042', 'M008'),
('G015', 'guard015', 'George', 'Liu', '9880078765', 'george.liu@example.com', 'M', '1997-02-23', '230948572039', 'M009'),
('G016', 'guard016', 'Lena', 'Zhu', '9882304567', 'lena.zhu@example.com', 'F', '1995-10-31', '908471023847', 'M009'),
('G017', 'guard017', 'Henry', 'Lin', '8765123490', 'henry.lin@example.com', 'M', '1993-12-04', '478923190487', 'M010'),
('G018', 'guard018', 'Diana', 'Wang', '8125071234', 'diana.wang@example.com', 'F', '1994-09-27', '987654321234', 'M010');

INSERT INTO cities (pincode, city)
VALUES
(110001, 'Delhi'),
(110002, 'Delhi'),
(400001, 'Mumbai'),
(400011, 'Mumbai'),
(500001, 'Hyderabad'),
(500012, 'Hyderabad'),
(600001, 'Kochi');

INSERT INTO drivers (driver_id, pwd, first_name, last_name, phone_no, email, sex, house_no, street_name, pincode, dob, aadhar, created_by_id)
VALUES
('D001', 'driver123', 'Alex', 'Chung', '9876543217', 'alex.chung@example.com', 'M', 15, 'Main Street', 110001, '1995-11-23', '567890123456', 'M001'),
('D002', 'driver456', 'Emma', 'Lee', '9876543218', 'emma.lee@example.com', 'F', 25, 'Second Street', 400001, '1997-03-14', '789012345678', 'M001'),
('D003', 'driver789', 'Tom', 'Park', '9876543219', 'tom.park@example.com', 'M', 35, 'Third Street', 500001, '1992-05-06', '901234567890', 'M002'),
('D004', 'driverabc', 'Olivia', 'Kim', '9876543220', 'olivia.kim@example.com', 'F', 45, 'Fourth Street', 110002, '1996-08-29', '123456789012', 'M003'),
('D005', 'driver005', 'Jacob', 'Wu', '8125077892', 'jacob.wu@example.com', 'M', 20, 'Fifth Street', 400011, '1998-01-15', '238479102938', 'M004'),
('D006', 'driver006', 'Ella', 'Zhang', '8125077893', 'ella.zhang@example.com', 'F', 30, 'Sixth Street', 500001, '1990-12-02', '749203849012', 'M004'),
('D007', 'driver007', 'Noah', 'Chang', '8765432102', 'noah.chang@example.com', 'M', 40, 'Seventh Street', 110001, '1987-09-22', '039485739482', 'M005'),
('D008', 'driver008', 'Sophia', 'Choi', '7712495099', 'sophia.choi@example.com', 'F', 50, 'Eighth Street', 400001, '1986-11-17', '748291048593', 'M005'),
('D009', 'driver009', 'William', 'Kang', '9993914808', 'william.kang@example.com', 'M', 18, 'Ninth Street', 500012, '2004-02-20', '897491230097', 'M006'),
('D010', 'driver010', 'Grace', 'Kim', '9297004139', 'grace.kim@example.com', 'F', 28, 'Tenth Street', 110001, '1995-06-28', '146723804390', 'M006'),
('D011', 'driver011', 'Ethan', 'Park', '9880231477', 'ethan.park@example.com', 'M', 38, 'Eleventh Street', 400001, '1984-03-31', '698321427098', 'M007'),
('D012', 'driver012', 'Chloe', 'Lee', '9993918808', 'chloe.lee@example.com', 'F', 48, 'Twelfth Street', 500001, '1974-12-19', '379499182498', 'M007'),
('D013', 'driver013', 'Daniel', 'Chen', '9889078724', 'daniel.chen@example.com', 'M', 22, 'Thirteenth Street', 110001, '1999-08-05', '567898123456', 'M008'),
('D014', 'driver014', 'Lily', 'Li', '8765412102', 'lily.li@example.com', 'F', 32, 'Fourteenth Street', 400001, '1989-04-25', '789612345678', 'M008'),
('D015', 'driver015', 'Luke', 'Yang', '8125077894', 'luke.yang@example.com', 'M', 42, 'Fifteenth Street', 600001, '1980-07-14', '909234567890', 'M009'),
('D016', 'driver016', 'Ava', 'Jung', '8125077895', 'ava.jung@example.com', 'F', 52, 'Sixteenth Street', 110001, '1970-02-18', '123456789092', 'M009');

INSERT INTO model_type (model, vehicle_type)
VALUES
('M1', 'Car'),
('M2', 'SUV'),
('M3', 'Bike'),
('M4', 'Truck'),
('M5', 'Jet');

INSERT INTO vehicles (vin_no, model, color, owner_id)
VALUES 
('VIN001', 'M1', 'Red', 'D001'),
('VIN002', 'M1', 'Blue', 'D002'),
('VIN003', 'M2', 'Pink', 'D002'),
('VIN004', 'M3', 'Silver', 'D003'),
('VIN005', 'M4', 'Black', 'D004'),
('VIN006', 'M2', 'White', 'D005'),
('VIN007', 'M5', 'Green', 'D006'),
('VIN008', 'M1', 'Yellow', 'D007'),
('VIN009', 'M2', 'Orange', 'D007'),
('VIN010', 'M3', 'Red', 'D008'),
('VIN011', 'M4', 'Blue', 'D009'),
('VIN012', 'M5', 'Pink', 'D009'),
('VIN013', 'M1', 'Silver', 'D009'),
('VIN014', 'M2', 'Black', 'D011'),
('VIN015', 'M3', 'White', 'D012'),
('VIN016', 'M4', 'Green', 'D013'),
('VIN017', 'M5', 'Yellow', 'D014'),
('VIN018', 'M1', 'Orange', 'D015'),
('VIN019', 'M2', 'Red', 'D016');

INSERT INTO log (vin_no, stat, log_time, log_date, logged_by_id)
VALUES 
('VIN001', 0, '20:30:00', '2003-11-03', 'G001'),
('VIN001', 1, '20:51:00', '2004-02-13', 'G002'),
('VIN001', 0, '11:00:00', '2008-08-12', 'G002'),
('VIN001', 1, '11:51:00', '2009-12-09', 'G002'),
('VIN002', 0, '11:12:00', '2009-12-29', 'G002'),
('VIN002', 1, '14:30:00', '2001-09-03', 'G001'),
('VIN002', 0, '16:00:00', '2002-04-15', 'G002'),
('VIN002', 1, '19:30:00', '2002-06-17', 'G003'),
('VIN002', 0, '21:00:00', '2003-05-12', 'G004'),
('VIN002', 1, '12:00:00', '2005-10-03', 'G005'),
('VIN002', 0, '17:30:00', '2005-11-29', 'G006'),
('VIN003', 0, '10:00:00', '2006-04-08', 'G007'),
('VIN003', 1, '11:30:00', '2006-08-09', 'G008'),
('VIN003', 0, '12:30:00', '2007-02-18', 'G009'),
('VIN003', 1, '13:00:00', '2008-01-03', 'G010'),
('VIN003', 0, '16:00:00', '2010-09-29', 'G011'),
('VIN003', 1, '18:30:00', '2012-11-14', 'G012'),
('VIN004', 0, '15:30:00', '2007-06-17', 'G013'),
('VIN004', 1, '18:00:00', '2007-12-03', 'G014'),
('VIN004', 0, '19:00:00', '2008-08-22', 'G015'),
('VIN004', 1, '20:30:00', '2009-05-06', 'G016'),
('VIN004', 0, '10:00:00', '2011-07-12', 'G017'),
('VIN004', 1, '12:00:00', '2012-02-28', 'G018'),
('VIN005', 0, '10:00:00', '2007-06-17', 'G001'),
('VIN005', 1, '12:00:00', '2007-12-03', 'G002'),
('VIN005', 0, '15:30:00', '2008-08-22', 'G003'),
('VIN005', 1, '18:00:00', '2009-05-06', 'G004'),
('VIN005', 0, '19:00:00', '2011-07-12', 'G005'),
('VIN001', 1, '15:00:00', '2011-09-02', 'G002'),
('VIN001', 0, '10:30:00', '2013-07-18', 'G003'),
('VIN002', 1, '11:00:00', '2014-02-13', 'G003'),
('VIN003', 0, '15:30:00', '2014-08-02', 'G004'),
('VIN004', 0, '10:45:00', '2015-12-25', 'G004'),
('VIN001', 1, '12:15:00', '2016-09-19', 'G004'),
('VIN002', 0, '09:00:00', '2016-12-01', 'G004'),
('VIN005', 1, '14:00:00', '2017-05-10', 'G005'),
('VIN001', 0, '16:30:00', '2018-02-23', 'G005'),
('VIN002', 1, '08:45:00', '2018-08-09', 'G006'),
('VIN003', 1, '12:15:00', '2018-10-15', 'G006'),
('VIN004', 1, '14:30:00', '2019-01-25', 'G007'),
('VIN006', 0, '13:00:00', '2019-08-17', 'G007'),
('VIN001', 1, '10:30:00', '2019-10-02', 'G008'),
('VIN002', 0, '11:45:00', '2020-03-01', 'G008'),
('VIN003', 0, '15:30:00', '2020-07-11', 'G009'),
('VIN004', 0, '14:00:00', '2021-02-14', 'G009'),
('VIN005', 0, '16:30:00', '2021-09-22', 'G010'),
('VIN008', 0, '10:30:00', '2005-06-15', 'G001'),
('VIN007', 0, '12:00:00', '2006-02-12', 'G002'),
('VIN019', 0, '14:00:00', '2007-08-02', 'G003'),
('VIN011', 0, '16:00:00', '2008-03-25', 'G004'),
('VIN018', 0, '18:30:00', '2009-05-06', 'G005'),
('VIN010', 0, '20:30:00', '2010-02-13', 'G006'),
('VIN013', 0, '10:00:00', '2011-07-12', 'G007'),
('VIN017', 0, '11:30:00', '2012-09-29', 'G008'),
('VIN009', 0, '12:30:00', '2013-04-18', 'G009'),
('VIN014', 0, '13:00:00', '2014-06-03', 'G010'),
('VIN012', 0, '16:00:00', '2015-11-19', 'G011'),
('VIN015', 0, '18:30:00', '2016-03-29', 'G012'),
('VIN016', 1, '15:30:00', '2017-05-10', 'G013'),
('VIN007', 1, '18:00:00', '2018-01-05', 'G014'),
('VIN019', 1, '19:00:00', '2019-03-22', 'G015'),
('VIN009', 1, '20:30:00', '2020-06-09', 'G016'),
('VIN011', 1, '10:00:00', '2021-04-17', 'G017'),
('VIN018', 1, '12:00:00', '2022-01-01', 'G018'),
('VIN013', 1, '15:30:00', '2022-08-10', 'G018'),
('VIN017', 1, '08:45:00', '2023-02-19', 'G018');

-- DATA INSERTION END --
