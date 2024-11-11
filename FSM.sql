

---netsh advfirewall firewall add rule name="TCP Port 2224" dir=in action=allow protocol=TCP localport=22

---nohup java -jar FieldServiceManagement_30_oct_2024.jar > FieldServiceManagement_30_oct_2024.log 2>&1 &


create database fsm;






--DROP SEQUENCE user_id_sequence;
CREATE SEQUENCE user_id_sequence START 1 INCREMENT 1;

--DROP TABLE user_details;
CREATE TABLE user_details (
    id UUID PRIMARY KEY,
    user_id VARCHAR NOT NULL,
    user_name VARCHAR NOT NULL,
    password VARCHAR NOT NULL,
    email_id VARCHAR NOT NULL,
    mobile_no VARCHAR NOT NULL UNIQUE,  
    role_name VARCHAR NOT NULL,
    branch VARCHAR NOT NULL,
    rep_code VARCHAR,
    rep_account VARCHAR,
    user_rights TEXT,
    leader_user_id VARCHAR,
    file_name VARCHAR
);

INSERT INTO user_details (id,user_id, user_name, password, email_id, mobile_no, role_name, branch, rep_code, rep_account, user_rights,leader_user_id,file_name) 
VALUES 
    (gen_random_uuid(),'001', 'admin', '123', 'admin@gmail.com', '9090909090', 'admin', 'Chennai', '-', '-', 'asdfasdf asdfasdf asdfasdf','','{"Dashboard":"","Users":"","Catgory":"","Product":"","DAR":"","Estimation":"","Order":""}');


--DROP FUncTion generate_user_id_sequence();
CREATE OR REPLACE FUNCTION generate_user_id_sequence() RETURNS TEXT AS $$
	DECLARE
	    seq_value INT;
	    generated_id TEXT;
	BEGIN	    
	    seq_value := nextval('user_id_sequence');
	    generated_id := 'USR_' || seq_value;
	    RETURN generated_id;
	END;
$$ LANGUAGE plpgsql;

--SELECT reset_user_id_sequence();
CREATE OR REPLACE FUNCTION reset_user_id_sequence() RETURNS BOOLEAN AS $$
DECLARE
    last_user_id_num INT;
BEGIN    
    SELECT COALESCE(MAX(CAST(SUBSTRING(user_id FROM '^[^0-9]*(\d+)$') AS INTEGER)), 0) 
    INTO last_user_id_num
    FROM user_details
    WHERE user_id IS NOT NULL 
      AND user_id <> ''
      AND user_id ~ '^[^0-9]*(\d+)$'; 

    
    IF last_user_id_num IS NULL THEN        
        RETURN FALSE; 
    END IF;
    PERFORM setval('user_id_sequence', last_user_id_num);
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;





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


--DROP TABLE order_details;
--DROP TABLE IF EXISTS order_details CASCADE;
CREATE TABLE order_details(
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
 stock_clearance_estimate   VARCHAR,
 payment_mode   			VARCHAR
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



--DROP TABLE order_product_details;
CREATE TABLE order_product_details(
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





SELECT * FROM getUserBasedTeamMemberList('USR_2');

--DROP FUNcTION getUserBasedTeamMemberList(VARCHAR);
CREATE OR REPLACE FUNCTION public.getUserBasedTeamMemberList(leaderUserId VARCHAR)
RETURNS VARCHAR
LANGUAGE 'plpgsql'
VOLATILE
PARALLEL UNSAFE
COST 100
AS $BODY$
DECLARE
    result VARCHAR;
BEGIN

    WITH RECURSIVE user_based_team_member_list AS (
        SELECT 
            user_id
        FROM 
            user_details
        WHERE 
            user_id = leaderUserId
        UNION 
        SELECT 
            ud.user_id
        FROM 
            user_details ud 
        INNER JOIN user_based_team_member_list s ON s.user_id = ud.leader_user_id
    )
    SELECT string_agg(user_id::VARCHAR, ',') INTO result
    FROM user_based_team_member_list;

    RETURN result;
END;
$BODY$;


--SELECT * FROM getFSMUserIdsBasedDarDetailsList('001,USR_2,USR_3');

CREATE OR REPLACE FUNCTION public.getFSMUserIdsBasedDarDetailsList(userIds VARCHAR)
																	RETURNS SETOF dar_details
																	LANGUAGE 'plpgsql'
																	VOLATILE
																	PARALLEL UNSAFE
																	COST 100
																	ROWS 1000
																	AS $BODY$
	BEGIN
    	


	    	RETURN QUERY
		    SELECT 
		        m1.*
		    FROM
		        dar_details m1		    
		    WHERE
		    	lower(m1.created_by) ILIKE ANY(string_to_array(lower(userIds) || '%', ','))
		     ORDER BY
        		m1.created_date DESC;
		        
	END;

$BODY$;

--SELECT * FROM getFSMUserIdsBasedEstimationDetailsList('001,USR_2,USR_3');

CREATE OR REPLACE FUNCTION public.getFSMUserIdsBasedEstimationDetailsList(userIds VARCHAR)
																	RETURNS SETOF estimation_details
																	LANGUAGE 'plpgsql'
																	VOLATILE
																	PARALLEL UNSAFE
																	COST 100
																	ROWS 1000
																	AS $BODY$
	BEGIN
    	


	    	RETURN QUERY
		    SELECT 
		        m1.*
		    FROM
		        estimation_details m1		    
		    WHERE
		    	lower(m1.created_by) ILIKE ANY(string_to_array(lower(userIds) || '%', ','))
		     ORDER BY
        		m1.created_date DESC;
		        
	END;

$BODY$;


--SELECT * FROM getFSMUserIdsBasedOrderDetailsList('001');
DROP FUNCTION getFSMUserIdsBasedOrderDetailsList(VARCHAR);

CREATE OR REPLACE FUNCTION public.getFSMUserIdsBasedOrderDetailsList(userIds VARCHAR)
																	RETURNS SETOF order_details
																	LANGUAGE 'plpgsql'
																	VOLATILE
																	PARALLEL UNSAFE
																	COST 100
																	ROWS 1000
																	AS $BODY$
	BEGIN
    	


	    	RETURN QUERY
		    SELECT 
		        m1.*
		    FROM
		        order_details m1		    
		    WHERE
		    	lower(m1.created_by) ILIKE ANY(string_to_array(lower(userIds) || '%', ','))
		    ORDER BY
        		m1.created_date DESC;
	END;

$BODY$;


/************************Filter user details*********************************/
SELECT * FROM getFilterUsersDetailsList('001','','','','','','','');


CREATE OR REPLACE FUNCTION public.getFilterUsersDetailsList(userId VARCHAR,
														    userName VARCHAR,    
														    mobileNo VARCHAR,  
														    roleName VARCHAR,
														    branchName VARCHAR,
														    repCode VARCHAR,
														    repAccount VARCHAR,    
														    leaderUserId VARCHAR)
																RETURNS SETOF user_details
																LANGUAGE 'plpgsql'
																VOLATILE
																PARALLEL UNSAFE
																COST 100
																ROWS 1000
																AS $BODY$
	BEGIN

	    	RETURN QUERY
		    SELECT 
		        m1.*
		    FROM
		        user_details m1		    
		    WHERE
		    	m1.user_id IS NOT NULL
		    	AND lower(m1.user_id) ILIKE ANY(string_to_array(lower(userId) || '%', ','))
		        AND lower(m1.user_name) ILIKE ANY(string_to_array(lower(userName) || '%', ','))
		        AND lower(m1.mobile_no) ILIKE ANY(string_to_array(lower(mobileNo) || '%', ','))
		        AND lower(m1.role_name) ILIKE ANY(string_to_array(lower(roleName) || '%', ','))
		        AND lower(m1.branch) ILIKE ANY(string_to_array(lower(branchName) || '%', ','))
		        AND lower(m1.rep_code) ILIKE ANY(string_to_array(lower(repCode) || '%', ','))
		        AND lower(m1.rep_account) ILIKE ANY(string_to_array(lower(repAccount) || '%', ','))
		        AND lower(m1.leader_user_id) ILIKE ANY(string_to_array(lower(leaderUserId) || '%', ','));		        
		
	END;

$BODY$;

/*****************************************Category Filter**********************************************************/

SELECT * FROM getFilterCategoryDetailsList('','','2024-10-09T00:00','2024-10-09T23:40','');

CREATE OR REPLACE FUNCTION public.getFilterCategoryDetailsList(
															    categoryId VARCHAR,
															    categoryName VARCHAR,    
															    createdFromDate TIMESTAMP,
															    createdToDate TIMESTAMP,
															    createdBy VARCHAR
															)
															RETURNS SETOF product_category
															LANGUAGE 'plpgsql'
															VOLATILE
															PARALLEL UNSAFE
															COST 100
															ROWS 1000
															AS $BODY$
	BEGIN
	    RETURN QUERY
	    SELECT 
	        m1.*
	    FROM
	        product_category m1
	    WHERE     
	        (categoryId IS NULL OR lower(m1.category_id) ILIKE lower(categoryId) || '%')            
	        AND (categoryName IS NULL OR lower(m1.category) ILIKE lower(categoryName) || '%')        
	        AND (createdFromDate IS NULL OR createdToDate IS NULL OR m1.created_date BETWEEN createdFromDate AND createdToDate)
	        AND (createdBy IS NULL OR lower(m1.created_by) ILIKE lower(createdBy) || '%')
	    ORDER BY
        		m1.created_date DESC;
	END;
$BODY$;


/*****************************************Product Filter**********************************************************/

SELECT * FROM getFilterProductDetailsList('','','','2024-10-09T00:00','2024-10-09T23:40','');

CREATE OR REPLACE FUNCTION public.getFilterProductDetailsList(
															    productId VARCHAR,
															    productName VARCHAR,    
															    productCategory VARCHAR,
															    createdFromDate TIMESTAMP,
															    createdToDate TIMESTAMP,
															    createdBy VARCHAR
															)
															RETURNS SETOF product_details
															LANGUAGE 'plpgsql'
															VOLATILE
															PARALLEL UNSAFE
															COST 100
															ROWS 1000
															AS $BODY$
	BEGIN
	    RETURN QUERY
	    SELECT 
	        m1.*
	    FROM
	        product_details m1
	    WHERE
	    	(productId IS NULL OR lower(m1.product_id) ILIKE lower(productId) || '%')                 	        
	        AND (productName IS NULL OR lower(m1.product_name) ILIKE lower(productName) || '%')      
	        AND (productCategory IS NULL OR lower(m1.product_category) ILIKE lower(productCategory) || '%')        
	        AND (createdFromDate IS NULL OR createdToDate IS NULL OR m1.created_date BETWEEN createdFromDate AND createdToDate)
	        AND (createdBy IS NULL OR lower(m1.created_by) ILIKE lower(createdBy) || '%')
	    ORDER BY
        		m1.created_date DESC;
	END;
$BODY$;

/*****************************************Dar Filter**********************************************************/
SELECT * FROM getFilterDarDetailsList('',null,null,'asdf','','','2024-10-20T00:00','2024-10-20T23:40','');


SELECT * FROM getFilterDarDetailsList('',null,null,'','','',null,null,'');


CREATE OR REPLACE FUNCTION public.getFilterDarDetailsList(
														    darNo VARCHAR,
														    darPerformFromDate TIMESTAMP,    
														    darPerformToDate TIMESTAMP,    
														    clientName VARCHAR,
														    clientMobileNo VARCHAR,
														    statusToVisit VARCHAR,
														    createdFromDate TIMESTAMP,
														    createdToDate TIMESTAMP,
														    createdBy VARCHAR
														)
														RETURNS SETOF dar_details
														LANGUAGE 'plpgsql'
														VOLATILE
														PARALLEL UNSAFE
														COST 100
														ROWS 1000
														AS $BODY$
		BEGIN
		    RETURN QUERY
		    SELECT 
		        m1.*
		    FROM
		        dar_details m1
		    WHERE
		        (darNo IS NULL OR lower(m1.dar_no) ILIKE lower(darNo) || '%')                 	        
		        AND (darPerformFromDate IS NULL OR darPerformToDate IS NULL OR m1.dar_process_date BETWEEN darPerformFromDate AND darPerformToDate)
		        AND (clientName IS NULL OR lower(m1.client_name) ILIKE lower(clientName) || '%') 
		        AND (clientMobileNo IS NULL OR lower(m1.client_mobile_no) ILIKE lower(clientMobileNo) || '%')
		        AND (statusToVisit IS NULL OR lower(m1.status_to_visit) ILIKE lower(statusToVisit) || '%')      	             
		        AND (createdFromDate IS NULL OR createdToDate IS NULL OR m1.created_date BETWEEN createdFromDate AND createdToDate)
		        AND (createdBy IS NULL OR lower(m1.created_by) ILIKE lower(createdBy) || '%')
		    ORDER BY
		        m1.created_date DESC;
		END;
$BODY$;

/*
getFilterDarDetailsList(
    $P{darNo}, 
    $P{darPerformFromDate}, 
    $P{darPerformToDate}, 
    $P{clientName}, 
    $P{clientMobileNo}, 
    $P{statusToVisit}, 
    $P{createdFromDate}, 
    $P{createdToDate}, 
    $P{createdBy}
)
*/

/*****************************************EStimation Filter**********************************************************/
SELECT * FROM getFilterEstimationDetailsList('','',null,null,'','','','','Estimation Enquiry',null,null,'');

CREATE OR REPLACE FUNCTION public.getFilterEstimationDetailsList(
															    estNo VARCHAR,
															    customerName VARCHAR,
															    estimationPerformFromDate TIMESTAMP,    
															    estimationPerformToDate TIMESTAMP,    
															    repAttD VARCHAR,
															    repAccount VARCHAR,
															    mobileNo VARCHAR,
															    itsHaveDiscount VARCHAR,
															    estimationStatus VARCHAR,
															    createdFromDate TIMESTAMP,
															    createdToDate TIMESTAMP,
															    createdBy VARCHAR
															)
															RETURNS SETOF estimation_details
															LANGUAGE 'plpgsql'
															VOLATILE
															PARALLEL UNSAFE
															COST 100
															ROWS 1000
															AS $BODY$
	BEGIN
	    RETURN QUERY
	    SELECT 
	        m1.*
	    FROM
	        estimation_details m1
	    WHERE
	    	(estNo IS NULL OR lower(m1.est_no) ILIKE lower(estNo) || '%')  
	    	AND (customerName IS NULL OR lower(m1.customer_name) ILIKE lower(customerName) || '%') 
	    	AND (estimationPerformFromDate IS NULL OR estimationPerformToDate IS NULL OR m1.estimation_process_date BETWEEN estimationPerformFromDate AND estimationPerformToDate)	        
	    	AND (repAttD IS NULL OR lower(m1.rep_attd) ILIKE lower(repAttD) || '%') 
	    	AND (repAccount IS NULL OR lower(m1.rep_account) ILIKE lower(repAccount) || '%') 	    	
	        AND (mobileNo IS NULL OR lower(m1.customer_phone) ILIKE lower(mobileNo) || '%')
	        AND (itsHaveDiscount IS NULL OR lower(m1.its_have_discount) ILIKE lower(itsHaveDiscount) || '%')      	             
	        AND (estimationStatus IS NULL OR lower(m1.register_status) ILIKE lower(estimationStatus) || '%')      	             
	        AND (createdFromDate IS NULL OR createdToDate IS NULL OR m1.created_date BETWEEN createdFromDate AND createdToDate)
	        AND (createdBy IS NULL OR lower(m1.created_by) ILIKE lower(createdBy) || '%')
	    ORDER BY
        		m1.created_date DESC;
	END;
$BODY$;



/*****************************************Order Filter**********************************************************/
--DROP FUNCTION IF EXISTS public.getFilterOrderDetailsList(VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,TIMESTAMP,TIMESTAMP,VARCHAR,VARCHAR,TIMESTAMP,TIMESTAMP,VARCHAR,VARCHAR,VARCHAR,TIMESTAMP,TIMESTAMP,VARCHAR);

--SELECT * FROM getFilterOrderDetailsList('','','','','','',null,null,'','','',null,null,'','','2024-10-21T00:00','2024-10-21T23:40','');																																																				

CREATE OR REPLACE FUNCTION public.getFilterOrderDetailsList(
														    eNo VARCHAR,
														    estNo VARCHAR,
														    orderNo VARCHAR,
														    soNo VARCHAR,
														    ddNo VARCHAR,
														    customerName VARCHAR,
														    orderPerformFromDate TIMESTAMP,    
														    orderPerformToDate TIMESTAMP,    
														    repAttD VARCHAR,                                                                                                                
														    mobileNo VARCHAR,
														    demoPlan VARCHAR,
														    demoFromDate TIMESTAMP,
														    demoToDate TIMESTAMP,
														    itsHaveDiscount VARCHAR,
														    orderStatus VARCHAR,
														    createdFromDate TIMESTAMP,
														    createdToDate TIMESTAMP,
														    createdBy VARCHAR
														)
														RETURNS SETOF order_details
														LANGUAGE 'plpgsql'
														VOLATILE
														PARALLEL UNSAFE
														COST 100
														ROWS 1000
														AS $BODY$
				BEGIN
				    RETURN QUERY
				    SELECT 
				        m1.*
				    FROM
				        order_details m1
				    WHERE
				        (eNo IS NULL OR lower(m1.e_no) ILIKE lower(eNo) || '%') 
				        AND (estNo IS NULL OR lower(m1.est_no) ILIKE lower(estNo) || '%') 
				        AND (orderNo IS NULL OR lower(m1.order_no) ILIKE lower(orderNo) || '%')  
				        AND (soNo IS NULL OR lower(m1.so_no) ILIKE lower(soNo) || '%')  
				        AND (ddNo IS NULL OR lower(m1.d_d_no) ILIKE lower(ddNo) || '%')  
				        AND (customerName IS NULL OR lower(m1.customer_name) ILIKE lower(customerName) || '%')        
				        AND (orderPerformFromDate IS NULL OR orderPerformToDate IS NULL 
				             OR m1.order_process_date BETWEEN orderPerformFromDate AND orderPerformToDate)                           
				        AND (repAttD IS NULL OR lower(m1.rep_code) ILIKE lower(repAttD) || '%')                                 
				        AND (mobileNo IS NULL OR lower(m1.customer_phone) ILIKE lower(mobileNo) || '%')
				        AND (demoPlan IS NULL OR lower(m1.demo_plan) ILIKE lower(demoPlan) || '%')        
				        AND (demoFromDate IS NULL OR demoToDate IS NULL OR m1.demo_date BETWEEN demoFromDate AND demoToDate)            
				        AND (itsHaveDiscount IS NULL OR lower(m1.its_have_discount) ILIKE lower(itsHaveDiscount) || '%')                     
				        AND (orderStatus IS NULL OR lower(m1.register_status) ILIKE lower(orderStatus) || '%')                              
				        AND (createdFromDate IS NULL OR createdToDate IS NULL OR m1.created_date BETWEEN createdFromDate AND createdToDate)        
				        AND (createdBy IS NULL OR lower(m1.created_by) ILIKE lower(createdBy) || '%')
				    ORDER BY
				        m1.created_date DESC;
				END;
$BODY$;

 --SELECT string_agg(m1.user_id||'-'||m1.user_name, ',') FROM user_details  m1;



 --Drop table default_properties;
CREATE TABLE default_properties(
	id UUID   PRIMARY KEY
	,property_name VARCHAR		
	,property_value VARCHAR		
);

Drop Table IF EXISTS payment_details CASCADE;
CREATE TABLE payment_details(
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
 stock_clearance_estimate   VARCHAR,
 payment_mode   			VARCHAR
);


--SELECT * FROM getFSMUserIdsBasedPaymentDetailsList('001');
DROP FUNCTION IF EXISTS getFSMUserIdsBasedPaymentDetailsList(VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION public.getFSMUserIdsBasedPaymentDetailsList(userIds VARCHAR)
																	RETURNS SETOF payment_details
																	LANGUAGE 'plpgsql'
																	VOLATILE
																	PARALLEL UNSAFE
																	COST 100
																	ROWS 1000
																	AS $BODY$
	BEGIN
    	


	    	RETURN QUERY
		    SELECT 
		        m1.*
		    FROM
		        payment_details m1		    
		    WHERE
		    	lower(m1.created_by) ILIKE ANY(string_to_array(lower(userIds) || '%', ','))
		    ORDER BY
        		m1.created_date DESC;
	END;

$BODY$;


--DROP FUNCTION IF EXISTS public.getFilterPaymentDetailsList(VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,TIMESTAMP,TIMESTAMP,VARCHAR,VARCHAR,TIMESTAMP,TIMESTAMP,VARCHAR,VARCHAR,VARCHAR,TIMESTAMP,TIMESTAMP,VARCHAR) CASCADE;

--SELECT * FROM getFilterPaymentDetailsList('','','','','','',null,null,'','','',null,null,'','','2024-10-21T00:00','2024-10-21T23:40','');																																																				

CREATE OR REPLACE FUNCTION public.getFilterPaymentsDetailsList(
														    eNo VARCHAR,
														    estNo VARCHAR,
														    orderNo VARCHAR,
														    soNo VARCHAR,
														    ddNo VARCHAR,
														    customerName VARCHAR,
														    orderPerformFromDate TIMESTAMP,    
														    orderPerformToDate TIMESTAMP,    
														    repAttD VARCHAR,                                                                                                                
														    mobileNo VARCHAR,
														    demoPlan VARCHAR,
														    demoFromDate TIMESTAMP,
														    demoToDate TIMESTAMP,
														    itsHaveDiscount VARCHAR,
														    orderStatus VARCHAR,
														    createdFromDate TIMESTAMP,
														    createdToDate TIMESTAMP,
														    createdBy VARCHAR
														)
														RETURNS SETOF payment_details
														LANGUAGE 'plpgsql'
														VOLATILE
														PARALLEL UNSAFE
														COST 100
														ROWS 1000
														AS $BODY$
				BEGIN
				    RETURN QUERY
				    SELECT 
				        m1.*
				    FROM
				        payment_details m1
				    WHERE
				        (eNo IS NULL OR lower(m1.e_no) ILIKE lower(eNo) || '%') 
				        AND (estNo IS NULL OR lower(m1.est_no) ILIKE lower(estNo) || '%') 
				        AND (orderNo IS NULL OR lower(m1.order_no) ILIKE lower(orderNo) || '%')  
				        AND (soNo IS NULL OR lower(m1.so_no) ILIKE lower(soNo) || '%')  
				        AND (ddNo IS NULL OR lower(m1.d_d_no) ILIKE lower(ddNo) || '%')  
				        AND (customerName IS NULL OR lower(m1.customer_name) ILIKE lower(customerName) || '%')        
				        AND (orderPerformFromDate IS NULL OR orderPerformToDate IS NULL 
				             OR m1.order_process_date BETWEEN orderPerformFromDate AND orderPerformToDate)                           
				        AND (repAttD IS NULL OR lower(m1.rep_code) ILIKE lower(repAttD) || '%')                                 
				        AND (mobileNo IS NULL OR lower(m1.customer_phone) ILIKE lower(mobileNo) || '%')
				        AND (demoPlan IS NULL OR lower(m1.demo_plan) ILIKE lower(demoPlan) || '%')        
				        AND (demoFromDate IS NULL OR demoToDate IS NULL OR m1.demo_date BETWEEN demoFromDate AND demoToDate)            
				        AND (itsHaveDiscount IS NULL OR lower(m1.its_have_discount) ILIKE lower(itsHaveDiscount) || '%')                     
				        AND (orderStatus IS NULL OR lower(m1.register_status) ILIKE lower(orderStatus) || '%')                              
				        AND (createdFromDate IS NULL OR createdToDate IS NULL OR m1.created_date BETWEEN createdFromDate AND createdToDate)        
				        AND (createdBy IS NULL OR lower(m1.created_by) ILIKE lower(createdBy) || '%')
				    ORDER BY
				        m1.created_date DESC;
				END;
$BODY$;
