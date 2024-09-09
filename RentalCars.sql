

Windows firewall port enable command line syntax;
***************************************************

	netsh advfirewall firewall add rule name="TCP Port 2024" dir=in action=allow protocol=TCP localport=22


creating database in postgres
*****************************

	createdb -U postgres rental_cars;  				// in Linux

	create database 	; 					//in windows



/* dummy table
CREATE TABLE cars (
  brand VARCHAR,
  model VARCHAR,
  year Numeric
); 


INSERT INTO cars(brand,model,year) values('BMW','X7','2010');
INSERT INTO cars(brand,model,year) values('BMW','X5','2008');
*/

drop table customer_registration_details;
CREATE TABLE customer_registration_details(
	id UUID
	,name VARCHAR
	,password VARCHAR
	,mobile_no VARCHAR
	,alternative_mobile_no VARCHAR
	,age VARCHAR
	,email_id VARCHAR
	,sign_status VARCHAR
);


CREATE TABLE admin_software_user_details(
	user_id VARCHAR   PRIMARY KEY
	,password VARCHAR
	,email_id VARCHAR
	,mobile_no VARCHAR
	
);
insert into admin_software_user_details values('admin','123','rajesh@smartyuppies.com','9090909090');

CREATE TABLE admin_cars_category(
	category_id UUID   PRIMARY KEY
	,category_name VARCHAR		
);


drop table admin_rental_cars_upload;
CREATE TABLE admin_rental_cars_upload(
	id UUID   PRIMARY KEY
	,file_path VARCHAR		
	,file_name VARCHAR
	,file_type VARCHAR
	,convert_into_png_status VARCHAR
);

drop table admin_rental_cars_details;
CREATE TABLE admin_rental_cars_details(
	id UUID   PRIMARY KEY
	,brand VARCHAR		
	,car_name VARCHAR
	,car_no VARCHAR
	,is_ac VARCHAR	
	,img_url VARCHAR
	,category VARCHAR
	,no_of_seat VARCHAR
	,is_gps VARCHAR
	,transmission_type VARCHAR
	,fuel_type VARCHAR	
	,limit_km VARCHAR
	,price_per_day VARCHAR
);



SELECT 
	m1.id
	,m1.file_name
	,m2.car_name
	,m2.price_per_day
	,m2.car_no
	,m2.no_of_seat
	,m2.transmission_type
	,m2.fuel_type
FROM
	admin_rental_cars_upload m1
	,admin_rental_cars_details m2
WHERE
	m1.id = m2.id
	AND m2.car_name is  NOT NUll;

	