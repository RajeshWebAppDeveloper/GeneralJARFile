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
-- Name: customer_cars_info_list; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.customer_cars_info_list AS (
	id uuid,
	file_name character varying,
	car_name character varying,
	price_per_day character varying,
	car_no character varying,
	no_of_seat character varying,
	transmission_type character varying,
	fuel_type character varying
);


ALTER TYPE public.customer_cars_info_list OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_cars_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_cars_category (
    category_id uuid NOT NULL,
    category_name character varying(255)
);


ALTER TABLE public.admin_cars_category OWNER TO postgres;

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
    fuel_type character varying,
    limit_km character varying(255),
    price_per_day character varying(255),
    feul_type character varying(255)
);


ALTER TABLE public.admin_rental_cars_details OWNER TO postgres;

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
    mobile_no character varying(255)
);


ALTER TABLE public.admin_software_user_details OWNER TO postgres;

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
-- Name: customer_registration_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_registration_details (
    id uuid,
    name character varying(255),
    password character varying(255),
    mobile_no character varying(255),
    alternative_mobile_no character varying(255),
    age character varying(255),
    email_id character varying(255),
    sign_status character varying(255)
);


ALTER TABLE public.customer_registration_details OWNER TO postgres;

--
-- Data for Name: admin_cars_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_cars_category (category_id, category_name) FROM stdin;
0d1848a9-f7f8-4e07-a83c-b45f1c7acc57	luxu
6b619e92-5169-4a4e-a74b-0166928ac910	SUV
818dc8cc-b1e8-4c89-adef-bd6acda08f59	Sedan
d6dee699-f9d7-44aa-b226-fbb605c5aeae	Hatchback
4ad3d795-f848-4eff-8a4b-3cb27473110a	Convertible
\.


--
-- Data for Name: admin_rental_cars_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_rental_cars_details (id, brand, car_name, car_no, is_ac, img_url, category, no_of_seat, is_gps, transmission_type, fuel_type, limit_km, price_per_day, feul_type) FROM stdin;
1884870c-5caf-4f78-9d65-8e2c874eab1d	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
1d4c8670-27e7-4a1f-b818-bf0242a01434	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
e1025388-650c-4f43-a0ce-8808857f414c	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
5d26ca34-3e5e-4722-82c9-ef5db8619212	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
460328c2-9e06-4afa-8b2b-0ae714d36e1b	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
157d76d2-7d11-4d99-963a-09c222a2f29e	BMW	BMW X3	123	No	http://localhost:2024/RentARide/157d76d2-7d11-4d99-963a-09c222a2f29e_tesla.png	Sedan	5	Yes	Normal	\N	320 KM	4000	Petrol
\.


--
-- Data for Name: admin_rental_cars_upload; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_rental_cars_upload (id, file_path, file_name, file_type, convert_into_png_status) FROM stdin;
1884870c-5caf-4f78-9d65-8e2c874eab1d	C:/Users/Lenovo/Desktop/uploads/	1884870c-5caf-4f78-9d65-8e2c874eab1d_mercedes-offer.png	image/png	true
1d4c8670-27e7-4a1f-b818-bf0242a01434	C:/Users/Lenovo/Desktop/uploads/	1d4c8670-27e7-4a1f-b818-bf0242a01434_nissan-offer.png	image/png	true
e1025388-650c-4f43-a0ce-8808857f414c	C:/Users/Lenovo/Desktop/uploads/	e1025388-650c-4f43-a0ce-8808857f414c_offer-toyota.png	image/png	true
157d76d2-7d11-4d99-963a-09c222a2f29e	C:/Users/Lenovo/Desktop/uploads/	157d76d2-7d11-4d99-963a-09c222a2f29e_tesla.png	image/jpeg	true
5d26ca34-3e5e-4722-82c9-ef5db8619212	C:/Users/Lenovo/Desktop/uploads/	5d26ca34-3e5e-4722-82c9-ef5db8619212_tesla-removebg-preview.png	image/png	true
460328c2-9e06-4afa-8b2b-0ae714d36e1b	C:/Users/Lenovo/Desktop/uploads/	460328c2-9e06-4afa-8b2b-0ae714d36e1b_toyota-offer-2.png	image/png	true
\.


--
-- Data for Name: admin_software_user_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_software_user_details (user_id, password, email_id, mobile_no) FROM stdin;
admin	123	rajesh@smartyuppies.com	9090909090
superuser	123	super@gmail.com	9898989898
jack	jack	info@lionearentals.com	12345678
\.


--
-- Data for Name: cars; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cars (brand, model, year, email_id, mobile_no, password) FROM stdin;
BMW	X7	2010	\N	\N	\N
BMW	X5	2008	\N	\N	\N
\.


--
-- Data for Name: customer_registration_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_registration_details (id, name, password, mobile_no, alternative_mobile_no, age, email_id, sign_status) FROM stdin;
d30a0513-3c83-454a-9659-67598864fcab	ravi	8989	8989898989				active
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
-- Name: admin_cars_category admin_cars_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_cars_category
    ADD CONSTRAINT admin_cars_category_pkey PRIMARY KEY (category_id);


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
-- PostgreSQL database dump complete
--

