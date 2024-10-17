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
	,mobile_no VARCHAR
	,alternative_mobile_no VARCHAR
	,age VARCHAR
	,email_id VARCHAR
	,sign_status VARCHAR
);

--drop table profile_image_details;
CREATE TABLE profile_image_details(
	id VARCHAR   PRIMARY KEY
	,file_path VARCHAR		
	,file_name VARCHAR
	,file_type VARCHAR
	,profile_type VARCHAR
);

--DROP TABLE admin_software_user_details;
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


--drop table admin_rental_cars_upload;
CREATE TABLE admin_rental_cars_upload(
	id UUID   PRIMARY KEY
	,file_path VARCHAR		
	,file_name VARCHAR
	,file_type VARCHAR
	,convert_into_png_status VARCHAR
);

--DROP TABLE IF EXISTS admin_rental_cars_details CASCADE;
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
	,extra_travel_km_per_price VARCHAR
	,price_per_day VARCHAR
	,branch VARCHAR
);




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
--DROP TABLE IF EXISTS customer_feedback_details CASCADE;
CREATE TABLE customer_feedback_details (
    id UUID PRIMARY KEY,
    person_name VARCHAR,
    person_contact VARCHAR,
    person_description TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION set_created_date() RETURNS TRIGGER AS $$
	BEGIN
	    IF NEW.created_date IS NULL THEN
	        NEW.created_date := CURRENT_TIMESTAMP;
	    END IF;
	    RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_set_created_date BEFORE INSERT ON customer_feedback_details
FOR EACH ROW
EXECUTE FUNCTION set_created_date();

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

--SELECT checkCountCarBookingBefore('1111','2024-10-01 05:47:00.0','2024-10-01 06:47:00.0');
DROP FUNCTIONcheckCountCarBookingBefore(VARCHAR,VARCHAR,VARCHAR);
CREATE OR REPLACE FUNCTION checkCountCarBookingBefore(carNO VARCHAR) RETURNS VARCHAR LANGUAGE plpgsql AS $$
		DECLARE
		    status VARCHAR := 'Sold Out';
		    car_no_based_returned_status_count INT;
		    car_no_based_count INT;
		BEGIN
		    
		    SELECT 
		    	COUNT(*) 
		    INTO 
		    	car_no_based_returned_status_count
		    FROM 
		    	customer_car_rent_booking_details s1
		    WHERE 
		    	s1.car_no = carNO
		    	AND s1.approve_status = 'Car Returned';
		    
		    
		    SELECT 
		    	COUNT(*) 
		    INTO 
		    	car_no_based_count
		    FROM 
		    	customer_car_rent_booking_details s2
		    WHERE 
		    	s2.car_no = carNO;
		    
		    
		    IF car_no_based_returned_status_count = car_no_based_count THEN
		        status := 'Book Now';
		    ELSE
		        status := 'Sold Out';
		    END IF;

		    RETURN status;
		END;
$$;

SELECT checkCountCarBookingBefore('1111','2024-10-01 05:47:00.0','2024-10-01 06:47:00.0');

--SELECT EXTRACT(DAY FROM ('2024-10-01 06:47:00.0'::TIMESTAMP - '2024-10-01 05:47:00.0'::TIMESTAMP)) AS days,EXTRACT(HOUR FROM ('2024-10-01 06:47:00.0'::TIMESTAMP - '2024-10-01 05:47:00.0'::TIMESTAMP)) AS hours



--DROP TABLE IF EXISTS admin_view_price_plan_rule_details CASCADE;
CREATE TABLE admin_view_price_plan_rule_details(
	id UUID   PRIMARY KEY
	,limit_km VARCHAR	
	,car_rent_amount_additional_percentage VARCHAR	
);



--DROP FUNCTION IF EXISTS getRentARideCustomerCarsList(VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR) CASCADE;


--SELECT * FROM getRentARideCustomerCarsList('','','','','');	

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
	,no_of_free_km_per_given_date NUMERIC
	,transmission_type VARCHAR
	,fuel_type VARCHAR	
	,extra_travel_km_per_price VARCHAR
	,price_based_on_date NUMERIC
	,branch VARCHAR
	,car_available_status VARCHAR
);

--SELECT * FROM getRentARideCustomerCarsList('2024-09-01 01:00','2024-09-01 04:00','Chennai','Hatchback','Diesel','Automatic','140');
--SELECT price_per_day as given_date_plan_price,is_gps as free_km FROM getRentARideCustomerCarsList('2024-09-01 01:00:00','2024-09-02 01:00:00','Chennai','Hatchback','Diesel','Automatic','320');


CREATE OR REPLACE FUNCTION getRentARideCustomerCarsList(fromDate VARCHAR,toDate VARCHAR,locationArgs VARCHAR,categoryArgs VARCHAR,fuelType VARCHAR,transmissionType VARCHAR,kmLimit VARCHAR) RETURNS SETOF customer_cars_info_list AS $BODY$

	DECLARE
        customerCarsInfoList customer_cars_info_list;
        pricePlanRecord RECORD;
        planKmPerHour NUMERIC := 0;
        noOfHours NUMERIC := 0;
    BEGIN
        
        SELECT 
        	t1.*
        INTO 
        	pricePlanRecord
        FROM 
        	admin_view_price_plan_rule_details t1
        WHERE 
        	limit_km = kmLimit;
        
        planKmPerHour := (pricePlanRecord.limit_km::NUMERIC / 24);

        noOfHours := (SELECT EXTRACT(EPOCH FROM (toDate::TIMESTAMP - fromDate::TIMESTAMP)) / 3600);
        
        FOR customerCarsInfoList IN
            SELECT
                m2.id
                ,m2.brand
                ,m2.car_name
                ,m2.car_no
                ,m2.is_ac
                ,m1.file_name AS img_url
                ,m2.category
                ,m2.no_of_seat
                ,COALESCE(m4.no_of_free_km_per_given_date,0) as no_of_free_km_per_given_date
                ,m2.transmission_type
                ,m2.fuel_type
                ,m2.extra_travel_km_per_price
                ,COALESCE(m4.price_based_on_date,0) as price_based_on_date
                ,m2.branch
			    ,(CASE WHEN m5.car_no_based_returned_status_count = m6.car_no_based_count THEN 'Book Now' ELSE 'Sold Out' END) AS car_available_status                
            FROM
                admin_rental_cars_upload m1
            JOIN
                admin_rental_cars_details m2 ON m1.id = m2.id
            LEFT OUTER JOIN LATERAL (
                SELECT
                    ((m2.price_per_day::NUMERIC + (m2.price_per_day::NUMERIC * pricePlanRecord.car_rent_amount_additional_percentage::NUMERIC) / 100) / 24) AS car_rent_plan_price_per_hour
            ) m3 ON TRUE
            LEFT OUTER JOIN LATERAL (
                SELECT
                    ROUND((m3.car_rent_plan_price_per_hour * noOfHours)) AS price_based_on_date
                    ,ROUND((planKmPerHour * noOfHours)) AS no_of_free_km_per_given_date
            ) m4 ON TRUE
            LEFT OUTER JOIN LATERAL (
                SELECT 
           			COUNT(*) as car_no_based_returned_status_count
           		FROM 
           			customer_car_rent_booking_details s1
             	WHERE 
             		s1.car_no = m2.car_no
             		AND approve_status = 'Car Returned'
            ) m5 ON TRUE
            LEFT OUTER JOIN LATERAL (
                SELECT 
           			COUNT(*) as car_no_based_count
           		FROM 
           			customer_car_rent_booking_details s2
             	WHERE 
             		s2.car_no = m2.car_no             		
            ) m6 ON TRUE
            WHERE
                m2.car_name IS NOT NULL
                AND lower(m2.branch) ILIKE ANY (string_to_array(lower(locationArgs) || '%', ','))
                AND lower(m2.category) ILIKE ANY (string_to_array(lower(categoryArgs) || '%', ','))
                AND lower(m2.fuel_type) ILIKE ANY (string_to_array(lower(fuelType) || '%', ','))
                AND lower(m2.transmission_type) ILIKE ANY (string_to_array(lower(transmissionType) || '%', ','))
        LOOP
            RETURN NEXT customerCarsInfoList;
        END LOOP;
    END;

$BODY$ LANGUAGE plpgsql VOlATILE COST 100;




--DROP TYPE IF EXISTS customer_cars_rent_price_details CASCADE;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TYPE customer_cars_rent_price_details AS (
	id UUID
	,plan_based_payable_charges NUMERIC
	,base_fare NUMERIC
    ,delivery_charges NUMERIC
    ,secuirty_deposite_charges NUMERIC
    ,no_of_leave_day_charges NUMERIC
    ,charges_type VARCHAR
    ,charges_type_based_amount NUMERIC
);

--DROP FUNCTION getCustomerBookingCalculatePayment(VARCHAR,VARCHAR,VARCHAR,VARCHAR);

 --SELECT * FROM getCustomerBookingCalculatePayment('2024-10-04 04:34','2024-10-11 10:34','2100','2000');

CREATE OR REPLACE FUNCTION getCustomerBookingCalculatePayment(
															    cFromDate VARCHAR,
															    cToDate VARCHAR,
															    cCarNumber VARCHAR,
															    cPlanBasedPayable VARCHAR
															) 
															RETURNS SETOF customer_cars_rent_price_details AS $BODY$

DECLARE    
    customerCarsRentPriceDetails customer_cars_rent_price_details;
    noOfCustomerBookingDays NUMERIC := 0;
    carRentPricePerDay NUMERIC := 0;
    multipleDayRuleRecord RECORD;
    deliveryAmount NUMERIC := 0;
    securityDepositAmount NUMERIC := 0;
    finalPrice NUMERIC := 0;

    countDate DATE := cFromDate::DATE;
    leaveDayBookingCharges NUMERIC := 0;
    chargesType VARCHAR := 'Additional Charges';
    chargesTypeBasedAmount NUMERIC := 0;

    holidayCarAdditionalChargesPercent NUMERIC := 0; -- Moved declaration outside the loop for consistency

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

    RAISE NOTICE 'CAR RENT PRICE PER DAY: %', carRentPricePerDay;
    /************************************ PRICE CALCULATION *********************************************/
    
    WHILE countDate <= cToDate::DATE LOOP

        holidayCarAdditionalChargesPercent := 0; -- Reset the value in each iteration

        SELECT 
            ps.car_rent_amount_additional_percentage::NUMERIC
        INTO 
            holidayCarAdditionalChargesPercent
        FROM 
            admin_view_holiday_car_booking_payment_rule ps
        WHERE 
            TO_CHAR(ps.holiday_date, 'DD/MM/YYYY') = TO_CHAR(countDate, 'DD/MM/YYYY');
        
        IF holidayCarAdditionalChargesPercent IS NOT NULL THEN 
        	RAISE NOTICE 'HOLIDAY CAR ADDITIONAL CHARGES PERCENT: %', holidayCarAdditionalChargesPercent;
        	RAISE NOTICE 'HOLIDAY CAR ADDITIONAL CHARGES PRICE AMOUNT: %', ROUND(carRentPricePerDay * holidayCarAdditionalChargesPercent / 100);

            leaveDayBookingCharges := ROUND(leaveDayBookingCharges + (carRentPricePerDay * holidayCarAdditionalChargesPercent / 100));        

            RAISE NOTICE 'countDate: %', countDate;
        	RAISE NOTICE 'leaveDayBookingCharges: %', leaveDayBookingCharges;
        END IF;        
        countDate := countDate + INTERVAL '1 day';

    END LOOP;

    RAISE NOTICE 'LEAVE DAYS BOOKING CHARGES: %', leaveDayBookingCharges;

    IF noOfCustomerBookingDays > 1 THEN

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
                chargesType := 'Additional Charges';
                chargesTypeBasedAmount := (carRentPricePerDay * multipleDayRuleRecord.car_rent_amount_additional_percentage::NUMERIC / 100);
            ELSIF multipleDayRuleRecord.adjust_type = 'Decrease' THEN
                chargesType := 'Discount';
                chargesTypeBasedAmount := (carRentPricePerDay * multipleDayRuleRecord.car_rent_amount_additional_percentage::NUMERIC / 100);
            END IF;
        ELSE
            chargesType := 'Additional Charges';
            chargesTypeBasedAmount := 0;
        END IF;
        
        RAISE NOTICE 'CHARGES TYPE: %', chargesType;
        RAISE NOTICE 'CHARGES TYPE BASED AMOUNT: %', chargesTypeBasedAmount;
    END IF;

    /****************************** DELIVERY CHARGES ****************************************/
    
    SELECT
        dp.property_value::NUMERIC
    INTO
        deliveryAmount
    FROM
        admin_default_properties dp     
    WHERE
        lower(property_name) = 'deliverycharges';

    RAISE NOTICE 'DELIVERY CHARGES: %', deliveryAmount;
    
    /****************************** SECURITY DEPOSIT CHARGES ****************************************/

    SELECT
        pd.property_value::NUMERIC
    INTO
        securityDepositAmount
    FROM
        admin_default_properties pd     
    WHERE
        lower(property_name) = 'secuirtydepositecharges';

    RAISE NOTICE 'SECURITY DEPOSIT CHARGES: %', securityDepositAmount;

    /********************************* FINAL OUTPUT ******************************************/

    FOR customerCarsRentPriceDetails IN
        SELECT 
            gen_random_uuid() as id	            
            ,COALESCE(cPlanBasedPayable::NUMERIC, 0) as plan_based_payable_charges   
            ,COALESCE(carRentPricePerDay,0) as base_fare         
            ,COALESCE(deliveryAmount, 0) as delivery_charges
            ,COALESCE(securityDepositAmount, 0) as secuirty_deposite_charges
            ,COALESCE(leaveDayBookingCharges, 0) as no_of_leave_day_charges
            ,chargesType as charges_type
            ,chargesTypeBasedAmount as charges_type_based_amount
    LOOP 
        RETURN NEXT customerCarsRentPriceDetails;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'An error occurred: %', SQLERRM;
        RETURN;
END;

$BODY$ LANGUAGE plpgsql VOLATILE COST 100;


--DROP FUNCTION getRentARideAdminViewCarsList(VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR);
--SELECT * FROM getRentARideAdminViewCarsList('','Chennai','Hatchback','Diesel','Automatic','Yes','No','11','as3');
--SELECT * FROM getRentARideAdminViewCarsList('','','','','','','','');

CREATE OR REPLACE FUNCTION public.getRentARideAdminViewCarsList(
																	infoType VARCHAR
																	,locationArgs VARCHAR
																    ,categoryArgs VARCHAR
																    ,fuelType VARCHAR
																    ,transmissionType VARCHAR
																    ,itsHaveGPS VARCHAR
																    ,itsHaveAC VARCHAR
																    ,extraTravelPricePerKm VARCHAR
																    ,carNo VARCHAR
																)
																RETURNS SETOF admin_rental_cars_details
																LANGUAGE 'plpgsql'
																VOLATILE
																PARALLEL UNSAFE
																COST 100
																ROWS 1000
																AS $BODY$
	BEGIN
    	

    	IF (infoType= 'Info') THEN

	    	RETURN QUERY
		    SELECT 
		        m2.*
		    FROM
		        admin_rental_cars_upload m1
		    JOIN
		        admin_rental_cars_details m2
		    ON
		        m1.id = m2.id
		    WHERE
		    	m2.car_name IS NOT NULL
		        AND lower(m2.branch) ILIKE ANY(string_to_array(lower(locationArgs) || '%', ','))
		        AND lower(m2.category) ILIKE ANY(string_to_array(lower(categoryArgs) || '%', ','))
		        AND lower(m2.fuel_type) ILIKE ANY(string_to_array(lower(fuelType) || '%', ','))
		        AND lower(m2.transmission_type) ILIKE ANY(string_to_array(lower(transmissionType) || '%', ','))
		        AND lower(m2.is_gps) ILIKE ANY(string_to_array(lower(itsHaveGPS) || '%', ','))
		        AND lower(m2.is_ac) ILIKE ANY(string_to_array(lower(itsHaveAC) || '%', ','))
		        AND lower(m2.extra_travel_km_per_price) ILIKE ANY(string_to_array(lower(extraTravelPricePerKm) || '%', ','))
		        AND lower(m2.car_no) ILIKE ANY(string_to_array(lower(carNo) || '%', ','));

		ELSIF infoType= 'Null' THEN

			RETURN QUERY
			SELECT 
		        mm2.*
		    FROM
		        admin_rental_cars_upload mm1
		    JOIN
		        admin_rental_cars_details mm2
		    ON
		        mm1.id = mm2.id
		    WHERE
		    	mm2.car_name IS NULL;

		ELSIF infoType= '' THEN

			RETURN QUERY
			SELECT 
		        mm2.*
		    FROM
		        admin_rental_cars_upload mm1
		    JOIN
		        admin_rental_cars_details mm2
		    ON
		        mm1.id = mm2.id;
		    
		END IF;


	END;

$BODY$;




--DROP SEQUENCE IF EXISTS cb_sequence;
CREATE SEQUENCE cb_sequence START 1	INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_cb_key() RETURNS TEXT AS $$
	DECLARE
	    seq_value INT;
	BEGIN	    
	    seq_value := nextval('cb_sequence');	    
	    RETURN 'CB_' || seq_value;
	END;
$$ LANGUAGE plpgsql;


		
--DROP TABLE IF EXISTS customer_car_rent_booking_details CASCADE;
CREATE TABLE customer_car_rent_booking_details (
    id UUID  PRIMARY KEY
    ,ticket_id VARCHAR
    ,created_date TIMESTAMP
    ,customer_name VARCHAR
    ,mobile_no VARCHAR
    ,email_id VARCHAR
    ,car_no VARCHAR
    ,car_name VARCHAR
    ,pick_up_date TIMESTAMP
    ,return_date TIMESTAMP     
    ,pick_up_type VARCHAR    
    ,approve_status VARCHAR
    ,car_img_name VARCHAR
    ,address VARCHAR
    ,extra_info VARCHAR
    ,duration VARCHAR
    ,free_km  VARCHAR
    ,plan_based_payable_charges NUMERIC
	,base_fare NUMERIC
    ,delivery_or_pickup_charges NUMERIC    
    ,secuirty_deposite_charges NUMERIC
    ,no_of_leave_day_charges NUMERIC
    ,charges_type VARCHAR
    ,charges_type_based_amount NUMERIC
    ,total_payable NUMERIC
 );


--DROP TABLE admin_whatsapp_template;
CREATE TABLE admin_whatsapp_template(
	id UUID   PRIMARY KEY
	,whatsapp_subject VARCHAR		
	,url TEXT
	,reference_key TEXT			
);

--TRUNCATE admin_whatsapp_template
INSERT INTO admin_whatsapp_template values (gen_random_uuid(),'CAR RENTAL SERVICE - Car Rental Price Information','','<br/>Customer Name: {{name}}
<br/>Customer Mobile Number: {{mobileNo}}									
<br/>Category: {{category}}
<br/>Brand: {{brand}}
<br/>Car Name: {{carName}}
<br/>Car Number: {{carNo}}
<br/>Number of Seats: {{noOfSeats}}
<br/>Fuel Type: {{fuelType}}
<br/>Transmission Type: {{transmissionType}}
<br/>Charges Type: {{chargesType}}
<br/>Charges Type Based Amount: {{chargesTypeBasedAmount}}
<br/>Number of Leave Day Charges: {{noOfLeaveDayCharges}}
<br/>Security Deposit Charges: {{securityDepositCharges}}
<br/>Deliverycharges :{{devliveryOrPickupCharges}}										
<br/>Plan Based Payable Charges: {{planBasedPayableCharges}}
<br/>Base Fare: {{baseFare}}
<br/>Pickup Date: {{pickupDate}}
<br/>Return Date: {{returnDate}}
<br/>Base Fare: {{baseFare}}
');

INSERT INTO admin_whatsapp_template values (gen_random_uuid(),'CAR RENTAL SERVICE - Car Rental Feedback Information','','Customer Name: {{name}}<br/>Customer Mobile Number: {{mobileNo}}');

INSERT INTO admin_whatsapp_template values (gen_random_uuid(),'CAR RENTAL SERVICE - Hope your travels were amazing! Lets catch up soon ','','Customer Name: {{name}}<br/>Customer Mobile Number: {{mobileNo}}');


INSERT INTO admin_whatsapp_template values (gen_random_uuid(),'CAR RENTAL SERVICE - Car Reservation Confirmation ','','<br/>Customer Name: {{name}}
<br/>Customer Mobile Number: {{mobileNo}}
<br/>Pickup Date: {{pickupDate}}
<br/>Return Date: {{returnDate}}
<br/>Total totalPayable: {{totalPayable}}');

INSERT INTO admin_whatsapp_template values (gen_random_uuid(),'CAR RENTAL SERVICE - Profile Update','','Customer Name: {{name}}<br/>Customer Mobile Number: {{mobileNo}}');

INSERT INTO admin_whatsapp_template values (gen_random_uuid(),'CAR RENTAL SERVICE - Password Update Notification','','Customer Name: {{name}}<br/>Customer Mobile Number: {{mobileNo}}');


INSERT INTO admin_whatsapp_template values (gen_random_uuid(),'CAR RENTAL SERVICE - Car Booking Reservation Alerted','','<br/>Customer Name: {{name}}
<br/>Customer Mobile Number: {{mobileNo}}
<br/>Pickup Date: {{pickupDate}}
<br/>Return Date: {{returnDate}}
<br/>Total totalPayable: {{totalPayable}}');















