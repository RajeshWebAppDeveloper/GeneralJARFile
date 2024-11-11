--
-- PostgreSQL database dump
--

-- Dumped from database version 17.0
-- Dumped by pg_dump version 17.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: generate_category_sequence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_category_sequence() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    seq_value INT;
BEGIN    
    seq_value := nextval('category_sequence');    
    RETURN 'CTY_' || seq_value;
END;
$$;


ALTER FUNCTION public.generate_category_sequence() OWNER TO postgres;

--
-- Name: generate_dar_sequence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_dar_sequence() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    seq_value INT;
BEGIN    
    seq_value := nextval('dar_sequence');    
    RETURN 'DAR_' || seq_value;
END;
$$;


ALTER FUNCTION public.generate_dar_sequence() OWNER TO postgres;

--
-- Name: generate_estimation_sequence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_estimation_sequence() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    seq_value INT;
BEGIN    
    seq_value := nextval('estimation_sequence');    
    RETURN 'EST_' || seq_value;
END;
$$;


ALTER FUNCTION public.generate_estimation_sequence() OWNER TO postgres;

--
-- Name: generate_order_sequence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_order_sequence() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    seq_value INT;
BEGIN    
    seq_value := nextval('order_sequence');    
    RETURN 'ORD_' || seq_value;
END;
$$;


ALTER FUNCTION public.generate_order_sequence() OWNER TO postgres;

--
-- Name: generate_product_sequence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_product_sequence() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    seq_value INT;
BEGIN    
    seq_value := nextval('product_sequence');    
    RETURN 'PDT_' || seq_value;
END;
$$;


ALTER FUNCTION public.generate_product_sequence() OWNER TO postgres;

--
-- Name: generate_user_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_user_id() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    seq_value INT;
    generated_id TEXT;
BEGIN    
    seq_value := nextval('user_id_sequence');
    generated_id := 'USR_' || seq_value;
    RETURN generated_id;
END;
$$;


ALTER FUNCTION public.generate_user_id() OWNER TO postgres;

--
-- Name: generate_user_id_sequence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_user_id_sequence() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    seq_value INT;
    generated_id TEXT;
BEGIN    
    seq_value := nextval('user_id_sequence');
    generated_id := 'USR_' || seq_value;
    RETURN generated_id;
END;
$$;


ALTER FUNCTION public.generate_user_id_sequence() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dar_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dar_details (
    id uuid NOT NULL,
    dar_no character varying(255),
    dar_process_date timestamp without time zone,
    planned_activity text,
    delivery_place_name_and_address text,
    state_cum_area character varying(255),
    client_name character varying(255),
    client_mobile_no character varying(255),
    about_the_client text,
    product_details text,
    from_location text,
    to_location text,
    total_expenses character varying(255),
    status_to_visit character varying(255),
    created_date timestamp without time zone,
    created_by character varying(255)
);


ALTER TABLE public.dar_details OWNER TO postgres;

--
-- Name: getfsmuseridsbaseddardetailslist(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getfsmuseridsbaseddardetailslist(userids character varying) RETURNS SETOF public.dar_details
    LANGUAGE plpgsql
    AS $$
BEGIN
    


    RETURN QUERY
    SELECT 
        m1.*
    FROM
        dar_details m1    
    WHERE
    lower(m1.created_by) ILIKE ANY(string_to_array(lower(userIds) || '%', ','));
        
END;

$$;


ALTER FUNCTION public.getfsmuseridsbaseddardetailslist(userids character varying) OWNER TO postgres;

--
-- Name: estimation_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estimation_details (
    id uuid NOT NULL,
    est_no character varying(255),
    customer_name character varying(255),
    estimation_process_date timestamp without time zone,
    rep_attd character varying(255),
    rep_account character varying(255),
    billing_address text,
    delivery_address text,
    customer_city character varying(255),
    customer_pin_code character varying(255),
    customer_phone character varying(255),
    customer_email character varying(255),
    delivery_city character varying(255),
    delivery_pin_code character varying(255),
    warranty character varying(255),
    pan_and_gst character varying(255),
    ref character varying(255),
    remarks text,
    its_have_discount character varying(255),
    discount_estimate character varying(255),
    demo_piece_estimate character varying(255),
    stock_clearance_estimate character varying(255),
    discount_amount character varying(255),
    gst character varying(255),
    delivery_charges character varying(255),
    total_amount character varying(255),
    register_status character varying(255),
    created_by character varying(255),
    created_date timestamp(6) without time zone,
    total_product character varying(255)
);


ALTER TABLE public.estimation_details OWNER TO postgres;

--
-- Name: getfsmuseridsbasedestimationdetailslist(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getfsmuseridsbasedestimationdetailslist(userids character varying) RETURNS SETOF public.estimation_details
    LANGUAGE plpgsql
    AS $$
BEGIN
    


    RETURN QUERY
    SELECT 
        m1.*
    FROM
        estimation_details m1    
    WHERE
    lower(m1.created_by) ILIKE ANY(string_to_array(lower(userIds) || '%', ','));
        
END;

$$;


ALTER FUNCTION public.getfsmuseridsbasedestimationdetailslist(userids character varying) OWNER TO postgres;

--
-- Name: order_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_details (
    id uuid NOT NULL,
    e_no character varying(255),
    est_no character varying(255),
    order_no character varying(255),
    so_no character varying(255),
    d_d_no character varying(255),
    customer_name character varying(255),
    billing_name character varying(255),
    billing_address text,
    customer_city character varying(255),
    customer_pin_code character varying(255),
    customer_phone character varying(255),
    customer_email character varying(255),
    rep_code character varying(255),
    demo_plan character varying(255),
    order_process_date timestamp without time zone,
    payment_charges character varying(255),
    payment_term_date timestamp without time zone,
    warranty character varying(255),
    pan_and_gst character varying(255),
    demo_date timestamp without time zone,
    delivery_address text,
    expected_date timestamp without time zone,
    ship_mode_name character varying(255),
    remarks text,
    total_product_amount character varying(255),
    gst character varying(255),
    delivery_charges character varying(255),
    total_amount character varying(255),
    less_advance character varying(255),
    balance character varying(255),
    register_status character varying(255),
    delivery_city character varying(255),
    delivery_pin_code character varying(255),
    demo_piece_estimate character varying(255),
    discount_amount character varying(255),
    discount_estimate character varying(255),
    its_have_discount character varying(255),
    stock_clearance_estimate character varying(255),
    created_by character varying(255),
    created_date timestamp(6) without time zone
);


ALTER TABLE public.order_details OWNER TO postgres;

--
-- Name: getfsmuseridsbasedorderdetailslist(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getfsmuseridsbasedorderdetailslist(userids character varying) RETURNS SETOF public.order_details
    LANGUAGE plpgsql
    AS $$
BEGIN
    


    RETURN QUERY
    SELECT 
        m1.*
    FROM
        order_details m1    
    WHERE
    lower(m1.created_by) ILIKE ANY(string_to_array(lower(userIds) || '%', ','));
        
END;

$$;


ALTER FUNCTION public.getfsmuseridsbasedorderdetailslist(userids character varying) OWNER TO postgres;

--
-- Name: getuserbasedteammemberlist(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getuserbasedteammemberlist(leaderuserid character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    result VARCHAR;
BEGIN
    -- Use recursive query to fetch the list of user IDs
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
    -- Concatenate all user IDs into a single string with commas
    SELECT string_agg(user_id::VARCHAR, ',') INTO result
    FROM user_based_team_member_list;

    -- Return the result
    RETURN result;
END;
$$;


ALTER FUNCTION public.getuserbasedteammemberlist(leaderuserid character varying) OWNER TO postgres;

--
-- Name: reset_user_id_sequence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reset_user_id_sequence() RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.reset_user_id_sequence() OWNER TO postgres;

--
-- Name: category_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.category_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.category_sequence OWNER TO postgres;

--
-- Name: dar_expenses_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dar_expenses_details (
    id uuid NOT NULL,
    reference_id character varying(255),
    expenses_description character varying(255),
    expenses_amount character varying(255),
    image_file_path character varying(255)
);


ALTER TABLE public.dar_expenses_details OWNER TO postgres;

--
-- Name: dar_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dar_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dar_sequence OWNER TO postgres;

--
-- Name: estimation_product_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estimation_product_details (
    id uuid NOT NULL,
    reference_id character varying(255),
    product_details character varying(255),
    product_code character varying(255),
    qty integer,
    unit_price integer,
    tax integer,
    total double precision
);


ALTER TABLE public.estimation_product_details OWNER TO postgres;

--
-- Name: estimation_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estimation_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estimation_sequence OWNER TO postgres;

--
-- Name: order_product_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_product_details (
    id uuid NOT NULL,
    reference_id character varying(255),
    product_type character varying(255),
    product_details character varying(255),
    product_code character varying(255),
    qty integer,
    unit_price integer,
    tax integer,
    total double precision
);


ALTER TABLE public.order_product_details OWNER TO postgres;

--
-- Name: order_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_sequence OWNER TO postgres;

--
-- Name: product_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_category (
    id uuid NOT NULL,
    category_id character varying(255),
    category character varying(255),
    created_date timestamp without time zone,
    created_by character varying(255)
);


ALTER TABLE public.product_category OWNER TO postgres;

--
-- Name: product_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_details (
    id uuid NOT NULL,
    product_id character varying(255),
    product_name character varying(255),
    product_category character varying(255),
    unit_price character varying(255),
    tax character varying(255),
    created_date timestamp without time zone,
    created_by character varying(255)
);


ALTER TABLE public.product_details OWNER TO postgres;

--
-- Name: product_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_sequence OWNER TO postgres;

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
-- Name: user_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_details (
    id uuid NOT NULL,
    user_id character varying(255) NOT NULL,
    user_name character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    email_id character varying(255) NOT NULL,
    mobile_no character varying(255) NOT NULL,
    role_name character varying(255) NOT NULL,
    branch character varying(255) NOT NULL,
    rep_code character varying(255),
    rep_account character varying(255),
    user_rights text,
    leader_user_id character varying(255),
    file_name character varying(255)
);


ALTER TABLE public.user_details OWNER TO postgres;

--
-- Name: user_id_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_id_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_id_sequence OWNER TO postgres;

--
-- Data for Name: dar_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dar_details (id, dar_no, dar_process_date, planned_activity, delivery_place_name_and_address, state_cum_area, client_name, client_mobile_no, about_the_client, product_details, from_location, to_location, total_expenses, status_to_visit, created_date, created_by) FROM stdin;
91e68726-7d6b-491f-8793-ca4f0e43595c	DAR_1	2024-10-10 05:30:00	asdf	asd	asdf	asdf	asdf	asdf	asd	asdf	asdf	6.00	Demo success	2024-10-20 22:32:15.418	001
\.


--
-- Data for Name: dar_expenses_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dar_expenses_details (id, reference_id, expenses_description, expenses_amount, image_file_path) FROM stdin;
fb11206d-a7d1-4cc2-b7f7-1e0e9b63ae61	91e68726-7d6b-491f-8793-ca4f0e43595c	asdf	2	IMG-20240816-WA0007.jpg
63608b71-829f-4493-bdf4-574d93c4f573	91e68726-7d6b-491f-8793-ca4f0e43595c	asd	2	IMG-20240816-WA0006.jpg
8814bd75-d77c-4df8-94a9-10c6b5c7d120	91e68726-7d6b-491f-8793-ca4f0e43595c	asdf	2	IMG-20240816-WA0008.jpg
\.


--
-- Data for Name: estimation_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.estimation_details (id, est_no, customer_name, estimation_process_date, rep_attd, rep_account, billing_address, delivery_address, customer_city, customer_pin_code, customer_phone, customer_email, delivery_city, delivery_pin_code, warranty, pan_and_gst, ref, remarks, its_have_discount, discount_estimate, demo_piece_estimate, stock_clearance_estimate, discount_amount, gst, delivery_charges, total_amount, register_status, created_by, created_date, total_product) FROM stdin;
070cdf76-58f6-4667-b1ed-4d28c525e8b0	EST_1	Rajesh	2024-11-07 05:30:00		asdf	asdf	asdf	asdf	asdf	asdf	asdf	asdf	asdf	6 Months	asdf	asd	asd	No	34	34	34	34	34	34	34	Cancel Estimation	001	2024-10-22 15:48:07.823	21.00
31a8dabd-79c6-48f2-a33c-db9ae42ac174	EST_10	Shshs	2024-10-23 16:48:00	123	123	Vdbd	Ebehehe	Bdhdu	Dheheh	Ehehe	Dnrhjd	Dhdhe	Ebeheh				Shhs	no						89464	91684.00	Estimation Enquiry	USR_4	2024-10-23 16:49:30	0
af58e766-7fb7-4b4c-80d0-8d6defe967c2	EST_11	Bdhdundmd	2024-10-23 16:56:40	123	123	Gshdjdj		Bdhdhdj	Dhjdjdj	Bdndndnnd								no						799494	800109.00	Estimation Enquiry	USR_4	2024-10-23 16:57:18	0
\.


--
-- Data for Name: estimation_product_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.estimation_product_details (id, reference_id, product_details, product_code, qty, unit_price, tax, total) FROM stdin;
9ea94b91-4467-4183-92a4-18834928adc6	070cdf76-58f6-4667-b1ed-4d28c525e8b0	asdf	asd	2	2	3	7
bac06461-f12d-440e-90fb-412c0e1959a8	070cdf76-58f6-4667-b1ed-4d28c525e8b0	asdf	asdf	2	2	3	7
51d3286a-c645-4c4b-9c33-81c275527172	070cdf76-58f6-4667-b1ed-4d28c525e8b0	asdf	asd	2	2	3	7
e4635575-0228-43eb-a282-dd2086b4577a	\N	Product 2	S456	2	200	10	410
796ac033-90fa-405c-aa11-263cfff845fe	\N	Product 2	S456	2	200	10	410
1d3d899e-a50b-4c42-a1a6-23d5d7d2c296	31a8dabd-79c6-48f2-a33c-db9ae42ac174	Product 2	S456	2	200	10	410
12d83b3a-75ea-4f1a-b168-9879266542bf	\N	Product 2	S456	9	200	10	1810
616d00e8-8d1d-4ecf-950e-bea77dbfe06b	af58e766-7fb7-4b4c-80d0-8d6defe967c2	Product 1	S123	2	100	5	205
ddf8392c-6318-46ee-8230-6b5d181c66a7	af58e766-7fb7-4b4c-80d0-8d6defe967c2	Product 2	S456	2	200	10	410
\.


--
-- Data for Name: order_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_details (id, e_no, est_no, order_no, so_no, d_d_no, customer_name, billing_name, billing_address, customer_city, customer_pin_code, customer_phone, customer_email, rep_code, demo_plan, order_process_date, payment_charges, payment_term_date, warranty, pan_and_gst, demo_date, delivery_address, expected_date, ship_mode_name, remarks, total_product_amount, gst, delivery_charges, total_amount, less_advance, balance, register_status, delivery_city, delivery_pin_code, demo_piece_estimate, discount_amount, discount_estimate, its_have_discount, stock_clearance_estimate, created_by, created_date) FROM stdin;
f0c366ff-964a-47ed-b135-e97bbd9d6191		EST_1	ORD_12			Rajesh		asdf	asdf	asdf	asdf	asdf			2024-10-21 19:18:00.595		\N	6 Months	asdf	\N	asdf	\N		asd	34	34	34	34			Convert To Order	asdf	asdf	34	34	34	No	34	001	2024-10-21 19:18:00.548
\.


--
-- Data for Name: order_product_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_product_details (id, reference_id, product_type, product_details, product_code, qty, unit_price, tax, total) FROM stdin;
\.


--
-- Data for Name: product_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_category (id, category_id, category, created_date, created_by) FROM stdin;
a9da0293-60bd-46a1-ba14-cb7ab79368ea	CTY_1	Category1	2024-10-09 14:19:42.368	admin
dfafbd67-009b-4b6d-88ca-fb15b5c27a27	CTY_2	Category2	2024-10-09 14:19:49.199	admin
\.


--
-- Data for Name: product_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_details (id, product_id, product_name, product_category, unit_price, tax, created_date, created_by) FROM stdin;
5241975d-fd9a-4fab-9c6a-72990b6b1ca9	PDT_1	product1	Category1	10	10	2024-10-09 14:20:03.847	admin
96bd0798-0b90-4f1f-a198-9107f50fb7fd	PDT_2	product	Category2	20	2	2024-10-09 14:20:17.344	admin
\.


--
-- Data for Name: profile_image_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profile_image_details (id, file_path, file_name, file_type, profile_type) FROM stdin;
\.


--
-- Data for Name: user_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_details (id, user_id, user_name, password, email_id, mobile_no, role_name, branch, rep_code, rep_account, user_rights, leader_user_id, file_name) FROM stdin;
e0717635-e7ee-4788-976d-1a0c99e9e5cc	001	Admin	123	admin@gmail.com	9090909090	SRK	Chennai	-	-	{"Dashboard":"","Users":"","Catgory":"","Product":"","DAR":"","Estimation":"","Order":""}		001_WhatsApp Image 2024-07-30 at 17.45.58_a5451dbf.jpg
a29eed12-e98c-4bc6-9580-014db801901b	USR_2	Saran	123	sar@gmail.com	8989898989	Sales coordinator	Chennai	123	123	{"Dashboard":"","Users":"","Catgory":"","Product":"","DAR":"","Estimation":"","Order":""}	001	USR_2_Singapore Poster MY TRAVEL.jpg
14ab5161-7137-40b0-859c-1e9645d53805	USR_3	shalini	123	sha@gmail.com	6758965980	Sales Account	Chennai	123	123	{"Order":""}	001	USR_3_WhatsApp-Image-2024-07-01-at-17.50.29-1-1536x665.webp
917f318b-ade8-41a8-a740-00364443f095	USR_4	vivek	123	vv@gmail.com	7878787878	VS	Chennai	123	123	{"DAR":"","Estimation":""}	USR_2	USR_4_IMG-20240816-WA0005.jpg
\.


--
-- Name: category_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.category_sequence', 2, true);


--
-- Name: dar_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dar_sequence', 1, true);


--
-- Name: estimation_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estimation_sequence', 11, true);


--
-- Name: order_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_sequence', 12, true);


--
-- Name: product_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_sequence', 2, true);


--
-- Name: user_id_sequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_id_sequence', 5, true);


--
-- Name: dar_details dar_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dar_details
    ADD CONSTRAINT dar_details_pkey PRIMARY KEY (id);


--
-- Name: dar_expenses_details dar_expenses_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dar_expenses_details
    ADD CONSTRAINT dar_expenses_details_pkey PRIMARY KEY (id);


--
-- Name: estimation_details estimation_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimation_details
    ADD CONSTRAINT estimation_details_pkey PRIMARY KEY (id);


--
-- Name: estimation_product_details estimation_product_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimation_product_details
    ADD CONSTRAINT estimation_product_details_pkey PRIMARY KEY (id);


--
-- Name: order_details order_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_details
    ADD CONSTRAINT order_details_pkey PRIMARY KEY (id);


--
-- Name: order_product_details order_product_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_product_details
    ADD CONSTRAINT order_product_details_pkey PRIMARY KEY (id);


--
-- Name: product_category product_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_category
    ADD CONSTRAINT product_category_pkey PRIMARY KEY (id);


--
-- Name: product_details product_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_details
    ADD CONSTRAINT product_details_pkey PRIMARY KEY (id);


--
-- Name: profile_image_details profile_image_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile_image_details
    ADD CONSTRAINT profile_image_details_pkey PRIMARY KEY (id);


--
-- Name: user_details user_details_mobile_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_details
    ADD CONSTRAINT user_details_mobile_no_key UNIQUE (mobile_no);


--
-- Name: user_details user_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_details
    ADD CONSTRAINT user_details_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

