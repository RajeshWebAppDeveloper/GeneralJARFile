



create database fsm;

--DROP TABLE user_details;
CREATE TABLE user_details(
	id UUID PRIMARY KEY
	,user_id VARCHAR   
	,user_name VARCHAR
	,password VARCHAR
	,email_id VARCHAR
	,mobile_no VARCHAR
	,role_name VARCHAR
	,branch VARCHAR	
);
--INSERT INTO user_details VALUES (gen_random_uuid(),'001','admin','123','admin@gmail.com','9090909090','admin','Chennai');

--DROP TABLE profile_image_details;

CREATE TABLE profile_image_details(
	id UUID   PRIMARY KEY
	,file_path VARCHAR		
	,file_name VARCHAR
	,file_type VARCHAR
	,profile_type VARCHAR
);

--DROP TABLE product_category;
CREATE TABLE product_category(
	id UUID   PRIMARY KEY
	,category_id VARCHAR
	,category VARCHAR		
	,created_date TIMESTAMP
	,created_by VARCHAR
);

--DROP SEQUENCE IF EXISTS category_sequence;
CREATE SEQUENCE category_sequence START 1 INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_category_sequence() RETURNS TEXT AS $$
	DECLARE
	    seq_value INT;
	BEGIN	    
	    seq_value := nextval('category_sequence');	    
	    RETURN 'CTY_' || seq_value;
	END;
$$ LANGUAGE plpgsql;

--DROP TABLE product_details;
CREATE TABLE product_details(
	id UUID   PRIMARY KEY
	,product_id VARCHAR
	,product_name VARCHAR		
	,product_category VARCHAR		
	,unit_price VARCHAR
	,tax VARCHAR
	,created_date TIMESTAMP
	,created_by VARCHAR
);


--DROP SEQUENCE IF EXISTS product_sequence;
CREATE SEQUENCE product_sequence START 1 INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_product_sequence() RETURNS TEXT AS $$
	DECLARE
	    seq_value INT;
	BEGIN	    
	    seq_value := nextval('product_sequence');	    
	    RETURN 'PDT_' || seq_value;
	END;
$$ LANGUAGE plpgsql;


--DROP TABLE dar_details;
CREATE TABLE dar_details(
	id UUID   PRIMARY KEY
	,dar_no VARCHAR
	,dar_process_date TIMESTAMP		
	,planned_activity TEXT		
	,delivery_place_name_and_address TEXT
	,state_cum_area VARCHAR
	,client_name VARCHAR
	,client_mobile_no VARCHAR
	,about_the_client TEXT
	,product_details TEXT
	,from_location TEXT
	,to_location TEXT
	,total_expenses VARCHAR
	,status_to_visit VARCHAR
	,created_date TIMESTAMP
	,created_by VARCHAR
);


--DROP SEQUENCE IF EXISTS dar_sequence;
CREATE SEQUENCE dar_sequence START 1 INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_dar_sequence() RETURNS TEXT AS $$
	DECLARE
	    seq_value INT;
	BEGIN	    
	    seq_value := nextval('dar_sequence');	    
	    RETURN 'DAR_' || seq_value;
	END;
$$ LANGUAGE plpgsql;




--DROP TABLE dar_expenses_details;
CREATE TABLE dar_expenses_details(
	id UUID   PRIMARY KEY
	,reference_id VARCHAR
	,expenses_description VARCHAR
	,expenses_amount NUMERIC		
	,image_file_path VARCHAR	
);


--DROP TABLE estimation_details;
CREATE TABLE estimation_details(
	id UUID   PRIMARY KEY
	,est_no VARCHAR
	,customer_name VARCHAR
	,estimation_process_date TIMESTAMP		
	,rep_attd VARCHAR
	,rep_account VARCHAR
	,billing_address TEXT		
	,delivery_address TEXT		
	,customer_city VARCHAR
	,customer_pin_code VARCHAR
	,customer_phone VARCHAR
	,customer_email VARCHAR
	,delivery_city VARCHAR
	,delivery_pin_code VARCHAR
	,warranty VARCHAR
	,pan_and_gst VARCHAR
	,ref VARCHAR
	,remarks TEXT
	,its_have_discount VARCHAR
	,discount_estimate VARCHAR
	,demo_piece_estimate VARCHAR
	,stock_clearance_estimate VARCHAR
	,discount_amount VARCHAR
	,gst VARCHAR
	,delivery_charges VARCHAR
	,total_amount VARCHAR
	,register_status VARCHAR
);

--DROP SEQUENCE IF EXISTS estimation_sequence;
CREATE SEQUENCE estimation_sequence START 1 INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_estimation_sequence() RETURNS TEXT AS $$
	DECLARE
	    seq_value INT;
	BEGIN	    
	    seq_value := nextval('estimation_sequence');	    
	    RETURN 'EST_' || seq_value;
	END;
$$ LANGUAGE plpgsql;



--DROP TABLE estimation_product_details;
CREATE TABLE estimation_product_details(
	id UUID   PRIMARY KEY
	,reference_id VARCHAR
	,product_details VARCHAR
	,product_code VARCHAR
	,qty INT	
	,unit_price INT
	,tax INT
	,total FLOAT	
);


--DROP TABLE order_product_details;
CREATE TABLE order_product_details(
 id                        uuid PRIMARY KEY, 
 e_no 						VARCHAR,
 est_no                     VARCHAR,
 order_no                   VARCHAR,
 so_no                      VARCHAR,
 d_d_no                     VARCHAR,
 customer_name              VARCHAR,
 billing_name               VARCHAR,
 billing_address            TEXT,                                             
 customer_city              VARCHAR,
 customer_pin_code          VARCHAR,
 customer_phone             VARCHAR,
 customer_email             VARCHAR,
 rep_code                   VARCHAR,
 demo_plan                  VARCHAR,
 order_process_date         TIMESTAMP,
 payment_charges            VARCHAR,
 payment_term_date          TIMESTAMP,
 warranty                   VARCHAR,
 pan_and_gst                VARCHAR,
 demo_date                  TIMESTAMP,
 delivery_address           TEXT,                                             
 expected_date              TIMESTAMP,
 ship_mode_name             VARCHAR,
 remarks                    TEXT,                                             
 total_product_amount       VARCHAR,
 gst  VARCHAR,
 delivery_charges           VARCHAR,
 total_amount               VARCHAR,
 less_advance               VARCHAR,
 balance                    VARCHAR,
 register_status            VARCHAR,
 delivery_city              VARCHAR,
 delivery_pin_code          VARCHAR,
 demo_piece_estimate        VARCHAR,
 discount_amount            VARCHAR,
 discount_estimate          VARCHAR,
 its_have_discount          VARCHAR,
 stock_clearance_estimate   VARCHAR
);

--DROP SEQUENCE IF EXISTS order_sequence;
CREATE SEQUENCE order_sequence START 1 INCREMENT 1;

CREATE OR REPLACE FUNCTION generate_order_sequence() RETURNS TEXT AS $$
	DECLARE
	    seq_value INT;
	BEGIN	    
	    seq_value := nextval('order_sequence');	    
	    RETURN 'ORD_' || seq_value;
	END;
$$ LANGUAGE plpgsql;



--DROP TABLE estimation_product_details;
CREATE TABLE estimation_product_details(
	id UUID   PRIMARY KEY
	,reference_id VARCHAR
	,product_type VARCHAR
	,product_details VARCHAR
	,product_code VARCHAR
	,qty INT	
	,unit_price INT
	,tax INT
	,total FLOAT	
);