--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: customer_cars_info_list; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.customer_cars_info_list AS (
	id uuid,
	brand character varying,
	car_name character varying,
	car_no character varying,
	is_ac character varying,
	img_url character varying,
	category character varying,
	no_of_seat character varying,
	no_of_free_km_per_given_date numeric,
	transmission_type character varying,
	fuel_type character varying,
	extra_travel_km_per_price character varying,
	price_based_on_date numeric,
	branch character varying,
	car_available_status character varying
);


ALTER TYPE public.customer_cars_info_list OWNER TO postgres;

--
-- Name: customer_cars_rent_price_details; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.customer_cars_rent_price_details AS (
	id uuid,
	pick_up_date_char character varying,
	return_date_char character varying,
	plan_based_payable_charges numeric,
	base_fare numeric,
	delivery_charges numeric,
	secuirty_deposite_charges numeric,
	no_of_leave_day_charges numeric,
	charges_type character varying,
	charges_type_based_amount numeric
);


ALTER TYPE public.customer_cars_rent_price_details OWNER TO postgres;

--
-- Name: checkcountcarbookingbefore(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.checkcountcarbookingbefore(carno character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
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


ALTER FUNCTION public.checkcountcarbookingbefore(carno character varying) OWNER TO postgres;

--
-- Name: getcustomerbookingcalculatepayment(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getcustomerbookingcalculatepayment(cfromdate character varying, ctodate character varying, ccarnumber character varying, cplanbasedpayable character varying) RETURNS SETOF public.customer_cars_rent_price_details
    LANGUAGE plpgsql
    AS $$

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
            ,cFromDate as pick_up_date_char
            ,cToDate as return_date_char
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

$$;


ALTER FUNCTION public.getcustomerbookingcalculatepayment(cfromdate character varying, ctodate character varying, ccarnumber character varying, cplanbasedpayable character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_rental_cars_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_rental_cars_details (
    id uuid NOT NULL,
    brand character varying(255),
    car_name character varying(255),
    car_no character varying(255),
    is_ac character varying(255),
    img_url character varying(255),
    category character varying(255),
    no_of_seat character varying(255),
    is_gps character varying(255),
    transmission_type character varying(255),
    fuel_type character varying(255),
    extra_travel_km_per_price character varying(255),
    price_per_day character varying(255),
    branch character varying(255)
);


ALTER TABLE public.admin_rental_cars_details OWNER TO postgres;

--
-- Name: getrentarideadminviewcarslist(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getrentarideadminviewcarslist(infotype character varying, locationargs character varying, categoryargs character varying, fueltype character varying, transmissiontype character varying, itshavegps character varying, itshaveac character varying, extratravelpriceperkm character varying, carno character varying) RETURNS SETOF public.admin_rental_cars_details
    LANGUAGE plpgsql
    AS $$
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

$$;


ALTER FUNCTION public.getrentarideadminviewcarslist(infotype character varying, locationargs character varying, categoryargs character varying, fueltype character varying, transmissiontype character varying, itshavegps character varying, itshaveac character varying, extratravelpriceperkm character varying, carno character varying) OWNER TO postgres;

--
-- Name: getrentaridecustomercarslist(character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getrentaridecustomercarslist(fromdate character varying, todate character varying, locationargs character varying, categoryargs character varying, fueltype character varying, transmissiontype character varying, kmlimit character varying) RETURNS SETOF public.customer_cars_info_list
    LANGUAGE plpgsql
    AS $$

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

$$;


ALTER FUNCTION public.getrentaridecustomercarslist(fromdate character varying, todate character varying, locationargs character varying, categoryargs character varying, fueltype character varying, transmissiontype character varying, kmlimit character varying) OWNER TO postgres;

--
-- Name: set_created_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_created_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.created_date IS NULL THEN
        NEW.created_date := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_created_date() OWNER TO postgres;

--
-- Name: a; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a (
    total_hours numeric
);


ALTER TABLE public.a OWNER TO postgres;

--
-- Name: admin_cars_category_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_cars_category_seq
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_cars_category_seq OWNER TO postgres;

--
-- Name: admin_default_properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_default_properties (
    id uuid NOT NULL,
    property_name character varying(255),
    property_value character varying(255),
    email_html_body character varying(255),
    email_subject character varying(255)
);


ALTER TABLE public.admin_default_properties OWNER TO postgres;

--
-- Name: admin_email_template; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_email_template (
    id uuid NOT NULL,
    email_subject character varying(255),
    email_html_body text
);


ALTER TABLE public.admin_email_template OWNER TO postgres;

--
-- Name: admin_rental_cars_upload; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_rental_cars_upload (
    id uuid NOT NULL,
    file_path character varying(255),
    file_name character varying(255),
    file_type character varying(255),
    convert_into_png_status character varying(255)
);


ALTER TABLE public.admin_rental_cars_upload OWNER TO postgres;

--
-- Name: admin_software_user_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_software_user_details (
    user_id character varying(255) NOT NULL,
    password character varying(255),
    email_id character varying(255),
    mobile_no character varying(255),
    role_name character varying(255),
    branch character varying(255)
);


ALTER TABLE public.admin_software_user_details OWNER TO postgres;

--
-- Name: admin_user_rights; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_user_rights (
    id uuid NOT NULL,
    role_name character varying(255),
    rights_object text
);


ALTER TABLE public.admin_user_rights OWNER TO postgres;

--
-- Name: admin_view_holiday_car_booking_payment_rule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_view_holiday_car_booking_payment_rule (
    id uuid NOT NULL,
    holiday_date timestamp(6) without time zone,
    car_rent_amount_additional_percentage character varying(255)
);


ALTER TABLE public.admin_view_holiday_car_booking_payment_rule OWNER TO postgres;

--
-- Name: admin_view_multiple_day_car_booking_payment_rule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_view_multiple_day_car_booking_payment_rule (
    id uuid NOT NULL,
    no_of_days character varying(255),
    car_rent_amount_additional_percentage character varying(255),
    adjust_type character varying(255),
    limit_km character varying(255)
);


ALTER TABLE public.admin_view_multiple_day_car_booking_payment_rule OWNER TO postgres;

--
-- Name: admin_view_price_plan_rule_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_view_price_plan_rule_details (
    id uuid NOT NULL,
    limit_km character varying(255),
    car_rent_amount_additional_percentage character varying(255)
);


ALTER TABLE public.admin_view_price_plan_rule_details OWNER TO postgres;

--
-- Name: admin_whatsapp_template; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_whatsapp_template (
    id uuid NOT NULL,
    whatsapp_subject character varying(255),
    url text,
    reference_key text
);


ALTER TABLE public.admin_whatsapp_template OWNER TO postgres;

--
-- Name: cars; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cars (
    brand character varying(255),
    model character varying(255),
    year character varying(255),
    email_id character varying(255),
    mobile_no character varying(255),
    password character varying(255)
);


ALTER TABLE public.cars OWNER TO postgres;

--
-- Name: cars_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cars_seq
    START WITH 1
    INCREMENT BY 50
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cars_seq OWNER TO postgres;

--
-- Name: customer_booking_documents_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_booking_documents_details (
    id uuid NOT NULL,
    customer_name character varying(255),
    mobile_no character varying(255),
    email_id character varying(255),
    document_type character varying(255),
    docuent_number character varying,
    name_on_document character varying(255),
    file_path character varying(255),
    file_name character varying(255),
    file_type character varying(255),
    document_number character varying(255)
);


ALTER TABLE public.customer_booking_documents_details OWNER TO postgres;

--
-- Name: customer_car_rent_booking_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_car_rent_booking_details (
    id uuid NOT NULL,
    created_date timestamp without time zone,
    customer_name character varying(255),
    mobile_no character varying(255),
    email_id character varying(255),
    car_no character varying(255),
    car_name character varying(255),
    pick_up_date timestamp without time zone,
    return_date timestamp without time zone,
    pick_up_type character varying(255),
    approve_status character varying(255),
    car_img_name character varying(255),
    address character varying(255),
    extra_info character varying(255),
    duration character varying(255),
    free_km character varying(255),
    plan_based_payable_charges integer,
    base_fare integer,
    delivery_or_pickup_charges integer,
    secuirty_deposite_charges integer,
    no_of_leave_day_charges integer,
    charges_type character varying(255),
    charges_type_based_amount integer,
    total_payable integer
);


ALTER TABLE public.customer_car_rent_booking_details OWNER TO postgres;

--
-- Name: customer_cars_info_list_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_cars_info_list_type (
    id uuid NOT NULL,
    branch character varying(255),
    brand character varying(255),
    car_name character varying(255),
    car_no character varying(255),
    category character varying(255),
    extra_travel_km_per_price character varying(255),
    fuel_type character varying(255),
    img_url character varying(255),
    no_of_free_km_per_given_date character varying(255),
    no_of_seat character varying(255),
    is_ac character varying(255),
    price_based_on_date character varying(255),
    transmission_type character varying(255),
    car_available_status character varying(255)
);


ALTER TABLE public.customer_cars_info_list_type OWNER TO postgres;

--
-- Name: customer_cars_rent_price_details_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_cars_rent_price_details_type (
    id uuid NOT NULL,
    car_rent_charges integer NOT NULL,
    delivery_charges character varying(255),
    total_payable character varying(255),
    charges_type character varying(255),
    charges_type_based_amount integer,
    no_of_leave_day_charges integer,
    plan_based_payable_charges integer,
    secuirty_deposite_charges integer,
    base_fare integer,
    pick_up_date_char character varying(255),
    return_date_char character varying(255)
);


ALTER TABLE public.customer_cars_rent_price_details_type OWNER TO postgres;

--
-- Name: customer_feedback; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_feedback (
    id uuid NOT NULL,
    person_name character varying,
    person_contact character varying,
    person_description text
);


ALTER TABLE public.customer_feedback OWNER TO postgres;

--
-- Name: customer_feedback_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_feedback_details (
    id uuid NOT NULL,
    person_name character varying(255),
    person_contact character varying(255),
    person_description text,
    created_date date DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.customer_feedback_details OWNER TO postgres;

--
-- Name: customer_registration_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_registration_details (
    id uuid,
    name character varying(255),
    mobile_no character varying(255),
    alternative_mobile_no character varying(255),
    age character varying(255),
    email_id character varying(255),
    sign_status character varying(255)
);


ALTER TABLE public.customer_registration_details OWNER TO postgres;

--
-- Name: profile_image_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile_image_details (
    id character varying(255) NOT NULL,
    file_path character varying(255),
    file_name character varying(255),
    file_type character varying(255),
    profile_type character varying(255)
);


ALTER TABLE public.profile_image_details OWNER TO postgres;

--
-- Name: 33256; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33256');


ALTER LARGE OBJECT 33256 OWNER TO postgres;

--
-- Name: 33257; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33257');


ALTER LARGE OBJECT 33257 OWNER TO postgres;

--
-- Name: 33258; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33258');


ALTER LARGE OBJECT 33258 OWNER TO postgres;

--
-- Name: 33259; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33259');


ALTER LARGE OBJECT 33259 OWNER TO postgres;

--
-- Name: 33260; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33260');


ALTER LARGE OBJECT 33260 OWNER TO postgres;

--
-- Name: 33261; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33261');


ALTER LARGE OBJECT 33261 OWNER TO postgres;

--
-- Name: 33262; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33262');


ALTER LARGE OBJECT 33262 OWNER TO postgres;

--
-- Name: 33263; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33263');


ALTER LARGE OBJECT 33263 OWNER TO postgres;

--
-- Name: 33264; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33264');


ALTER LARGE OBJECT 33264 OWNER TO postgres;

--
-- Name: 33265; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33265');


ALTER LARGE OBJECT 33265 OWNER TO postgres;

--
-- Name: 33266; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33266');


ALTER LARGE OBJECT 33266 OWNER TO postgres;

--
-- Name: 33267; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33267');


ALTER LARGE OBJECT 33267 OWNER TO postgres;

--
-- Name: 33268; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33268');


ALTER LARGE OBJECT 33268 OWNER TO postgres;

--
-- Name: 33269; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33269');


ALTER LARGE OBJECT 33269 OWNER TO postgres;

--
-- Name: 33319; Type: BLOB; Schema: -; Owner: postgres
--

SELECT pg_catalog.lo_create('33319');


ALTER LARGE OBJECT 33319 OWNER TO postgres;

--
-- Data for Name: a; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.a (total_hours) FROM stdin;
52.5000000000000000
\.


--
-- Data for Name: admin_default_properties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_default_properties (id, property_name, property_value, email_html_body, email_subject) FROM stdin;
e8fe4516-887d-42ec-9ff8-16eb3ec38e4c	DeliveryCharges	1000	\N	\N
ad98589b-2142-4b1a-bf44-984f8f95b8ba	SecuirtyDepositeCharges	1500	\N	\N
a2118d07-c164-41a9-bd0d-5d261fd4cc62	Extra Travel Price Per Km	,11,8,15	\N	\N
219ea9d9-e535-44b4-a826-d3d9af6efa5d	Branch	,Chennai,Thiruvallur,Madurai,Trichy,Selam	\N	\N
06c9aa96-a706-4adc-9722-2ce164299c2f	Category	,Hatchback,SUV,MUV,luxury,Sedan	\N	\N
\.


--
-- Data for Name: admin_email_template; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_email_template (id, email_subject, email_html_body) FROM stdin;
201465b4-4965-49d6-b25b-87f391885509	CAR RENTAL SERVICE - Hope your travels were amazing! Let's catch up soon 	<!DOCTYPE html>\n<html lang="en" style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0px;padding: 0px;">\n<head>\n\t<meta charset="UTF-8">\n\t<meta name="viewport" content="width=device-width, initial-scale=1.0">\n\t<title>Rental Cars</title>\n</head>\n<body style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0px;padding: 0px;">    \n  <div class="job-card" style="position:relative;\n    height:350px;\n    width:300px;\n    left:10%;\n    top:10%;\n    background-color: #000d6b;\n    box-shadow: 0 4px 8px rgba(0,0,0,0.1);    \n    border-radius: 8px;\n    text-align:justify;\n    margin:20px;\n    padding:20px;\n    text-align:justify;\n    ">\n    <div class="headerMessage" style="position:relative;\n                                      height:10px;\n                                      width:80%;\n                                      margin-left:35px;    \n                                      color:white;\n                                      font-weight:bold;\n                                      margin-top:50px;\n    ">Welcome to Rental Cars Service</div>\n    <div class="messagecls" style="position: relative;\n                                    height: 140px;\n                                    width: 80%;\n                                    margin-left:35px;\n                                    font-size: 14px;\n                                    color: orange;\n                                    text-wrap: balance;\n                                    \n                                    overflow:hidden;\n                                     margin-top:50px;\n  ">Hi ${name},<br/>\n     <b> Successfully Register your Account</b>,\n      Now your have provision to book cars for your trip .                \n    </div>\n\n    <button class="buttonCls" style="position:relative;\n                                     height:35px;\n                                     width:50%;\n                                     margin-left:35px;  \n                                     background-color: #0073b1;    \n                                     border: none;    \n                                     border-radius: 5px;\n                                     cursor: pointer; \n    \n"><a href="https://rentalcar.smartyuppies.com" style="color: white;\ntext-decoration :none;">Website</a></button>\n  </div>\n</body>\n</html>\n    
04c3fa6d-bf30-4bde-8fbb-d76373ae82b0	CAR RENTAL SERVICE - Car Rental Price Information	<!DOCTYPE html>\n<html lang="en" style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0px;padding: 0px;">\n<head>\n\t<meta charset="UTF-8">\n\t<meta name="viewport" content="width=device-width, initial-scale=1.0">\n\t<title>Rental Cars</title>\n</head>\n<body style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0px;padding: 0px;">    \n  <div class="job-card" style="position:relative;\n    height:1100px;\n    width:300px;\n    left:10%;\n    top:10%;\n    background-color: #000d6b;\n    box-shadow: 0 4px 8px rgba(0,0,0,0.1);    \n    border-radius: 8px;\n    text-align:justify;\n    margin:20px;\n    padding:20px;\n    text-align:justify;\n    ">\n    <div class="headerMessage" style="position:relative;\n                                      height:10px;\n                                      width:80%;\n                                      margin-left:35px;    \n                                      color:white;\n                                      font-weight:bold;\n                                      margin-top:50px;\n    ">Welcome to Rental Cars Service</div>\n    <div class="messagecls" style="position: relative;\n                                    height: 900px;\n                                    width: 80%;\n                                    margin-left:35px;\n                                    font-size: 14px;\n                                    color: orange;\n                                    text-wrap: balance;\n                                    \n                                    overflow:hidden;\n                                     margin-top:50px;\n  ">\n      \n      Dear ${name},<br/><br/>   \n\n      \t\t\t\tThank you for reaching out to us regarding car rental prices. We are happy to provide the following details:<br/><br/>\nCategory    : ${category}<br/>\nCar Brand   : ${brand}<br/>\nCar Model   : ${carName}<br/>\nCar Number: ${carNo}<br/>\nNo.of Seats : ${noOfSeats}<br/>\nFuel Type   : ${fuelType}<br/>\nTransmission<br/>\nType   \t\t: ${transmissionType}<br/>\nDiscounts\t: Based on Reversing time period (or) No.of days / Duration.<br/><br/>\nBase Fare \t: ${baseFare}<br/>\nPlan Based Payable Charges : ${planBasedPayableCharges}<br/>\n${chargesType} : ${chargesTypeBasedAmount}<br/>\nDelivery Charges: ${deliveryCharges}<br/>\nSecurity Deposite Charges: ${securityDepositeCharges}<br/>\nNO.Of Leave Day Charges: ${noOfLeaveDayCharges}<br/>\n\n\nIf you have any specific preferences or questions, please let us know. We would be happy to assist you further with your booking.<br/><br/>\n\nWe look forward to helping you with your car rental needs.<br/><br/>\n\nBest regards,<br/>\nRental cars service team.\n\n    </div>\n\n    <button class="buttonCls" style="position:relative;\n                                     height:35px;\n                                     width:50%;\n                                     margin-left:35px;  \n                                     background-color: #0073b1;    \n                                     border: none;    \n                                     border-radius: 5px;\n                                     cursor: pointer; \n    \n"><a href="https://rentalcar.smartyuppies.com" style="color: white;\ntext-decoration :none;">Website</a></button>\n  </div>\n</body>\n</html>\n    
d81ecda4-2e2c-401b-b5e5-52aff4d3f5b7	CAR RENTAL SERVICE - Password Update Notification	<!DOCTYPE html>\n<html lang="en" style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0;padding: 0;">\n<head>\n    <meta charset="UTF-8">\n    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n    <title>Password Update Notification</title>\n</head>\n<body style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0;padding: 0;">\n    <div class="job-card" style="position:relative;\n                                  height:750px;\n                                  width:300px;\n                                  left:10%;\n                                  top:10%;\n                                  background-color: #000d6b;\n                                  box-shadow: 0 4px 8px rgba(0,0,0,0.1);\n                                  border-radius: 8px;\n                                  margin:20px;\n                                  padding:20px;\n                                  text-align:justify;\n                                  color:white;">\n        \n        <!-- Header Message -->\n           <div class="headerMessage" style="position:relative;\n                                      height:10px;\n                                      width:80%;\n                                      margin-left:35px;    \n                                      color:white;\n                                      font-weight:bold;\n                                      margin-top:50px;\n    ">\n            Password Updated Successfully!\n        </div>\n\n        <!-- Message Content -->\n        <div class="messagecls" style="position: relative;\n                                        width: 80%;\n                                        margin-left:35px;\n                                        font-size: 14px;\n                                        color: orange;\n                                        text-wrap: balance;\n                                        line-height: 1.6;\n                                        margin-top:50px;">\n            Dear ${name},<br/><br/>\n            We wanted to let you know that your password has been updated successfully. If you did not make this change, please contact our support team immediately.<br/><br/>\n\n            Here are some tips to keep your account secure:<br/>\n            - Use a strong password with a mix of letters, numbers, and special characters.<br/>\n            - Never share your password with anyone.<br/><br/>\n\n            If you have any questions or need assistance, feel free to reach out to us.<br/><br/>\n\n            Best regards,<br/>\n            The Rental Cars Service Team\n        </div>\n\n        <!-- Button -->\n        <div style="text-align:center;">\n            <a href="https://rentalcar.smartyuppies.com"\n               class="buttonCls" style="display:inline-block;\n                                        background-color:#0073b1;\n                                        color:white;\n                                        padding:10px 20px;\n                                        border-radius:5px;\n                                        text-decoration:none;\n                                        font-size:14px;\n                                        cursor:pointer;\n                                        margin-top: 20px;">\nWebsite\n            </a>\n        </div>\n    </div>\n</body>\n\n</html>
c33b2113-b361-4c89-92fd-b8b42c793978	CAR RENTAL SERVICE - Profile Update	<!DOCTYPE html>\n<html lang="en" style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0px;padding: 0px;">\n<head>\n\t<meta charset="UTF-8">\n\t<meta name="viewport" content="width=device-width, initial-scale=1.0">\n\t<title>Rental Cars</title>\n</head>\n<body style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0px;padding: 0px;">    \n  <div class="job-card" style="position:relative;\n    height:350px;\n    width:300px;\n    left:10%;\n    top:10%;\n    background-color: #000d6b;\n    box-shadow: 0 4px 8px rgba(0,0,0,0.1);    \n    border-radius: 8px;\n    text-align:justify;\n    margin:20px;\n    padding:20px;\n    text-align:justify;\n    ">\n    <div class="headerMessage" style="position:relative;\n                                      height:10px;\n                                      width:80%;\n                                      margin-left:35px;    \n                                      color:white;\n                                      font-weight:bold;\n                                      margin-top:50px;\n    ">Welcome to Rental Cars Service</div>\n    <div class="messagecls" style="position: relative;\n                                    height: 140px;\n                                    width: 80%;\n                                    margin-left:35px;\n                                    font-size: 14px;\n                                    color: orange;\n                                    text-wrap: balance;\n                                    \n                                    overflow:hidden;\n                                     margin-top:50px;\n  ">Hi ${name},<br/>\n     <b> Successfully Update your Profile Account</b>,\n      Now you have provision to book cars for your trip .                \n    </div>\n\n    <button class="buttonCls" style="position:relative;\n                                     height:35px;\n                                     width:50%;\n                                     margin-left:35px;  \n                                     background-color: #0073b1;    \n                                     border: none;    \n                                     border-radius: 5px;\n                                     cursor: pointer; \n    \n"><a href="https://rentalcar.smartyuppies.com" style="color: white;\ntext-decoration :none;">Website</a></button>\n  </div>\n</body>\n</html>\n    
542d8697-5a28-48f9-b0c6-030cf2f888fe	CAR RENTAL SERVICE - Car Reservation Confirmation	\n    @<!DOCTYPE html>\n<html lang="en" style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0;padding: 0;">\n<head>\n    <meta charset="UTF-8">\n    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n    <title>Car Reservation Confirmation</title>\n</head>\n<body style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0;padding: 0;">\n    <div class="job-card" style="position:relative;\n                                  height:1000px;\n                                  width:300px;\n                                  left:10%;\n                                  top:10%;\n                                  background-color: #000d6b;\n                                  box-shadow: 0 4px 8px rgba(0,0,0,0.1);\n                                  border-radius: 8px;\n                                  margin:20px;\n                                  padding:20px;\n                                  text-align:justify;\n                                  color:white;">\n        <!-- Header Message -->\n       \n        <div class="headerMessage" style="position:relative;\n                                      height:10px;\n                                      width:80%;\n                                      margin-left:35px;    \n                                      color:white;\n                                      font-weight:bold;\n                                      margin-top:50px;\n    "> Your Car Reservation is Confirmed!</div>\n\n        <!-- Reservation Details -->\n        <div class="messagecls" style="position: relative;\n                                        width: 80%;\n                                        margin-left:35px;\n                                        font-size: 14px;\n                                        color: orange;\n                                        text-wrap: balance;\n                                        line-height: 1.6;\n                                        margin-top:50px;">\n            Dear ${name},<br/><br/>\n            We are thrilled to confirm your car reservation! Below are your reservation details:<br/><br/>\n\n            <strong>Pickup Date & Time</strong>: ${fromDate} <br/>\n            <strong>Return Date & Time</strong>: ${toDate} <br/><br/>\n\n            <strong>Car Details:</strong><br/>            \n            <strong>Car Model</strong>: ${carName}<br/>\n            <strong>Car Number</strong>: ${carNo}<br/>\n            <strong>Total Payable</strong>: ${totalPayable}<br/>\n            <strong>DeliveryCharge/PickupCharge</strong>: ${deliveryOrPickupCharges} <br/><br/>\n\n            If you have any specific preferences or additional requests, feel free to reach out to us.<br/><br/>\n\n            We look forward to providing you with a smooth and comfortable car rental experience!<br/><br/>\n\n            Best regards,<br/>\n            The Rental Cars Service Team\n        </div>\n\n        <!-- Button -->\n        <div style="text-align:center;">\n            <a href="https://rentalcar.smartyuppies.com"\n               class="buttonCls" style="display:inline-block;\n                                        background-color:#0073b1;\n                                        color:white;\n                                        padding:10px 20px;\n                                        border-radius:5px;\n                                        text-decoration:none;\n                                        font-size:14px;\n                                        cursor:pointer;\n                                        margin-top: 10%">\nWebsite\n            </a>\n        </div>\n    </div>\n</body>\n</html>\n
faa93467-2f2c-4b85-b071-730f02e19c00	CAR RENTAL SERVICE - Car Booking Reservation Alerted	<!DOCTYPE html>\n<html lang="en" style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0px;padding: 0px;">\n<head>\n    <meta charset="UTF-8">\n    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n    <title>Rental Cars</title>\n</head>\n<body style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0px;padding: 0px;">    \n    <div class="job-card" style="position:relative;\n        height:500px;\n        width:300px;\n        left:10%;\n        top:10%;\n        background-color: #000d6b;\n        box-shadow: 0 4px 8px rgba(0,0,0,0.1);    \n        border-radius: 8px;\n        text-align:justify;\n        margin:20px;\n        padding:20px;">\n        \n        <div class="headerMessage" style="position:relative;\n                                          height:10px;\n                                          width:80%;\n                                          margin-left:35px;    \n                                          color:white;\n                                          font-weight:bold;\n                                          margin-top:50px;">\n            Welcome to Rental Cars Service\n        </div>\n\n        <div class="messagecls" style="position: relative;\n                                        height: 240px;\n                                        width: 80%;\n                                        margin-left:35px;\n                                        font-size: 14px;\n                                        color: orange;\n                                        overflow:hidden;\n                                        margin-top:50px;\n                                        ">\n            Hi ${name},<br/>\n            <b>Your car has been successfully alerted!</b><br/>\n            <strong>Car Number:</strong> ${car_no}<br/>\n            <strong>From:</strong> ${fromDate}<br/>\n            <strong>To:</strong> ${toDate}<br/>\n            Thank you for choosing our rental service. We are preparing your vehicle for your upcoming trip.\n        </div>\n\n        <button class="buttonCls" style="position:relative\n        ;\n       \n                                           height:35px;\n                                           width:50%;\n                                           margin-left:35px;  \n                                           background-color: #0073b1;    \n                                           border: none;    \n                                           border-radius: 5px;\n                                           cursor: pointer;">\n            <a href="https://rentalcar.smartyuppies.com" style="color: white; text-decoration :none;">Website</a>\n        </button>\n    </div>\n</body>\n</\nhtml>
05faaeb6-4356-4eb1-b140-9f4f85301ae8	CAR RENTAL SERVICE - Car Rental Feedback Information	<!DOCTYPE html>\n<html lang="en" style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0;padding: 0;">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n  <title>Thank You for Your Feedback</title>\n</head>\n<body style="height:100%;width:100%;font-family: Arial, sans-serif;margin: 0;padding: 0;background-color: #f2f2f2;">\n  \n  <div class="job-card" style="position:relative;\n    height:450px;\n    width:300px;\n    left:10%;\n    top:10%;\n    background-color: #000d6b;\n    box-shadow: 0 4px 8px rgba(0,0,0,0.1);    \n    border-radius: 8px;\n    margin:20px;\n    padding:20px;\n    text-align:justify;\n    ">\n    \n    <!-- Header Message -->\n    <div class="headerMessage" style="position:relative;\n                                      height:10px;\n                                      width:80%;\n                                          \n                                      color:white;\n                                      font-weight:bold;\n                                      margin-top:50px;\n    ">Thank You for Your Feedback, ${name}!</div>\n    \n    <!-- Body Message -->\n    <div class="messagecls" style="position: relative;\n                                    height: 170px;\n                                    width: 80%;\n                                    margin-left:35px;\n                                    padding-bottom:75px;\n                                    margin-bottom:50px;\n                                    font-size: 14px;\n                                    color: orange;\n                                    text-wrap: balance;\n                                    overflow:hidden;\n                                    margin-top:50px;\n                                    ">\n      <b>We truly appreciate your feedback.</b> It helps us continue to improve our services to better meet your needs. If you have any further thoughts or suggestions, feel free to reach out to us.\n      <br/><br/>\n      Thank you again for your input, and we look forward to serving you in the future.\n    </div>\n    \n    <!-- Button -->\n    <button class="buttonCls" style="position:relative;\n                                     height:35px;\n                                     width:50%;\n                                     margin-left:35px;  \n                                     background-color: #0073b1;    \n                                     border: none;    \n                                     border-radius: 5px;\n                                     cursor: pointer;\n                                     \n                                     ">\n      <a href="https://rentalcar.smartyuppies.com" style="color: white; text-decoration: none;">Visit Website</a>\n    </button>\n  </div>\n</body>\n</html>
\.


--
-- Data for Name: admin_rental_cars_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_rental_cars_details (id, brand, car_name, car_no, is_ac, img_url, category, no_of_seat, is_gps, transmission_type, fuel_type, extra_travel_km_per_price, price_per_day, branch) FROM stdin;
cf19aadf-5d0d-40b8-83c8-08f5f2945589	adsf	af	2100	Yes	cf19aadf-5d0d-40b8-83c8-08f5f2945589_titleIcon.png	Hatchback	5	Yes	Automatic	Diesel	11	1000	Chennai
d3fb84a9-d63c-4398-b3c8-4611bb00b147	asdf	ae	as3	No	d3fb84a9-d63c-4398-b3c8-4611bb00b147_RentARide.png	Hatchback	5	Yes	Automatic	Diesel	11	2000	Chennai
ab66f87d-891c-4166-ad4c-7cdfd5a050ae	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: admin_rental_cars_upload; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_rental_cars_upload (id, file_path, file_name, file_type, convert_into_png_status) FROM stdin;
d3fb84a9-d63c-4398-b3c8-4611bb00b147	C:/Users/Lenovo/Desktop/uploads/	d3fb84a9-d63c-4398-b3c8-4611bb00b147_RentARide.png	image/png	true
bb56874b-d90a-4a79-bb2b-36d3f04c9e0b	C:/Users/Lenovo/Desktop/uploads/	bb56874b-d90a-4a79-bb2b-36d3f04c9e0b_nissan-offer.png	image/png	true
daeaba55-3c83-42af-a027-4d9086f07383	C:/Users/Lenovo/Desktop/uploads/	daeaba55-3c83-42af-a027-4d9086f07383_offer-toyota.png	image/png	true
102f7460-456a-4583-9bce-9ebdd648f7ae	C:/Users/Lenovo/Desktop/uploads/	102f7460-456a-4583-9bce-9ebdd648f7ae_tesla.png	image/jpeg	true
dc612b8f-1b64-44eb-8976-022cbca3857e	C:/Users/Lenovo/Desktop/uploads/	dc612b8f-1b64-44eb-8976-022cbca3857e_tesla-removebg-preview.png	image/png	true
cf19aadf-5d0d-40b8-83c8-08f5f2945589	C:/Users/Lenovo/Desktop/uploads/	cf19aadf-5d0d-40b8-83c8-08f5f2945589_titleIcon.png	image/jpeg	true
ab66f87d-891c-4166-ad4c-7cdfd5a050ae	C:/Users/dhasa/OneDrive/Desktop/uploads/	ab66f87d-891c-4166-ad4c-7cdfd5a050ae_QR Payment Smart Yuppies.jpg	image/jpeg	false
70de9806-4a81-4010-9521-332a99e32f8d	C:/Users/Lenovo/Desktop/uploads/	70de9806-4a81-4010-9521-332a99e32f8d_Screenshot (9).png	image/png	true
5d8b8c44-fd92-4e8b-a840-520eba315829	C:/Users/Lenovo/Desktop/uploads/	5d8b8c44-fd92-4e8b-a840-520eba315829_Screenshot (1).png	image/png	true
9f2be207-3d2c-49c5-8ac6-af66ca4d38ec	C:/Users/Lenovo/Desktop/uploads/	9f2be207-3d2c-49c5-8ac6-af66ca4d38ec_Screenshot (2).png	image/png	true
da790632-5b20-4ba5-9e99-d1eb02b75432	C:/Users/Lenovo/Desktop/uploads/	da790632-5b20-4ba5-9e99-d1eb02b75432_Screenshot (3).png	image/png	true
c1c952bd-e76c-4904-88c2-789bd5236310	C:/Users/Lenovo/Desktop/uploads/	c1c952bd-e76c-4904-88c2-789bd5236310_loginBgCar.png	image/jpeg	true
02592eb7-d040-4a23-b2ce-1286f7c7d4f5	C:/Users/Lenovo/Desktop/uploads/	02592eb7-d040-4a23-b2ce-1286f7c7d4f5_loginBgCar.png	image/jpeg	true
017ac9b7-41ce-4017-ab06-4f01d535c401	C:/Users/Lenovo/Desktop/uploads/	017ac9b7-41ce-4017-ab06-4f01d535c401_loginBgCar.png	image/jpeg	true
8b80e4d7-369e-46ff-afe4-933eea53e1e0	C:/Users/Lenovo/Desktop/uploads/	8b80e4d7-369e-46ff-afe4-933eea53e1e0_loginBgCar.png	image/jpeg	true
\.


--
-- Data for Name: admin_software_user_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_software_user_details (user_id, password, email_id, mobile_no, role_name, branch) FROM stdin;
dhasa	123	dhasa@gmail.com	1234567889	exexutive	Trichy
asfd	1234	asdf	asdf	exexutive	Chennai
admin	123	rajesh@smartyuppies.com	9090909090	Super Admin	Chennai
\.


--
-- Data for Name: admin_user_rights; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_user_rights (id, role_name, rights_object) FROM stdin;
64a3a800-fabb-4146-8f89-0172997a7fe5	exexutive	{"Dashboard":"","Customers Booking":"","Customers Profile":"","User":{"User Creation":"","User Rights":""}}
558f2ec2-365f-4a29-8e99-5331186dcfa9	Admin2	{"Dashboard":"","Customers Booking":"","Customers Profile":"","User":{"User Creation":""},"Payment Rule":{"Multi-Day Booking":""}}
a97171d9-d823-4a80-9fce-6184cb7db0b0	Admin	{"Dashboard":"","Customers Booking":"","Customers Profile":"","User":{"User Creation":"","User Rights":""},"Cars Info":"","Default Properties":"","Payment Rule":{"Holiday Booking":"","Multi-Day Booking":""},"Message Template":{"Email Template":"","Whatsapp Template":""}}
692784b7-93bb-45c2-b5a1-786c5eeb8dcf	Super Admin	{"Dashboard":"","Customers Booking":"","Customers Profile":"","User":{"User Creation":"","User Rights":""},"Cars Info":"","Default Properties":"","Payment Rule":{"Price Plans":"","Holiday Booking":"","Multi-Day Booking":""},"Message Template":{"Email Template":"","Whatsapp Template":""},"Feedback":""}
\.


--
-- Data for Name: admin_view_holiday_car_booking_payment_rule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_view_holiday_car_booking_payment_rule (id, holiday_date, car_rent_amount_additional_percentage) FROM stdin;
d0f55fde-d8aa-4bc0-b487-9949d34b2d54	2024-09-13 16:41:00	12
958876b7-44bb-42fa-8f7f-7a74e2713a2c	2024-09-28 05:30:00	22
26f1d8c9-6c48-4aa6-af74-761f140419ef	2024-09-20 05:30:00	22
45ef54c3-6004-491e-a057-a6e86623127a	2024-10-05 05:30:00	10
\.


--
-- Data for Name: admin_view_multiple_day_car_booking_payment_rule; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_view_multiple_day_car_booking_payment_rule (id, no_of_days, car_rent_amount_additional_percentage, adjust_type, limit_km) FROM stdin;
a79b5336-bb0a-454d-bb4d-a5ab3e4e8aba	3	20	Decrease	\N
0a5afdca-7bbf-486d-96d1-d04e3802d76f	3	3	Increase	\N
\.


--
-- Data for Name: admin_view_price_plan_rule_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_view_price_plan_rule_details (id, limit_km, car_rent_amount_additional_percentage) FROM stdin;
8f1c0640-4261-4058-8a21-937131cc051d	320	20
0d2dcf4a-d0b0-4fd2-85a7-844a830c91dd	140	10
\.


--
-- Data for Name: admin_whatsapp_template; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_whatsapp_template (id, whatsapp_subject, url, reference_key) FROM stdin;
7483d322-8d2e-4421-95cd-aad03bb56a93	CAR RENTAL SERVICE - Car Rental Price Information		<br/>Customer Name: {{name}}\n<br/>Customer Mobile Number: {{mobileNo}}\n<br/>Category: {{category}}\n<br/>Brand: {{brand}}\n<br/>Car Name: {{carName}}\n<br/>Car Number: {{carNo}}\n<br/>Number of Seats: {{noOfSeats}}\n<br/>Fuel Type: {{fuelType}}\n<br/>Transmission Type: {{transmissionType}}\n<br/>Charges Type: {{chargesType}}\n<br/>Charges Type Based Amount: {{chargesTypeBasedAmount}}\n<br/>Number of Leave Day Charges: {{noOfLeaveDayCharges}}\n<br/>Security Deposit Charges: {{securityDepositCharges}}\n<br/>Deliverycharges :{{devliveryOrPickupCharges}}\n<br/>Plan Based Payable Charges: {{planBasedPayableCharges}}\n<br/>Base Fare: {{baseFare}}\n<br/>Pickup Date: {{pickupDate}}\n<br/>Return Date: {{returnDate}}\n<br/>Base Fare: {{baseFare}}\n
87f8e01b-272b-4611-8870-2c690ab6c715	CAR RENTAL SERVICE - Car Rental Feedback Information		Customer Name: {{name}}<br/>Customer Mobile Number: {{mobileNo}}
20793ceb-db45-42ce-8b98-bc9341a56e91	CAR RENTAL SERVICE - Hope your travels were amazing! Lets catch up soon 		Customer Name: {{name}}<br/>Customer Mobile Number: {{mobileNo}}
20c0ba1e-c5ef-4fb9-a040-5b4c6bd8dbac	CAR RENTAL SERVICE - Car Reservation Confirmation 		<br/>Customer Name: {{name}}\n<br/>Customer Mobile Number: {{mobileNo}}\n<br/>Pickup Date: {{pickupDate}}\n<br/>Return Date: {{returnDate}}\n<br/>Total totalPayable: {{totalPayable}}
f0525f3a-7be6-4767-9463-1b3fa415181a	CAR RENTAL SERVICE - Profile Update		Customer Name: {{name}}<br/>Customer Mobile Number: {{mobileNo}}
8c29a3b6-2bfd-44c7-9b17-51b31507f382	CAR RENTAL SERVICE - Password Update Notification		Customer Name: {{name}}<br/>Customer Mobile Number: {{mobileNo}}
e630dff7-eaf5-4dbc-abb0-03de9837e350	CAR RENTAL SERVICE - Car Booking Reservation Alerted		<br/>Customer Name: {{name}}\n<br/>Customer Mobile Number: {{mobileNo}}\n<br/>Pickup Date: {{pickupDate}}\n<br/>Return Date: {{returnDate}}\n<br/>Total totalPayable: {{totalPayable}}
\.


--
-- Data for Name: cars; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cars (brand, model, year, email_id, mobile_no, password) FROM stdin;
BMW	X7	2010	\N	\N	\N
BMW	X5	2008	\N	\N	\N
\.


--
-- Data for Name: customer_booking_documents_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_booking_documents_details (id, customer_name, mobile_no, email_id, document_type, docuent_number, name_on_document, file_path, file_name, file_type, document_number) FROM stdin;
c8591ff7-fdec-427d-921a-c8e27b5b8535	K. Naveen	9090909090	kpnaveen1312@gmail.com	Aadhar Card	\N	Aadhar Card	C:/Users/Lenovo/Desktop/uploads/	c8591ff7-fdec-427d-921a-c8e27b5b8535_118-proforma-Naivedhyam_Kannan_Iyengar.pdf	application/pdf	asdf
57e95e89-bc80-438e-8e11-d967fc037568	K. Naveen	9090909090	kpnaveen1312@gmail.com	Driving License	\N	Driving License	C:/Users/Lenovo/Desktop/uploads/	57e95e89-bc80-438e-8e11-d967fc037568_tesla-removebg-preview.png	image/png	DSA
6ceb0952-b264-46f1-8f93-7767ad81dfe8	K. Naveen	9090909090	kpnaveen1312@gmail.com	Aadhar Card	\N	Aadhar Card	C:/Users/Lenovo/Desktop/uploads/	6ceb0952-b264-46f1-8f93-7767ad81dfe8_toyota-offer-2.png	image/png	asdfasdf
\.


--
-- Data for Name: customer_car_rent_booking_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_car_rent_booking_details (id, created_date, customer_name, mobile_no, email_id, car_no, car_name, pick_up_date, return_date, pick_up_type, approve_status, car_img_name, address, extra_info, duration, free_km, plan_based_payable_charges, base_fare, delivery_or_pickup_charges, secuirty_deposite_charges, no_of_leave_day_charges, charges_type, charges_type_based_amount, total_payable) FROM stdin;
265c05dd-662d-4db6-a2b9-1a6ea11883c2	2024-10-05 08:42:00	Rajesh	8667310426	rajesh@smartyuppies.com	2100	af	2024-10-05 04:30:00	2024-10-06 04:30:00	delivery	New Booking	cf19aadf-5d0d-40b8-83c8-08f5f2945589_titleIcon.png	\N	\N	24Hrs	320	1200	1000	1000	1500	100	\N	0	4800
\.


--
-- Data for Name: customer_cars_info_list_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_cars_info_list_type (id, branch, brand, car_name, car_no, category, extra_travel_km_per_price, fuel_type, img_url, no_of_free_km_per_given_date, no_of_seat, is_ac, price_based_on_date, transmission_type, car_available_status) FROM stdin;
\.


--
-- Data for Name: customer_cars_rent_price_details_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_cars_rent_price_details_type (id, car_rent_charges, delivery_charges, total_payable, charges_type, charges_type_based_amount, no_of_leave_day_charges, plan_based_payable_charges, secuirty_deposite_charges, base_fare, pick_up_date_char, return_date_char) FROM stdin;
\.


--
-- Data for Name: customer_feedback; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_feedback (id, person_name, person_contact, person_description) FROM stdin;
\.


--
-- Data for Name: customer_feedback_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_feedback_details (id, person_name, person_contact, person_description, created_date) FROM stdin;
5fae5eee-2a53-4222-8036-72a64017d141	adf	asdf	asdfasdfasdfasdfsa	2024-09-26
\.


--
-- Data for Name: customer_registration_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_registration_details (id, name, mobile_no, alternative_mobile_no, age, email_id, sign_status) FROM stdin;
6a0ad81b-337e-4139-868f-c4ecd8f9df82	Rajesh	8667310426	9696969696	28	rajesh@smartyuppies.com	active
\.


--
-- Data for Name: profile_image_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profile_image_details (id, file_path, file_name, file_type, profile_type) FROM stdin;
Rajesh	C:/Users/Lenovo/Desktop/uploads/	Rajesh_Cryptocurrency - Bootstrap 5 Admin Template — Mozilla Firefox 25-09-2024 11_59_09.png	image/png	\N
asfd	C:/Users/Lenovo/Desktop/uploads/	asfd_Screenshot (4).png	image/png	\N
admin	C:/Users/Lenovo/Desktop/uploads/	admin_king_R.jpg	image/jpeg	\N
1c966750-d54c-4e90-b764-bdbe0817073e	C:/Users/Lenovo/Desktop/uploads/	1c966750-d54c-4e90-b764-bdbe0817073e_loginBgCar.jpg	image/jpeg	Customer
\.


--
-- Name: admin_cars_category_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_cars_category_seq', 1, true);


--
-- Name: cars_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cars_seq', 1, false);


--
-- Data for Name: BLOBS; Type: BLOBS; Schema: -; Owner: -
--

BEGIN;

SELECT pg_catalog.lo_open('33256', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020203c6865616465723e0a20202020202020203c696d67207372633d226c6f676f2e706e672220616c743d224e61756b7269204c6f676f2220636c6173733d226c6f676f223e0a20202020202020203c68313e5365697a6520616c6c206a6f62206f70706f7274756e6974696573206f662074686973207765656b213c2f68313e0a202020203c2f6865616465723e0a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68323e4261636b656e6420456e67696e6565723c2f68323e0a2020202020202020202020203c703e5468697320697320612073696d706c69666965642076657273696f6e20746861742077696c6c206769766520796f752061206c61796f75742073696d696c617220746f207768617427732073686f776e20696e2074686520696d6167652e20596f75206d69676874206e65656420746f2061646a75737420746865207374796c65732028636f6c6f72732c20666f6e74732c206574632e2920746f206d61746368207468652073706563696669632064657369676e206f6620746865206a6f62206c697374696e6720736974652e20416c736f2c207265706c61636520226c6f676f2e706e67222077697468207468652061637475616c207061746820746f20796f7572206c6f676f2066696c652e20496620796f75206e65656420746f20616464206d6f72652066756e6374696f6e616c697479206f72207370656369666963207374796c696e672064657461696c732c206665656c206672656520746f2061736b213c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e4e6f7420496e74657265737465643c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020203c666f6f7465723e0a20202020202020203c627574746f6e20636c6173733d22766965772d616c6c223e5669657720416c6c205265636f6d6d656e646174696f6e733c2f627574746f6e3e0a202020203c2f666f6f7465723e0a3c2f626f64793e0a3c2f68746d6c3e');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33257', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172732052616a6573683c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020203c6865616465723e0a20202020202020203c696d67207372633d226c6f676f2e706e672220616c743d224e61756b7269204c6f676f2220636c6173733d226c6f676f223e0a20202020202020203c68313e5365697a6520616c6c206a6f62206f70706f7274756e6974696573206f662074686973207765656b213c2f68313e0a202020203c2f6865616465723e0a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68323e4261636b656e6420456e67696e6565723c2f68323e0a2020202020202020202020203c703e5468697320697320612073696d706c69666965642076657273696f6e20746861742077696c6c206769766520796f752061206c61796f75742073696d696c617220746f207768617427732073686f776e20696e2074686520696d6167652e20596f75206d69676874206e65656420746f2061646a75737420746865207374796c65732028636f6c6f72732c20666f6e74732c206574632e2920746f206d61746368207468652073706563696669632064657369676e206f6620746865206a6f62206c697374696e6720736974652e20416c736f2c207265706c61636520226c6f676f2e706e67222077697468207468652061637475616c207061746820746f20796f7572206c6f676f2066696c652e20496620796f75206e65656420746f20616464206d6f72652066756e6374696f6e616c697479206f72207370656369666963207374796c696e672064657461696c732c206665656c206672656520746f2061736b213c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e4e6f7420496e74657265737465643c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020203c666f6f7465723e0a20202020202020203c627574746f6e20636c6173733d22766965772d616c6c223e5669657720416c6c205265636f6d6d656e646174696f6e733c2f627574746f6e3e0a202020203c2f666f6f7465723e0a3c2f626f64793e0a3c2f68746d6c3e');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33258', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020203c6865616465723e0a20202020202020203c696d67207372633d226c6f676f2e706e672220616c743d224e61756b7269204c6f676f2220636c6173733d226c6f676f223e0a20202020202020203c68313e5365697a6520616c6c206a6f62206f70706f7274756e6974696573206f662074686973207765656b213c2f68313e0a202020203c2f6865616465723e0a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68323e4261636b656e6420456e67696e6565723c2f68323e0a2020202020202020202020203c703e48692052616a6573682c205468697320697320612073696d706c69666965642076657273696f6e20746861742077696c6c206769766520796f752061206c61796f75742073696d696c617220746f207768617427732073686f776e20696e2074686520696d6167652e20596f75206d69676874206e65656420746f2061646a75737420746865207374796c65732028636f6c6f72732c20666f6e74732c206574632e2920746f206d61746368207468652073706563696669632064657369676e206f6620746865206a6f62206c697374696e6720736974652e20416c736f2c207265706c61636520226c6f676f2e706e67222077697468207468652061637475616c207061746820746f20796f7572206c6f676f2066696c652e20496620796f75206e65656420746f20616464206d6f72652066756e6374696f6e616c697479206f72207370656369666963207374796c696e672064657461696c732c206665656c206672656520746f2061736b213c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e4e6f7420496e74657265737465643c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020203c666f6f7465723e0a20202020202020203c627574746f6e20636c6173733d22766965772d616c6c223e5669657720416c6c205265636f6d6d656e646174696f6e733c2f627574746f6e3e0a202020203c2f666f6f7465723e0a3c2f626f64793e0a3c2f68746d6c3e');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33259', 131072);
SELECT pg_catalog.lowrite(0, '\x3c696672616d653e0a3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020203c6865616465723e0a20202020202020203c696d67207372633d226c6f676f2e706e672220616c743d224e61756b7269204c6f676f2220636c6173733d226c6f676f223e0a20202020202020203c68313e5365697a6520616c6c206a6f62206f70706f7274756e6974696573206f662074686973207765656b213c2f68313e0a202020203c2f6865616465723e0a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68323e4261636b656e6420456e67696e6565723c2f68323e0a2020202020202020202020203c703e48692052616a6573682c205468697320697320612073696d706c69666965642076657273696f6e20746861742077696c6c206769766520796f752061206c61796f75742073696d696c617220746f207768617427732073686f776e20696e2074686520696d6167652e20596f75206d69676874206e65656420746f2061646a75737420746865207374796c65732028636f6c6f72732c20666f6e74732c206574632e2920746f206d61746368207468652073706563696669632064657369676e206f6620746865206a6f62206c697374696e6720736974652e20416c736f2c207265706c61636520226c6f676f2e706e67222077697468207468652061637475616c207061746820746f20796f7572206c6f676f2066696c652e20496620796f75206e65656420746f20616464206d6f72652066756e6374696f6e616c697479206f72207370656369666963207374796c696e672064657461696c732c206665656c206672656520746f2061736b213c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e4e6f7420496e74657265737465643c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020203c666f6f7465723e0a20202020202020203c627574746f6e20636c6173733d22766965772d616c6c223e5669657720416c6c205265636f6d6d656e646174696f6e733c2f627574746f6e3e0a202020203c2f666f6f7465723e0a3c2f626f64793e0a3c2f68746d6c3e0a3c2f696672616d653e');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33260', 131072);
SELECT pg_catalog.lowrite(0, '\x3c696672616d65206865696768743d22313030222077696474683d22313030223e0a3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020203c6865616465723e0a20202020202020203c696d67207372633d226c6f676f2e706e672220616c743d224e61756b7269204c6f676f2220636c6173733d226c6f676f223e0a20202020202020203c68313e5365697a6520616c6c206a6f62206f70706f7274756e6974696573206f662074686973207765656b213c2f68313e0a202020203c2f6865616465723e0a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68323e4261636b656e6420456e67696e6565723c2f68323e0a2020202020202020202020203c703e48692052616a6573682c205468697320697320612073696d706c69666965642076657273696f6e20746861742077696c6c206769766520796f752061206c61796f75742073696d696c617220746f207768617427732073686f776e20696e2074686520696d6167652e20596f75206d69676874206e65656420746f2061646a75737420746865207374796c65732028636f6c6f72732c20666f6e74732c206574632e2920746f206d61746368207468652073706563696669632064657369676e206f6620746865206a6f62206c697374696e6720736974652e20416c736f2c207265706c61636520226c6f676f2e706e67222077697468207468652061637475616c207061746820746f20796f7572206c6f676f2066696c652e20496620796f75206e65656420746f20616464206d6f72652066756e6374696f6e616c697479206f72207370656369666963207374796c696e672064657461696c732c206665656c206672656520746f2061736b213c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e4e6f7420496e74657265737465643c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020203c666f6f7465723e0a20202020202020203c627574746f6e20636c6173733d22766965772d616c6c223e5669657720416c6c205265636f6d6d656e646174696f6e733c2f627574746f6e3e0a202020203c2f666f6f7465723e0a3c2f626f64793e0a3c2f68746d6c3e0a3c2f696672616d653e');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33261', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a707b0a09666f6e742d73697a653a313470780a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020200a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68343e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a2020202020202020202020203c703e4869204e61766565656e2c3c62722f3e0a202020202020202020202020095375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c3c62722f3e0a202020202020202020202020094e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e0a202020202020202020202020202020200a2020202020202020202020203c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e576562736974653c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020200a3c2f626f64793e0a3c2f68746d6c3e');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33262', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a707b0a09666f6e742d73697a653a313470783b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a202020200a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020200a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68343e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a2020202020202020202020203c703e4869204e61766565656e2c3c62722f3e0a202020202020202020202020095375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a202020202020202020202020094e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e0a202020202020202020202020202020200a2020202020202020202020203c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e576562736974653c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020200a3c2f626f64793e0a3c2f68746d6c3e');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33263', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a707b0a09666f6e742d73697a653a313470783b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a202020200a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020200a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68343e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a2020202020202020202020203c703e4869204e61766565656e2c3c62722f3e0a202020202020202020202020095375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a202020202020202020202020094e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e0a202020202020202020202020202020200a2020202020202020202020203c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e576562736974653c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020200a3c2f626f64793e0a3c2f68746d6c3e');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33264', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a686561646572207b0a20202020746578742d616c69676e3a2063656e7465723b0a202020206d617267696e2d626f74746f6d3a20323070783b0a7d0a0a2e6c6f676f207b0a2020202077696474683a20353070783b202f2a2041646a7573742073697a65206173206e6565646564202a2f0a7d0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a707b0a09666f6e742d73697a653a313470783b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a202020200a7d0a0a666f6f746572207b0a20202020746578742d616c69676e3a2063656e7465723b0a7d0a3c2f7374796c653e0a3c626f64793e0a202020200a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68343e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a2020202020202020202020203c703e4869204e61766565656e2c3c62722f3e0a202020202020202020202020095375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a202020202020202020202020094e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e0a202020202020202020202020202020200a2020202020202020202020203c2f703e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e576562736974653c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020200a3c2f626f64793e0a3c2f68746d6c3e0a20202020');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33265', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b090a096d617267696e2d627574746f6d203a203130253b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a6469767b0a09666f6e742d73697a653a313470783b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a7d0a0a3c2f7374796c653e0a3c626f64793e0a202020200a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68343e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a2020202020202020202020203c6469763e4869204e61766565656e2c3c62722f3e0a202020202020202020202020095375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a202020202020202020202020094e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e202020202020202020202020202020200a2020202020202020202020203c2f6469763e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e576562736974653c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020200a3c2f626f64793e0a3c2f68746d6c3e0a20202020');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33266', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a09626f6479207b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a20303b0a2020202070616464696e673a20323070783b0a7d0a0a0a2e6a6f622d73656374696f6e207b0a20202020646973706c61793a20666c65783b0a202020206a7573746966792d636f6e74656e743a2073706163652d61726f756e643b0a202020206d617267696e3a20323070783b0a7d0a0a2e6a6f622d63617264207b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b0a2020202070616464696e673a20323070783b0a2020202077696474683a2033303070783b202f2a2041646a757374207769647468206173206e6565646564202a2f0a20202020626f726465722d7261646975733a203870783b0a7d0a0a2e6a6f622d636172642068322c202e6a6f622d636172642070207b0a202020206d617267696e3a203130707820303b0a7d0a0a2e726174696e67207b0a202020206261636b67726f756e642d636f6c6f723a20676f6c643b0a2020202070616464696e673a20337078203670783b0a20202020626f726465722d7261646975733a203570783b0a20202020666f6e742d7765696768743a20626f6c643b0a7d0a0a627574746f6e207b090a096d617267696e2d627574746f6d203a203130253b0a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a2020202070616464696e673a203130707820323070783b0a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a2020202077696474683a20313030253b0a7d0a0a2e766965772d616c6c207b0a20202020646973706c61793a20626c6f636b3b0a202020206d617267696e3a2032307078206175746f3b0a2020202077696474683a203530253b0a7d0a6469767b0a09666f6e742d73697a653a313470783b0a20202020776f72642d77726170203a20627265616b2d776f72643b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a7d0a0a3c2f7374796c653e0a3c626f64793e0a202020200a202020203c73656374696f6e20636c6173733d226a6f622d73656374696f6e223e0a20202020202020203c64697620636c6173733d226a6f622d63617264223e0a2020202020202020202020203c68343e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a2020202020202020202020203c6469763e4869204e61766565656e2c3c62722f3e0a202020202020202020202020095375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a202020202020202020202020094e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e202020202020202020202020202020200a2020202020202020202020203c2f6469763e0a2020202020202020202020200a2020202020202020202020203c627574746f6e3e576562736974653c2f627574746f6e3e0a20202020202020203c2f6469763e0a202020202020200a202020203c2f73656374696f6e3e0a202020200a3c2f626f64793e0a3c2f68746d6c3e0a20202020');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33267', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a68746d6c2c626f6479207b0a096865696768743a313030253b0a2020202077696474683a313030253b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a203070783b0a2020202070616464696e673a203070783b0a7d0a0a0a2e6a6f622d63617264207b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3730253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b202020200a20202020626f726465722d7261646975733a203870783b0a20202020746578742d616c69676e3a6a7573746966793b0a7d0a2e6865616465724d6573736167657b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3130253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a7d0a627574746f6e207b090a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3130253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a202020200a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a202020200a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a202020200a7d0a0a2e6d657373616765636c737b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3730253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a09666f6e742d73697a653a313470783b0a20202020776f72642d77726170203a20627265616b2d776f72643b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a7d0a0a3c2f7374796c653e0a3c626f64793e202020200a20203c64697620636c6173733d226a6f622d63617264223e0a202020203c683420636c6173733d226865616465724d657373616765223e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a202020203c64697620636c6173733d226d657373616765636c73223e4869204e61766565656e2c3c62722f3e0a2020202020205375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a2020202020204e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e202020202020202020202020202020200a202020203c2f6469763e0a0a202020203c627574746f6e3e576562736974653c2f627574746f6e3e0a20203c2f6469763e0a3c2f626f64793e0a3c2f68746d6c3e0a20202020');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33268', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a68746d6c2c626f6479207b0a096865696768743a313030253b0a2020202077696474683a313030253b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a203070783b0a2020202070616464696e673a203070783b0a7d0a0a0a2e6a6f622d63617264207b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3730253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b202020200a20202020626f726465722d7261646975733a203870783b0a20202020746578742d616c69676e3a6a7573746966793b0a7d0a2e6865616465724d6573736167657b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3130253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a7d0a627574746f6e207b090a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3130253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a202020200a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a202020200a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a202020200a7d0a0a2e6d657373616765636c737b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3530253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a09666f6e742d73697a653a313470783b0a20202020776f72642d77726170203a20627265616b2d776f72643b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a7d0a0a3c2f7374796c653e0a3c626f64793e202020200a20203c64697620636c6173733d226a6f622d63617264223e0a202020203c683420636c6173733d226865616465724d657373616765223e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a202020203c64697620636c6173733d226d657373616765636c73223e4869204e61766565656e2c3c62722f3e0a2020202020205375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a2020202020204e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e202020202020202020202020202020200a202020203c2f6469763e0a0a202020203c627574746f6e3e576562736974653c2f627574746f6e3e0a20203c2f6469763e0a3c2f626f64793e0a3c2f68746d6c3e0a20202020');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33269', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a68746d6c2c626f6479207b0a096865696768743a313030253b0a2020202077696474683a313030253b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a203070783b0a2020202070616464696e673a203070783b0a7d0a0a0a2e6a6f622d63617264207b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3730253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b202020200a20202020626f726465722d7261646975733a203870783b0a20202020746578742d616c69676e3a6a7573746966793b0a7d0a2e6865616465724d6573736167657b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3130253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a7d0a2e627574746f6e436c73207b090a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3130253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a202020200a202020206261636b67726f756e642d636f6c6f723a20233030373362313b0a20202020636f6c6f723a2077686974653b0a20202020626f726465723a206e6f6e653b0a202020200a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b0a202020200a7d0a0a2e6d657373616765636c737b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3530253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a09666f6e742d73697a653a313470783b0a20202020776f72642d77726170203a20627265616b2d776f72643b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a7d0a0a3c2f7374796c653e0a3c626f64793e202020200a20203c64697620636c6173733d226a6f622d63617264223e0a202020203c683420636c6173733d226865616465724d657373616765223e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a202020203c64697620636c6173733d226d657373616765636c73223e4869204e61766565656e2c3c62722f3e0a2020202020205375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a2020202020204e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e202020202020202020202020202020200a202020203c2f6469763e0a0a202020203c627574746f6e20636c6173733d22627574746f6e436c73223e576562736974653c2f627574746f6e3e0a20203c2f6469763e0a3c2f626f64793e0a3c2f68746d6c3e0a20202020');
SELECT pg_catalog.lo_close(0);

SELECT pg_catalog.lo_open('33319', 131072);
SELECT pg_catalog.lowrite(0, '\x3c21444f43545950452068746d6c3e0a3c68746d6c206c616e673d22656e223e0a3c686561643e0a093c6d65746120636861727365743d225554462d38223e0a093c6d657461206e616d653d2276696577706f72742220636f6e74656e743d2277696474683d6465766963652d77696474682c20696e697469616c2d7363616c653d312e30223e0a093c7469746c653e52656e74616c20436172733c2f7469746c653e0a3c2f686561643e0a3c7374796c653e0a68746d6c2c626f6479207b0a096865696768743a313030253b0a2020202077696474683a313030253b0a20202020666f6e742d66616d696c793a20417269616c2c2073616e732d73657269663b0a202020206261636b67726f756e642d636f6c6f723a20236634663466343b0a202020206d617267696e3a203070783b0a2020202070616464696e673a203070783b0a7d0a0a0a2e6a6f622d63617264207b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3730253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a202020206261636b67726f756e642d636f6c6f723a2077686974653b0a20202020626f782d736861646f773a20302034707820387078207267626128302c302c302c302e31293b202020200a20202020626f726465722d7261646975733a203870783b0a20202020746578742d616c69676e3a6a7573746966793b0a7d0a2e6865616465724d6573736167657b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3130253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a7d0a2e627574746f6e436c73207b090a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3130253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b202020200a202020206261636b67726f756e642d636f6c6f723a20233030373362313b202020200a20202020626f726465723a206e6f6e653b202020200a20202020626f726465722d7261646975733a203570783b0a20202020637572736f723a20706f696e7465723b202020200a7d0a0a2e627574746f6e436c7320617b0a636f6c6f723a2077686974653b0a746578742d6465636f726174696f6e203a6e6f6e653b0a7d0a2e6d657373616765636c737b0a09706f736974696f6e3a72656c61746976653b0a202020206865696768743a3530253b0a2020202077696474683a3830253b0a202020206c6566743a3130253b0a20202020746f703a3130253b0a09666f6e742d73697a653a313470783b0a20202020776f72642d77726170203a20627265616b2d776f72643b0a202020206f766572666c6f772d777261703a20627265616b2d776f72643b0a7d0a0a3c2f7374796c653e0a3c626f64793e202020200a20203c64697620636c6173733d226a6f622d63617264223e0a202020203c683420636c6173733d226865616465724d657373616765223e57656c636f6d6520746f2052656e74616c204361727320536572766963653c2f68343e0a202020203c64697620636c6173733d226d657373616765636c73223e486920247b4e616d657d3c62722f3e0a2020202020205375636365737366756c6c7920526567697374726174696f6e20796f7572204163636f756e742c0a2020202020204e6f7720796f757220686176652070726f766973696f6e20746f20626f6f6b206361727320666f7220796f75722074727570202e202020202020202020202020202020200a202020203c2f6469763e0a0a202020203c627574746f6e20636c6173733d22627574746f6e436c73223e3c6120687265663d2268747470733a2f2f72656e74616c6361722e736d617274797570706965732e636f6d223e576562736974653c2f613e3c2f627574746f6e3e0a20203c2f6469763e0a3c2f626f64793e0a3c2f68746d6c3e0a20202020');
SELECT pg_catalog.lo_close(0);

COMMIT;

--
-- Name: admin_default_properties admin_default_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_default_properties
    ADD CONSTRAINT admin_default_properties_pkey PRIMARY KEY (id);


--
-- Name: admin_email_template admin_email_template_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_email_template
    ADD CONSTRAINT admin_email_template_pkey PRIMARY KEY (id);


--
-- Name: admin_rental_cars_details admin_rental_cars_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_rental_cars_details
    ADD CONSTRAINT admin_rental_cars_details_pkey PRIMARY KEY (id);


--
-- Name: admin_rental_cars_upload admin_rental_cars_upload_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_rental_cars_upload
    ADD CONSTRAINT admin_rental_cars_upload_pkey PRIMARY KEY (id);


--
-- Name: admin_software_user_details admin_software_user_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_software_user_details
    ADD CONSTRAINT admin_software_user_details_pkey PRIMARY KEY (user_id);


--
-- Name: admin_user_rights admin_user_rights_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_user_rights
    ADD CONSTRAINT admin_user_rights_pkey PRIMARY KEY (id);


--
-- Name: admin_view_holiday_car_booking_payment_rule admin_view_holiday_car_booking_payment_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_view_holiday_car_booking_payment_rule
    ADD CONSTRAINT admin_view_holiday_car_booking_payment_rule_pkey PRIMARY KEY (id);


--
-- Name: admin_view_multiple_day_car_booking_payment_rule admin_view_multiple_day_car_booking_payment_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_view_multiple_day_car_booking_payment_rule
    ADD CONSTRAINT admin_view_multiple_day_car_booking_payment_rule_pkey PRIMARY KEY (id);


--
-- Name: admin_view_price_plan_rule_details admin_view_price_plan_rule_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_view_price_plan_rule_details
    ADD CONSTRAINT admin_view_price_plan_rule_details_pkey PRIMARY KEY (id);


--
-- Name: admin_whatsapp_template admin_whatsapp_template_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_whatsapp_template
    ADD CONSTRAINT admin_whatsapp_template_pkey PRIMARY KEY (id);


--
-- Name: customer_booking_documents_details customer_booking_documents_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_booking_documents_details
    ADD CONSTRAINT customer_booking_documents_details_pkey PRIMARY KEY (id);


--
-- Name: customer_car_rent_booking_details customer_car_rent_booking_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_car_rent_booking_details
    ADD CONSTRAINT customer_car_rent_booking_details_pkey PRIMARY KEY (id);


--
-- Name: customer_cars_info_list_type customer_cars_info_list_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_cars_info_list_type
    ADD CONSTRAINT customer_cars_info_list_type_pkey PRIMARY KEY (id);


--
-- Name: customer_cars_rent_price_details_type customer_cars_rent_price_details_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_cars_rent_price_details_type
    ADD CONSTRAINT customer_cars_rent_price_details_type_pkey PRIMARY KEY (id);


--
-- Name: customer_feedback_details customer_feedback_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_feedback_details
    ADD CONSTRAINT customer_feedback_details_pkey PRIMARY KEY (id);


--
-- Name: customer_feedback customer_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_feedback
    ADD CONSTRAINT customer_feedback_pkey PRIMARY KEY (id);


--
-- Name: profile_image_details profile_image_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_image_details
    ADD CONSTRAINT profile_image_details_pkey PRIMARY KEY (id);


--
-- Name: customer_feedback_details before_insert_set_created_date; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_insert_set_created_date BEFORE INSERT ON public.customer_feedback_details FOR EACH ROW EXECUTE FUNCTION public.set_created_date();


--
-- PostgreSQL database dump complete
--

