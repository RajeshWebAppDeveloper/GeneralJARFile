
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