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
1	Roy Cook	(0115) 4960666	roy.cook@yahoo.co.uk	\N	12
2	Phillip Gibbons	(0306) 999 0374	phillip.gibbons@outlook.com	\N	8
3	Grace Chan	+44151 496 0243	grace.chan@gmail.com	\N	20
4	Kim Price	+44(0)1154960523	kim.price@outlook.com	\N	19
5	Shane Harrison	01632 960789	shane.harrison@gmail.com	2019-05-20	5
6	Marian Gill	+44(0)118 496 0073	marian.gill@hotmail.co.uk	\N	10
7	Thomas Begum	+44116 496 0162	thomas.begum@outlook.com	\N	8
8	Pamela Sheppard	(028) 9018100	pamela.sheppard@gmail.com	\N	18
9	Conor Parker	+441154960293	conor.parker@yahoo.co.uk	\N	16
10	Jamie Cross	+44808 1570766	jamie.cross@gmail.com	2021-01-03	19
11	Helen Austin	0161 4960664	helen.austin@gmail.com	\N	17
12	Gavin Porter	0115 496 0537	gavin.porter@yahoo.co.uk	\N	8
13	Tom Jones	0151 4960040	tom.jones@outlook.com	\N	8
14	Brett Ryan	+4420 74960153	brett.ryan@hotmail.co.uk	2019-09-28	16
15	Gordon King	(0808) 1570986	gordon.king@gmail.com	\N	20
16	Dennis Wood	+44(0)116 4960117	dennis.wood@yahoo.com	\N	18
17	Claire Taylor	0191 4960948	claire.taylor@gmail.com	\N	3
18	Charlotte Osborne	(0115) 4960289	charlotte.osborne@hotmail.co.uk	\N	19
19	Jordan Jackson	0121 4960018	jordan.jackson@yahoo.com	\N	20
20	Mathew Page	+44909 8790767	mathew.page@hotmail.co.uk	\N	4
21	Geraldine Wheeler	0808 157 0181	geraldine.wheeler@yahoo.com	\N	7
22	Shaun Crawford	+4428 9018 0381	shaun.crawford@outlook.com	\N	14
23	Jacob Power	+44(0)909 879 0944	jacob.power@hotmail.co.uk	\N	15
24	Gerald Miles	020 74960664	gerald.miles@outlook.com	\N	9
25	Emily Read	(028)9018912	emily.read@yahoo.com	\N	17
26	Tina Poole	+44141 4960581	tina.poole@hotmail.co.uk	\N	4
27	Malcolm Bishop	01144960423	malcolm.bishop@gmail.com	\N	10
28	Marian Kaur	+44(0)1214960708	marian.kaur@yahoo.com	\N	6
29	Julia Sharpe	(01632)960104	julia.sharpe@gmail.com	\N	16
30	Alan Harris	(0909) 879 0375	alan.harris@yahoo.com	\N	11
31	Abbie Shaw	+4428 9018932	abbie.shaw@gmail.com	\N	1
32	Marion Porter	0306 9990450	marion.porter@hotmail.com	\N	2
33	Glen Richardson	+4429 2018 0584	glen.richardson@gmail.com	\N	11
34	Samantha Moore	+44(0)28 9018 0681	samantha.moore@hotmail.com	\N	9
35	Kathryn Todd	(0131) 496 0854	kathryn.todd@yahoo.co.uk	\N	19
36	Glen Cunningham	+44(0)292018006	glen.cunningham@outlook.com	\N	16
37	David Middleton	(0115)4960956	david.middleton@gmail.com	\N	8
38	Roy Lewis	(0118) 4960357	roy.lewis@hotmail.com	\N	9
39	Josephine Hancock	(0808) 157 0643	josephine.hancock@outlook.com	\N	20
40	Kate Walker	+441632960623	kate.walker@gmail.com	\N	6
41	Toby Chapman	(0118) 496 0943	toby.chapman@outlook.com	\N	15
42	Lindsey Evans	+44(0)2074960052	lindsey.evans@outlook.com	\N	5
43	Victoria Poole	+44(0)20 74960668	victoria.poole@outlook.com	\N	19
44	Alexandra Fox	+44141 496 0883	alexandra.fox@hotmail.co.uk	\N	13
45	Annette Woodward	+44161 496 0144	annette.woodward@hotmail.co.uk	\N	6
46	Hollie Jones	028 9018 0332	hollie.jones@hotmail.com	\N	4
47	Clive Barry	+441632960622	clive.barry@yahoo.com	\N	14
48	Sam Finch	+441614960499	sam.finch@yahoo.com	\N	1
49	Nicholas Howard	03069990664	nicholas.howard@hotmail.co.uk	\N	3
50	Robin Lane	(0191) 496 0117	robin.lane@yahoo.co.uk	2018-02-03	3
51	Anthony Gregory	0808 157 0516	anthony.gregory@gmail.com	\N	20
52	Rhys Tomlinson	+44(0)1214960514	rhys.tomlinson@hotmail.co.uk	\N	16
53	Robin Evans	(0115) 496 0305	robin.evans@hotmail.com	\N	14
54	Frances Turner	+44191 4960261	frances.turner@yahoo.com	\N	15
55	Naomi Nicholson	(0121)4960230	naomi.nicholson@yahoo.com	\N	9
56	Kimberley Owens	01184960507	kimberley.owens@outlook.com	\N	15
57	Kimberley Burgess	01184960526	kimberley.burgess@gmail.com	\N	17
58	Kerry Hunter	(01632)960951	kerry.hunter@hotmail.com	\N	5
59	Jacqueline Wilson	03069990759	jacqueline.wilson@yahoo.com	\N	11
60	Mohammed Rose	+441144960698	mohammed.rose@hotmail.co.uk	\N	7
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

