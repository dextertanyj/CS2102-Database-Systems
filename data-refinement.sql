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
1	James, Ahmed and Davies	\N
2	Robson, Davies and Lewis	\N
3	Wheeler, Knight and Welch	\N
4	Gardiner, Burton and Martin	\N
5	Norman-Ali	\N
6	Roberts-Gardiner	\N
7	Fox-Barnes	\N
8	Herbert-Atkinson	\N
9	Wood, Powell and Matthews	\N
10	Ball Ltd	\N
11	Little, Mills and Evans	\N
12	Martin-Bell	\N
13	Wade LLC	\N
14	Graham, Marshall and Mason	2021-03-08
15	Robinson-Turner	\N
16	Bird, Rogers and Webb	\N
17	Williams, Cole and Sheppard	\N
18	Williams, Kaur and Wilson	\N
19	Dawson LLC	\N
20	Lewis-Chadwick	\N
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employees (id, name, contact_number, email, resignation_date, department_id) FROM stdin;
1	Hong Hao Ming	+65-955-548-23 	roy.cook@yahoo.co.uk	\N	12
2	Yung Yong Zu	+65-851-540-87	phillip.gibbons@outlook.com	\N	8
3	Tan Wei Le	+65-952-521-65	grace.chan@gmail.com	\N	20
4	Jamus Beh Yong Zu	+65-857-566-89	kim.price@outlook.com	\N	19
5	Woo Zi Yi	+65-815-508-78	shane.harrison@gmail.com	2019-05-20	5
6	Oon Ling Hui	+65-823-575-59	marian.gill@hotmail.co.uk	\N	10
7	Yeh Kai Xin	+65-955-512-25	thomas.begum@outlook.com	\N	8
8	Leong Xuan Ming	+65-955-549-03	pamela.sheppard@gmail.com	\N	18
9	Lin Zi Rui Constance	+65-855-564-57	conor.parker@yahoo.co.uk	\N	16
10	Jamie Liew	+65-855-551-52	jamie.cross@gmail.com	2021-01-03	19
11	Leow Jun Jie	+65-955-540-50	helen.austin@gmail.com	\N	17
12	Satvik Nair	+65-913-546-61	gavin.porter@yahoo.co.uk	\N	8
13	Chu Ling Hui	+65-927-520-93	tom.jones@outlook.com	\N	8
14	Constance Lim	+65-855-514-09	brett.ryan@hotmail.co.uk	2019-09-28	16
15	Chang Jia De	+65-831-213-20	gordon.king@gmail.com	\N	20
16	Deng Jia Le	+65-951-312-09	dennis.wood@yahoo.com	\N	18
17	Kamarul Asra Bin Mohammed Nazir	+65-855-123-09	claire.taylor@gmail.com	\N	3
18	Guo Hao Ming	+65-956-471-23	charlotte.osborne@hotmail.co.uk	\N	19
19	Mohammad Syaril	+65-855-514-08	jordan.jackson@yahoo.com	\N	20
20	Santhi Banavi Tharumalingam	+65-973-215-09	mathew.page@hotmail.co.uk	\N	4
21	Ai Guo	+65-813-532-12	geraldine.wheeler@yahoo.com	\N	7
22	Leung Guo Qiang	+65-895-471-92	shaun.crawford@outlook.com	\N	14
23	Jacob Zeng Jun Le	+65-895-123-92	jacob.power@hotmail.co.uk	\N	15
24	Cao Lin	+65-895-178-28	gerald.miles@outlook.com	\N	9
25	Emily Chew	+65-938-192-87	emily.read@yahoo.com	\N	17
26	Tina Poll	+65-931-934-21	tina.poole@hotmail.co.uk	\N	4
27	Malcolm Wong	+65-895-178-28	malcolm.bishop@gmail.com	\N	10
28	Marian Kaur	+65-918-192-19	marian.kaur@yahoo.com	\N	6
29	Kavitha Krishnan	+65-829-444-19	julia.sharpe@gmail.com	\N	16
30	Santhi Muthu D/O A. Sathasivam	+65-895-178-28	alan.harris@yahoo.com	\N	11
31	Abbie Lim	+65-823-392-20	abbie.shaw@gmail.com	\N	1
32	Abbie Lim	+65-829-391-21	marion.porter@hotmail.com	\N	2
33	Hu Hui Shan	+65-895-293-10	glen.richardson@gmail.com	\N	11
34	Lim Jun Jie	+65-895-444-49	samantha.moore@hotmail.com	\N	9
35	Kathryn Todd	+65-839-109-75	kathryn.todd@yahoo.co.uk	\N	19
36	Baey Cheng Boon	+65-819-192-49	glen.cunningham@outlook.com	\N	16
37	Fung Ming En	+65-928-309-94	david.middleton@gmail.com	\N	8
38	Roy Lewis	+65-918-137-20	roy.lewis@hotmail.com	\N	9
39	Teo Xin Yi	+65-891-118-39	josephine.hancock@outlook.com	\N	20
40	Ang Cheng Hao	+65-890-192-02	kate.walker@gmail.com	\N	6
41	Lin Wei Le	+65-801-123-01	toby.chapman@outlook.com	\N	15
42	Chua Jia De	+65-876-123-31	lindsey.evans@outlook.com	\N	5
43	Umar Saifullah	+65-910-171-71	victoria.poole@outlook.com	\N	19
44	Kenji Tatsuya	+65-919-158-58	alexandra.fox@hotmail.co.uk	\N	13
45	Saiful Abdullah Bin Yusoff Radin	+65-910-100-22	annette.woodward@hotmail.co.uk	\N	6
46	Diah Sharifah	+65-938-109-31	hollie.jones@hotmail.com	\N	4
47	Hemendra Raj s/o A. Raju	+65-895-100-24	clive.barry@yahoo.com	\N	14
48	Hazel Rana d/o A. Raju	+65-823-190-21	sam.finch@yahoo.com	\N	1
49	Loo Xin En	+65-890-118-38	nicholas.howard@hotmail.co.uk	\N	3
50	Lim Wen Yi Cassandra	+65-913-549-28	robin.lane@yahoo.co.uk	2018-02-03	3
51	Low Jia Hui	+65-855-178-28	anthony.gregory@gmail.com	\N	20
52	Koh Si Ling	+65-910-170-21	rhys.tomlinson@hotmail.co.uk	\N	16
53	Koh Xin En	+65-930-100-90	robin.evans@hotmail.com	\N	14
54	Chua Kai De	+65-815-131-12	frances.turner@yahoo.com	\N	15
55	Naomi Nicholson	+65-840-140-40	naomi.nicholson@yahoo.com	\N	9
56	Chua Kai Xiang	+65-813-738-63	kimberley.owens@outlook.com	\N	15
57	Lin Jun Jie	+65-837-178-28	kimberley.burgess@gmail.com	\N	17
58	Collin Tan	+65-915-100-03	kerry.hunter@hotmail.com	\N	5
59	Jacqueline Saiful	+65-856-124-98	jacqueline.wilson@yahoo.com	\N	11
60	Mohammed Ali	+65-920-112-28	mohammed.rose@hotmail.co.uk	\N	7
\.


--
-- Data for Name: superiors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.superiors (id) FROM stdin;
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
60
\.


--
-- Data for Name: managers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.managers (id) FROM stdin;
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
60
\.


--
-- Data for Name: meetingrooms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meetingrooms (floor, room, name, department_id) FROM stdin;
3	8	Database Meeting Room	4
2	7	Cloud Technology Partners	10
1	1	Zaius	4
2	3	MOO	5
1	6	Bynder	3
3	4	InCrowd	7
1	5	MOO	17
3	7	MOO	18
3	6	BevSpot	1
1	7	InCrowd	13
2	5	Continuum	15
2	4	Crayon	15
3	5	Zaius	16
2	8	Continuum	12
1	9	Continuum	13
3	2	Crayon	1
1	3	Crayon	4
3	1	Cloud Technology Partners	19
2	6	Bynder	6
3	9	Zaius	12
\.


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bookings (floor, room, date, start_hour, creator_id, approver_id) FROM stdin;
3	1	2021-10-04	9	21	46
3	5	2021-10-13	22	35	44
1	3	2021-10-04	20	51	44
2	6	2021-10-03	12	58	47
1	7	2021-10-12	11	25	47
3	9	2021-10-06	17	54	41
1	1	2021-10-09	12	23	41
2	8	2021-10-08	10	32	42
2	4	2021-10-04	10	51	46
3	8	2021-10-13	6	29	50
1	5	2021-10-07	7	36	53
3	9	2021-10-02	17	58	60
2	8	2021-10-04	17	22	45
3	8	2021-10-02	3	22	42
3	4	2021-10-09	3	45	43
3	8	2021-10-10	21	48	46
3	9	2021-10-08	13	24	58
3	4	2021-10-08	1	45	59
1	9	2021-10-07	14	42	46
2	7	2021-10-09	12	50	56
\.


--
-- Data for Name: attends; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attends (employee_id, floor, room, date, start_hour) FROM stdin;
43	3	9	2021-10-02	17
9	1	3	2021-10-04	20
17	2	4	2021-10-04	10
6	3	9	2021-10-06	17
1	3	4	2021-10-09	3
18	1	7	2021-10-12	11
59	1	3	2021-10-04	20
20	3	9	2021-10-08	13
50	1	7	2021-10-12	11
35	2	6	2021-10-03	12
19	2	6	2021-10-03	12
52	2	7	2021-10-09	12
52	1	5	2021-10-07	7
37	3	1	2021-10-04	9
41	2	4	2021-10-04	10
28	3	9	2021-10-08	13
10	3	9	2021-10-08	13
41	3	5	2021-10-13	22
39	3	5	2021-10-13	22
42	3	5	2021-10-13	22
35	1	1	2021-10-09	12
14	3	1	2021-10-04	9
20	1	7	2021-10-12	11
10	3	8	2021-10-02	3
24	3	1	2021-10-04	9
43	3	9	2021-10-08	13
31	2	6	2021-10-03	12
30	3	8	2021-10-13	6
12	3	4	2021-10-09	3
2	1	7	2021-10-12	11
39	2	8	2021-10-04	17
29	1	7	2021-10-12	11
22	3	9	2021-10-06	17
10	3	8	2021-10-10	21
32	3	5	2021-10-13	22
25	1	9	2021-10-07	14
31	3	9	2021-10-06	17
14	2	4	2021-10-04	10
34	3	8	2021-10-10	21
42	3	9	2021-10-02	17
\.


--
-- Data for Name: healthdeclarations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.healthdeclarations (id, date, temperature) FROM stdin;
6	2021-10-03	36.5
29	2021-10-02	36.2
4	2021-10-06	34.9
29	2021-10-06	37.0
40	2021-10-12	40.3
39	2021-10-01	35.1
23	2021-10-11	36.7
22	2021-10-12	37.2
30	2021-10-01	36.4
13	2021-10-02	34.6
28	2021-10-10	34.9
3	2021-10-03	35.1
41	2021-10-09	41.5
37	2021-10-08	36.7
24	2021-10-08	36.4
4	2021-10-07	35.0
20	2021-10-03	35.4
4	2021-10-01	35.1
7	2021-10-06	36.3
12	2021-10-01	35.9
3	2021-10-09	36.5
39	2021-10-07	36.7
5	2021-10-04	36.2
13	2021-10-03	37.1
11	2021-10-12	35.0
26	2021-10-02	36.9
22	2021-10-06	34.2
12	2021-10-03	35.1
38	2021-10-02	36.6
10	2021-10-13	37.2
42	2021-10-10	41.9
26	2021-10-03	34.6
26	2021-10-12	34.7
16	2021-10-13	34.6
28	2021-10-08	35.9
19	2021-10-02	37.4
42	2021-10-11	42.9
7	2021-10-07	36.2
34	2021-10-10	37.0
39	2021-10-12	35.5
\.


--
-- Data for Name: juniors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.juniors (id) FROM stdin;
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
20
\.


--
-- Data for Name: seniors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.seniors (id) FROM stdin;
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
\.


--
-- Data for Name: updates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.updates (manager_id, floor, room, date, capacity) FROM stdin;
58	2	6	2021-10-03	6
51	1	6	2021-10-12	5
42	1	6	2021-10-01	7
51	2	7	2021-10-07	8
42	1	3	2021-10-02	6
43	3	9	2021-10-01	0
42	1	6	2021-10-08	0
54	2	4	2021-10-01	3
59	3	2	2021-10-02	1
43	2	3	2021-10-09	5
54	1	9	2021-10-13	4
45	3	4	2021-10-13	6
58	3	1	2021-10-07	3
45	3	7	2021-10-02	6
57	1	5	2021-10-07	9
53	3	2	2021-10-09	3
58	1	1	2021-10-01	2
58	2	6	2021-10-07	2
53	1	1	2021-10-13	7
41	1	5	2021-10-02	7
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

