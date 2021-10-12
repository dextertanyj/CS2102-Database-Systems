--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 13.4

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
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departments (id, name, removal_date) FROM stdin;
0	Hill-Watts	\N
1	Jones Inc	2019-10-01
2	Bennett, Davies and Hall	\N
3	Turner, Dawson and Hill	\N
4	Rice Group	\N
5	Savage and Sons	\N
6	Riley Group	\N
7	Atkins-White	\N
8	Smart Inc	\N
9	Finch, Fisher and Evans	\N
10	Craig-Allen	\N
11	Clark-Short	\N
12	Foster Group	\N
13	Smith, Fuller and Macdonald	\N
14	Campbell PLC	\N
15	Bibi Inc	\N
16	Sykes, Smith and Owen	\N
17	Thornton, Palmer and Walker	\N
18	Young-O'Brien	2018-08-05
19	Rowley, Hart and Yates	\N
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (id, name, contact_number, email, resignation_date, department_id) FROM stdin;
0	Nicola Shaw	+44(0)306 999 0690	nicola.shaw@outlook.com	2017-07-16	14
1	Laura Baker	0121 496 0532	laura.baker@hotmail.com	\N	12
2	Carly Rogers	0121 4960076	carly.rogers@yahoo.com	\N	4
3	Benjamin Lawrence	+44(0)1154960271	benjamin.lawrence@hotmail.com	\N	0
4	Dean Shaw	+4429 2018578	dean.shaw@yahoo.com	\N	11
5	Abbie Wong	0115 4960458	abbie.wong@yahoo.co.uk	\N	0
6	Jamie Rogers	(0115)4960423	jamie.rogers@hotmail.com	\N	3
7	Gary Hutchinson	+44(0)909 8790979	gary.hutchinson@gmail.com	\N	4
8	Owen Williams	0909 8790613	owen.williams@gmail.com	\N	8
9	Jeffrey Rogers	029 2018188	jeffrey.rogers@hotmail.com	\N	10
10	John Martin	0141 496 0851	john.martin@gmail.com	\N	16
11	Patricia Baker	+441632 960737	patricia.baker@outlook.com	\N	1
12	Gillian Wade	01414960877	gillian.wade@yahoo.co.uk	\N	14
13	Emma O'Donnell	08081570685	emma.o'donnell@gmail.com	\N	4
14	George Williams	+44(0)113 496 0927	george.williams@hotmail.com	\N	4
15	Abigail Scott	+44(0)121 4960963	abigail.scott@hotmail.co.uk	\N	16
16	Kirsty O'Brien	0151 4960977	kirsty.o'brien@yahoo.co.uk	\N	18
17	Harriet King	+44(0)161 4960786	harriet.king@hotmail.co.uk	\N	1
18	Sheila Thompson	+44151 496 0786	sheila.thompson@hotmail.com	\N	11
19	Gemma Smith	+449098790637	gemma.smith@gmail.com	2016-01-28	1
20	Richard Kelly	+44(0)1632 960890	richard.kelly@gmail.com	\N	9
21	Donna Ward	(0161) 4960136	donna.ward@yahoo.co.uk	\N	2
22	Claire Gough	+44(0)29 2018572	claire.gough@hotmail.com	\N	17
23	Sally Begum	+441314960773	sally.begum@yahoo.co.uk	\N	16
24	Laura Moore	+44141 496 0522	laura.moore@gmail.com	\N	8
25	Alan Gregory	+44(0)909 879 0655	alan.gregory@hotmail.co.uk	\N	8
26	Michelle Edwards	(0151) 4960899	michelle.edwards@hotmail.com	2019-05-09	8
27	John Moss	+44114 496 0502	john.moss@gmail.com	\N	2
28	Geoffrey Lloyd	+44(0)1314960696	geoffrey.lloyd@hotmail.com	\N	1
29	Adam Thomas	+441144960026	adam.thomas@hotmail.co.uk	2019-04-12	13
30	Caroline Curtis	(01632)960577	caroline.curtis@hotmail.co.uk	2019-08-06	11
31	Fiona Robinson	(0121) 496 0184	fiona.robinson@outlook.com	\N	19
32	Carolyn Wilson	+44(0)161 4960442	carolyn.wilson@gmail.com	\N	10
33	Linda Saunders	(0909)8790391	linda.saunders@yahoo.co.uk	\N	13
34	Naomi Day	+44151 496 0797	naomi.day@gmail.com	\N	4
35	Annette Richards	029 2018 0188	annette.richards@hotmail.co.uk	\N	8
36	Mohammed Norton	+44(0)191 4960462	mohammed.norton@yahoo.co.uk	\N	15
37	Nicole Ward	+441632 960 808	nicole.ward@outlook.com	\N	13
38	Kate Davidson	(020)74960372	kate.davidson@yahoo.co.uk	\N	18
39	Tina Thompson	01214960796	tina.thompson@gmail.com	\N	14
40	Hugh White	(0115) 4960343	hugh.white@yahoo.com	\N	17
41	Pauline Elliott	+44(0)1144960690	pauline.elliott@yahoo.co.uk	\N	12
42	Joyce Gray	+44116 496 0626	joyce.gray@gmail.com	\N	15
43	Martin Marshall	01314960225	martin.marshall@hotmail.co.uk	\N	6
44	Daniel Young	+441144960227	daniel.young@yahoo.co.uk	\N	9
45	Carly Thompson	+44(0)3069990968	carly.thompson@hotmail.com	2019-12-12	11
46	Lynda Begum	+441134960824	lynda.begum@outlook.com	2019-10-20	3
47	Samantha Gallagher	(0306) 999 0655	samantha.gallagher@yahoo.com	\N	13
48	Bradley Jones	(0121) 4960416	bradley.jones@outlook.com	\N	15
49	John Woods	+44(0)1184960653	john.woods@yahoo.co.uk	\N	19
50	Oliver Lane	+44(0)20 74960487	oliver.lane@gmail.com	\N	6
51	Sally Robinson	(0909) 8790978	sally.robinson@gmail.com	\N	5
52	Gail Woodward	(028) 9018786	gail.woodward@hotmail.co.uk	2016-05-22	18
53	Nigel Poole	+44(0)114 496 0206	nigel.poole@yahoo.com	\N	12
54	Gerard Chapman	+44(0)909 8790129	gerard.chapman@hotmail.com	\N	19
55	Lewis Harvey	(0131)4960409	lewis.harvey@hotmail.com	\N	3
56	Charlie White	(0115) 4960281	charlie.white@outlook.com	\N	0
57	Nigel Barnes	+44141 496 0784	nigel.barnes@gmail.com	\N	8
58	Katy Davies	0131 4960211	katy.davies@hotmail.com	\N	9
59	Trevor Cooke	+441314960807	trevor.cooke@yahoo.co.uk	\N	16
\.


--
-- Data for Name: superiors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.superiors (id) FROM stdin;
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
\.


--
-- Data for Name: managers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.managers (id) FROM stdin;
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
\.


--
-- Data for Name: meetingrooms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meetingrooms (floor, room, name, department_id) FROM stdin;
3	4	InCrowd	5
1	2	InCrowd	10
1	3	Zaius	9
3	5	Cloud Technology Partners	15
1	7	Cloud Technology Partners	15
2	8	Database Meeting Room	6
3	2	Bynder	9
2	6	Crayon	19
2	7	Bynder	17
3	9	Bynder	16
3	8	Bynder	17
2	9	Zaius	11
2	4	BevSpot	5
3	6	Cloud Technology Partners	14
3	7	Continuum	8
2	2	Zaius	9
1	8	Continuum	9
2	3	Crayon	7
1	1	Zaius	13
3	3	Zaius	17
\.


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bookings (floor, room, date, start_hour, creator_id, approver_id) FROM stdin;
2	2	2021-10-05	17	36	59
2	9	2021-10-10	9	51	53
2	7	2021-10-09	15	23	44
2	9	2021-10-01	5	26	51
3	6	2021-10-02	11	20	53
2	4	2021-10-06	0	59	56
2	9	2021-10-03	4	32	45
3	4	2021-10-07	23	29	45
1	2	2021-10-03	22	47	58
2	4	2021-10-02	13	42	47
2	6	2021-10-10	17	24	51
2	4	2021-10-05	19	35	55
3	4	2021-10-04	10	26	48
3	2	2021-10-10	9	45	58
2	7	2021-10-04	18	44	49
2	7	2021-10-09	23	58	48
3	9	2021-10-09	6	38	43
3	5	2021-10-01	16	54	43
2	3	2021-10-06	17	32	50
2	3	2021-10-06	5	25	48
\.


--
-- Data for Name: attends; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attends (employee_id, floor, room, date, start_hour) FROM stdin;
27	2	9	2021-10-03	4
20	3	5	2021-10-01	16
52	3	6	2021-10-02	11
27	2	6	2021-10-10	17
33	2	7	2021-10-09	15
13	3	4	2021-10-04	10
35	2	9	2021-10-03	4
20	3	2	2021-10-10	9
14	3	5	2021-10-01	16
21	2	9	2021-10-03	4
49	2	4	2021-10-06	0
29	2	4	2021-10-05	19
54	2	7	2021-10-09	23
24	2	3	2021-10-06	17
44	3	4	2021-10-07	23
53	3	9	2021-10-09	6
47	2	4	2021-10-02	13
34	2	4	2021-10-06	0
52	3	4	2021-10-07	23
31	3	9	2021-10-09	6
57	3	6	2021-10-02	11
45	1	2	2021-10-03	22
17	2	4	2021-10-05	19
32	2	6	2021-10-10	17
37	3	9	2021-10-09	6
23	3	2	2021-10-10	9
50	2	3	2021-10-06	17
45	2	9	2021-10-10	9
23	2	9	2021-10-10	9
7	2	4	2021-10-02	13
\.


--
-- Data for Name: healthdeclarations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.healthdeclarations (id, date, temperature) FROM stdin;
19	2021-10-02	35.4
13	2021-10-09	42.2
1	2021-10-01	41.1
6	2021-10-08	34.5
3	2021-10-07	37.0
6	2021-10-11	35.5
15	2021-10-01	41.0
13	2021-10-06	37.8
4	2021-10-02	42.0
4	2021-10-06	35.5
18	2021-10-03	34.7
18	2021-10-09	35.4
4	2021-10-05	41.5
12	2021-10-04	37.3
2	2021-10-08	34.5
3	2021-10-06	34.7
5	2021-10-03	36.2
11	2021-10-10	41.1
16	2021-10-06	40.0
13	2021-10-01	39.7
\.


--
-- Data for Name: juniors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.juniors (id) FROM stdin;
0
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
\.


--
-- Data for Name: seniors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.seniors (id) FROM stdin;
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
\.


--
-- Data for Name: updates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.updates (manager_id, floor, room, date, capacity) FROM stdin;
50	3	6	2021-10-06	3
41	2	7	2021-10-05	5
50	3	2	2021-10-01	1
46	2	6	2021-10-11	5
45	3	8	2021-10-11	6
58	3	2	2021-10-11	1
56	3	5	2021-10-09	9
43	1	8	2021-10-04	7
56	3	9	2021-10-11	8
44	3	2	2021-10-05	4
42	1	7	2021-10-09	3
57	1	8	2021-10-01	2
54	1	8	2021-10-06	2
48	2	7	2021-10-11	3
42	2	4	2021-10-11	6
55	2	7	2021-10-06	8
54	2	4	2021-10-07	6
50	1	3	2021-10-09	0
50	1	3	2021-10-10	5
43	3	8	2021-10-02	1
\.


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.departments_id_seq', 1, false);


--
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

