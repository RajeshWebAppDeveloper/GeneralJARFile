--select TO_CHAR(current_date,'DAY') as day;

Windows firewall port enable command line syntax;
***************************************************

--netsh advfirewall firewall add rule name="TCP Port 2024" dir=in action=allow protocol=TCP localport=22


creating database in postgres
*****************************

	createdb -U postgres rentalcars; /* in Linux */

	create database rentalcars; 	/* in windows */


--DROP TABLE customer_registration_details;
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

DROP TABLE admin_software_user_details;
CREATE TABLE admin_software_user_details(
	user_id VARCHAR   PRIMARY KEY
	,password VARCHAR
	,email_id VARCHAR
	,mobile_no VARCHAR
	,role_name VARCHAR
	,branch VARCHAR
	
);
insert into admin_software_user_details values('admin','123','rajesh@smartyuppies.com','9090909090','Super Admin','Chennai');
--Drop table admin_default_properties;
CREATE TABLE admin_default_properties(
	id UUID   PRIMARY KEY
	,property_name VARCHAR		
	,property_value VARCHAR		
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

--DROP TYPE IF EXISTS customer_cars_info_list CASCADE;

CREATE TYPE customer_cars_info_list AS (
    id UUID  
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

--DROP FUNCTION IF EXISTS getRentARideCustomerCarsList(VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR) CASCADE;


SELECT * FROM getRentARideCustomerCarsList('Sedan','Petrol','Automatic','500 KM');	
CREATE OR REPLACE FUNCTION getRentARideCustomerCarsList(categoryArgs VARCHAR,fuelType VARCHAR,transmissionType VARCHAR,kmLimit VARCHAR) RETURNS SETOF customer_cars_info_list AS $BODY$

		DECLARE
			customerCarsInfoList customer_cars_info_list;

		BEGIN
			FOR customerCarsInfoList IN
				SELECT 
					m2.id 
					,m2.brand
					,m2.car_name
					,m2.car_no 
					,m2.is_ac 
					,m1.file_name as img_url
					,m2.category
					,m2.no_of_seat
					,m2.is_gps 
					,m2.transmission_type
					,m2.fuel_type 
					,m2.limit_km 
					,m2.price_per_day
				FROM
					admin_rental_cars_upload m1
					,admin_rental_cars_details m2
				WHERE
					m1.id = m2.id
					AND m2.car_name is  NOT NUll
					AND lower(m2.category) like lower(categoryArgs)||'%'
					AND lower(m2.fuel_type) like lower(fuelType)||'%'
					AND lower(m2.transmission_type) like lower(transmissionType)||'%'
					AND lower(m2.limit_km) like lower(kmLimit)||'%'
			LOOP 

				RETURN NEXT customerCarsInfoList;

			END LOOP;
		END

$BODY$ LANGUAGE plpgsql VOlATILE COST 100;



DROP TABLE IF EXISTS admin_view_holiday_car_booking_payment_rule CASCADE;
CREATE TABLE admin_view_holiday_car_booking_payment_rule(
	id UUID   PRIMARY KEY
	,holiday_date DATE	
	,car_rent_amount_additional_percentage VARCHAR
);

DROP TABLE IF EXISTS admin_view_multiple_day_car_booking_payment_rule CASCADE;
CREATE TABLE admin_view_multiple_day_car_booking_payment_rule(
	id UUID   PRIMARY KEY
	,no_of_days VARCHAR	
	,car_rent_amount_additional_percentage VARCHAR
	,adjust_type VARCHAR
);



--DROP TYPE IF EXISTS customer_cars_rent_price_details CASCADE;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TYPE customer_cars_rent_price_details AS (
	id UUID
	,car_rent_charges NUMERIC
    ,delivery_charges NUMERIC
    ,total_payable NUMERIC
);

--DROP FUNCTION getCustomerBookingCalculatePayment(VARCHAR,VARCHAR,VARCHAR,VARCHAR);

 --SELECT * FROM getCustomerBookingCalculatePayment('2024-09-11 04:34','2024-09-11 10:34','RA 78 HQ 2343','Delivery');


CREATE OR REPLACE FUNCTION getCustomerBookingCalculatePayment(
															    cFromDate VARCHAR,
															    cToDate VARCHAR,
															    cCarNumber VARCHAR,
															    cPickType VARCHAR
															) 
															RETURNS SETOF customer_cars_rent_price_details AS $BODY$

DECLARE
    -- Declare variables

    customerCarsRentPriceDetails customer_cars_rent_price_details;
    noOfCustomerBookingDays NUMERIC := 0;
    carRentPricePerDay NUMERIC := 0;
    holidayCarAdditionalChargesPercent NUMERIC := 0;
    multipleDayRuleRecord RECORD;
    totalBookingPrice NUMERIC := 0;
    deliveryAmount NUMERIC := 0;
    finalPrice NUMERIC := 0;

BEGIN
    /****************************** GET VALUE: NO OF BOOKING DAYS ****************************************/
    SELECT 
        (cToDate::DATE - cFromDate::DATE) + 1
    INTO 
        noOfCustomerBookingDays;

    /****************************** GET VALUE: CAR PRICE PER DAY ****************************************/
    SELECT 
        rcd.price_per_day::NUMERIC
    INTO 
        carRentPricePerDay
    FROM 
        admin_rental_cars_details rcd
    WHERE 
        rcd.car_no = cCarNumber;

    /****************************** PRICE CALCULATION ****************************************/
    IF noOfCustomerBookingDays = 1 THEN
        -- For single day booking, get additional charges
        SELECT 
            ps.car_rent_amount_additional_percentage::NUMERIC
        INTO 
            holidayCarAdditionalChargesPercent
        FROM 
            admin_view_holiday_car_booking_payment_rule ps
        WHERE 
            TO_CHAR(ps.holiday_date, 'DD/MM/YYYY') = TO_CHAR(cFromDate::DATE, 'DD/MM/YYYY');
        
        -- Calculate total price with additional charges
        
        IF holidayCarAdditionalChargesPercent IS NOT NULL THEN 
        	totalBookingPrice := carRentPricePerDay + (carRentPricePerDay * holidayCarAdditionalChargesPercent / 100);
        ELSIF holidayCarAdditionalChargesPercent IS NULL THEN 
        	totalBookingPrice := (carRentPricePerDay * noOfCustomerBookingDays);
		END IF; 

        RAISE NOTICE 'TOTAL BOOKING PRICE FOR 1 DAY: %', totalBookingPrice;

    ELSIF noOfCustomerBookingDays > 1 THEN
    	SELECT 
            ps.*
        INTO 
            multipleDayRuleRecord
        FROM 
            admin_view_multiple_day_car_booking_payment_rule ps
        WHERE 
            ps.no_of_days::NUMERIC = noOfCustomerBookingDays;
        
        IF multipleDayRuleRecord IS NOT NULL THEN 
        	IF multipleDayRuleRecord.adjust_type = 'Increase' THEN
        		totalBookingPrice := ((carRentPricePerDay * noOfCustomerBookingDays) + (carRentPricePerDay * multipleDayRuleRecord.car_rent_amount_additional_percentage::NUMERIC/ 100));
        	ELSIF multipleDayRuleRecord.adjust_type = 'Decrease' THEN
        		totalBookingPrice := ((carRentPricePerDay * noOfCustomerBookingDays) - (carRentPricePerDay * multipleDayRuleRecord.car_rent_amount_additional_percentage::NUMERIC/ 100));
        	END IF;        	
        ELSIF multipleDayRuleRecord IS NULL THEN 
        	totalBookingPrice := (carRentPricePerDay * noOfCustomerBookingDays);
		END IF; 		
        
        RAISE NOTICE 'TOTAL BOOKING PRICE FOR MULTIPLE DAYS: %', totalBookingPrice;
    END IF;

    /****************************** DELIVERY CHARGES ****************************************/
    IF lower(cPickType) = lower('delivery') THEN
  		SELECT
  			dp.property_value::NUMERIC
  		INTO
  			deliveryAmount
  		FROM
  			admin_default_properties dp     
    	WHERE
    		lower(property_name) = 'deliverycharges';
    END IF;
    
    RAISE NOTICE 'DELIVERY CHARGES: %', deliveryAmount;

    -- Calculate final price (total price + delivery amount)
    finalPrice := totalBookingPrice + deliveryAmount;

    FOR customerCarsRentPriceDetails IN
		SELECT 
			/*uuid_generate_v4() as id*/
			gen_random_uuid() as id
			,COALESCE(round(totalBookingPrice),0) as car_rent_charges
            ,COALESCE(deliveryAmount,0) as delivery_charges
            ,COALESCE(round(finalPrice),0) as total_payable
		
	LOOP 

		RETURN NEXT customerCarsRentPriceDetails;

	END LOOP;
    

END;

$BODY$ LANGUAGE plpgsql VOlATILE COST 100;


--DROP TABLE IF EXISTS customer_booking_documents_details CASCADE;
CREATE TABLE customer_booking_documents_details (
    id UUID  PRIMARY KEY
	,customer_name VARCHAR		
	,mobile_no VARCHAR
	,email_id VARCHAR
	,document_type VARCHAR	
	,docuent_number VARCHAR
	,name_on_document VARCHAR
	,file_path VARCHAR		
	,file_name VARCHAR
	,file_type VARCHAR
);
--DROP TABLE IF EXISTS driver_job_request CASCADE;
CREATE TABLE driver_job_request (
    id UUID  PRIMARY KEY
    ,requester_name VARCHAR
    ,requester_contact VARCHAR
    ,message TEXT    
);

--DROP TABLE IF EXISTS customer_car_rent_booking_details CASCADE;
CREATE TABLE customer_car_rent_booking_details (
    id UUID  PRIMARY KEY
    ,created_date TIMESTAMP
    ,customer_name VARCHAR
    ,mobile_no VARCHAR
    ,email_id VARCHAR
    ,car_no VARCHAR
    ,car_name VARCHAR
    ,from_date TIMESTAMP
    ,to_date TIMESTAMP     
    ,pick_up_type VARCHAR
    ,delivery_or_pickup_charges NUMERIC
    ,car_rent_charges NUMERIC
    ,total_payable NUMERIC
    ,approve_status VARCHAR
    ,car_img_name VARCHAR
    ,address VARCHAR
 );




--SELECT 'true'::VARCHAR as status FROM customer_car_rent_booking_details WHERE car_no = 'VW 67 JH 7878' AND to_date < '2024-09-19T20:28' AND to_date < '2024-09-20T17:28' AND approve_status = 'Car Returned';


--DROP TABLE admin_email_template;
CREATE TABLE admin_email_template(
	id UUID   PRIMARY KEY
	,email_subject VARCHAR		
	,email_html_body TEXT		
);


--DROP TABLE admin_user_rights;
CREATE TABLE admin_user_rights(
	id UUID   PRIMARY KEY
	,role_name VARCHAR		
	,rights_object JSON		
);





