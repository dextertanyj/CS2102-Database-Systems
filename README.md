## Constraints

| ID | Entity / Relationship | Description | Implementation |
|----|-----------------------|-------------|----------------|
| D-1 | Departments | Each department records the following information: Department Name. | Schema (Field) |
| D-2 | Departments | Each department has a unique ID. | Schema (Primary Key) |
| D-3 | Departments | Each department may contain zero or more employees. | Schema (Referenced in Foreign Key) |
| D-4 | Departments | Each department may have zero or more meeting rooms. | Schema (Referenced in Foreign Key) |
| E-1 | Employees | Each employee records the following information: Name, Contact Numbers, Resignation Date. | Schema (Field) |
| E-2 | Employees | Each employee has a unique ID. | Schema (Primary Key) |
| E-3 | Employees | Each employee has a unique e-mail. | Schema (Unique) |
| E-4 | Employees | Each employee belongs to exactly one department. | Schema (NOT NULL & Foreign Key) |
| E-5 | Employees | Each employee must be one and only one of the three kinds of employees. | Trigger ([Check Junior Insertion](#check-junior-insertion), [Check Senior Insertion](#check-senior-insertion), [Check Manager Insertion](#check-manager-insertion), [Check Covering Employee](#check-covering-employee)) |
| E-6 | Employees | When an employee resigns, all past records are kept. | Schema (Field) [See E-1] |
| E-7 | Employees | When an employee resigns, the employee is removed from all future meetings, approved or otherwise. | Trigger (Not yet implemented.) |
| E-8 | Employees | When an employee resigns, the employee has all their future booked meetings canclled, approved or otherwise. | Trigger (Not yet implemented.) |
| E-9 | Employees | When an employee resigns, all future approvals granted by the employee are revoked. | Trigger (Lock Removed Department Employees Trigger[#lock-removed-department-employees-trigger]) |
| E-10 | Employees | Each employee can attend only one booked meeting at a given date and time. | Schema (Unique) |
| E-11 | Employees | When a department has been removed, employees cannot be added to it. | Trigger (Not yet implemented.) |
| MR-1 | Meeting Rooms | Each meeting room has a unique Floor-Room pair. | Schema (Primary Key) |
| MR-2 | Meeting Rooms | Each meeting room records the following information: Room name. | Schema (Field) |
| MR-3 | Meeting Rooms | Each meeting room must be located in exactly one department. | Schema (NOT NULL & Foreign Key) |
| MR-4 | Meeting Rooms | Each meeting room must have at least one relevant capacities entry. | Trigger (Not yet implemented.) |
| MR-5 | Meeting Rooms | When a department has been removed, meeting rooms cannot be added to it. | Trigger (Lock Removed Department Meeting Rooms Trigger)[#lock-removed-department-meeting-rooms-trigger] |
| B-1 | Bookings | A junior employee cannot book any meeting rooms. | Schema (Foreign Key) [See B-2] |
| B-2 | Bookings | A senior or a manager can book meeting rooms. | Schema (NOT NULL & Foreign Key) |
| B-3 | Bookings | A meeting room can only be booked by one group for a given date and time. | Schema (Primary Key) |
| B-4 | Bookings | A booking can only be made for future meetings. | Trigger ([Booking Date Check](#booking-date-check)) |
| B-5 | Bookings | The employee booking the room immediately joins the booked meeting. | Trigger ([Insert Meeting Creator](#insert-meeting-creator)) |
| B-6 | Bookings | Only a manager can approve a booked meeting. | Schema (Foriegn Key) |
| B-7 | Bookings | A manager can only approve a booked meeting if the meeting room used is in the same department as the manager. | Trigger (Not yet implemented.) |
| B-8 | Bookings | A manager can only approve a booked meeting if it is in the future. | Trigger ([Approval Only for Future Meetings Trigger](#approval-only-for-future-meetings-trigger)) |
| B-9 | Bookings | A booked meeting is approved at most once. | Schema (Foreign Key) & Trigger ([Check Booking Approval](#check-booking-approval)) |
| B-10 | Bookings | If an employee is having a fever, they cannot book a room. | Trigger ([Check Health Declaration Booking](#check-health-declaration-booking)) |
| B-11 | Bookings | If an employee is having a fever, they cannot book any meeting room until they are no longer having a fever. | Trigger [See B-11] |
| B-12 | Bookings | When an employee resigns, they are no longer allowed to book any meetings. | Trigger ([Check Resignation Booking Create Approve](#check-resignation-booking-create-approve)) |
| B-13 | Bookings | When an employee resigns, they are no longer allowed to approve any meetings. | Trigger ([Check Resignation Booking Create Approve](#check-resignation-booking-create-approve)) |
| B-14 | Bookings | A approved booked meeting can no longer have any of its details changed, except for the revocation of its approver. | Trigger (Not yet implemented.) |
| A-1 | Attends | Any employee can join a booked meeting. | Schema (Foreign Key) |
| A-2 | Attends | An employee can only join future meetings. | Trigger ([Employee Join Only Future Meetings Trigger](#employee-join-only-future-meetings-trigger)) |
| A-3 | Attends | If an employee is having a fever, they cannot join a booked meeting. | Trigger ([Check Health Declaration Attends](#check-health-declaration-attends)) |
| A-4 | Attends | Once approved, there should be no more changes in the participants and the participants will definitely attend the meeting. | Trigger ([Check Attends Change](#check-attends-change)) |
| A-5 | Attends | When an employee resigns, they are no longer allowed to join any booked meetings. | Trigger ([Check Resignation Attends](#check-resignation-attends)) |
| A-6 | Attends | The number of people attending a meeting should not exceed the latest past capacity declared. | Trigger ([Check Meeting Capacity Trigger](#check-meeting-capacity-trigger)) |
| A-7 | Attends | The employee booking the room cannot leave the meeting. | Trigger ([Prevent Creator Removal](#prevent-creator-removal)) |
| C-1 | Capacities | A manager from the same department as the meeting room may change the meeting room capacity. | Trigger ([Check Update Capacity Permissions](#check-update-capacity-permissions)) |
| C-2 | Capacities | If a meeting room has its capacity changed, all future meetings that exceed the new capacity will be removed. | Trigger ([Check Future Meetings On Capacity Change Trigger](#check-future-meetings-on-capacity-change-trigger)) |
| C-3 | Capacities | When an employee resigns, they are no longer allowed to change any meeting room capacities. | Trigger ([Check Resignation Updates](#check-resignation-updates)) |
| C-4 | Capacities | A meeting room can only have its capacity updated for a date not in the past. | Trigger (Not implemented yet.) |
| H-1 | Health Declarations | Every employee must do a daily health declaration. | Not Enforceable |
| H-2 | Health Declarations | A health declaration records the following information: Temperature, Date. | Schema (Field) |
| H-3 | Health Declarations | A health declaration for a given employee can be uniquely identified by the date. | Schema (Primary Key) |
| H-4 | Health Declarations | If the declared temperature is higher than 37.5 degrees celsius, the employee is having a fever. | No Action Required |
| H-5 | Health Declarations | The declared temperature can only be between 34 and 43 degress celsius. | Schema (Check) |
| H-6 | Health Declarations | When an employee resigns, they are no longer allowed to make any health declarations. | Trigger ([Check Resignation Health Declarations](#check-resignation-health-declarations)) |
| H-7 | Health Declarations | A health declaration cannot be made for any date other than the current date. | Trigger ([Health Declaration Date Check](#health-declaration-date-check)) |
| H-8 | Health Declarations | Past health declarations cannot be modified. | Trigger ([Health Declaration Date Check](#health-declaration-date-check)) |
| CT-1 | Contact Tracing | Close contacts are defined as employees who attended the same booked and approved meeting as an employee with a fever in any of the three days preceeding the fever. | Function |
| CT-2 | Contact Tracing | If an employee is having a fever, all future bookings are cancelled, approved or otherwise. | Function |
| CT-3 | Contact Tracing | If an employee is having a fever, they are removed from all future booked meetings. | Function |
| CT-4 | Contact Tracing | Close contacts have their booked meetings for the next seven days cancelled, approved or otherwise. | Function |
| CT-5 | Contact Tracing | Close contacts are removed from any future meetings for the next seven days. | Function |


## Triggers 

---

### Departments

No triggers implemented.

---

### Employees / Juniors / Superiors / Seniors / Managers

#### **Check Junior Insertion**
Activated on:
1. Before `INSERT` or `UPDATE` on `Juniors` table.

Actions: 
1. Raises exception when employee ID exists in `Superiors` table.
1. Otherwise, continue.

#### **Check Senior Insertion**
Activated on:
1. Before `INSERT` or `UPDATE` on `Seniors` table.

Actions:
1. Raises exception when employee ID exists in `Managers` table.
1. Otherwise, continue.

#### **Check Manager Insertion**
Activated on:
1. Before `INSERT` or `UPDATE` on `Managers` table.

Actions:
1. Raises exception when employee ID exists in `Seniors` table.
1. Otherwise, continue.

#### **Check Covering Employee**
Activated on:
1. After `INSERT` or `UPDATE` on `Managers` table.
1. Trigger is initially deferred.

Actions:
1. Raises exception if employee ID does not exist in either `Juniors`, `Seniors`, or `Managers` table.
1. Otherwise, continue.

#### **Resigned Employee Cleanup**
Activated on:
1. After `INSERT` or `UPDATE OF resignation_date` on `Employees` table.

Actions:
1. If new resignation date is non-null then:
    1. Delete all entries from `Bookings` table where creator is new employee and booking date is after the new resignation date.
    2. Delete all entries from `Attends` table where employee is new employee and the attendance date is after the new resignation date.
1. Continue.

#### **Lock Removed Department Employees Trigger**
Activated on:
1. After `INSERT` or `UPDATE` on `Employees` table.

Actions:
1. If there is no change in department ID, continue.
1. Otherwise, raises exception if the new department has a non-null removal date.
1. Otherwise, continue.

---

### Meeting Rooms

#### **Lock Removed Department Meeting Rooms Trigger**
Activated on:
1. After `INSERT` or `UPDATE` on `Meeting Rooms` table.

Actions:
1. If there is no change in department ID, continue.
1. Otherwise, raises exception if the new department has a non-null removal date.
1. Otherwise, continue.

---

### Bookings

#### **Check Booking Approval**
Activated on:
1. Before `UPDATE` on `Bookings` table.

Actions:
1. Raises exception if old approver ID is non-null.
1. Otherwise, continue.

#### **Check Resignation Booking Create Approve**
Activated on:
1. Before `INSERT` or `UPDATE` on `Bookings` table.

Actions:
1. Raises exception if new booking creator has a non-null resignation date.
1. Raises exception if new booking approver has a non-null resignation date.
1. Otherwise, continue.

#### **Insert Meeting Creator**
Activated on:
1. After `INSERT` or `UPDATE` on `Bookings` table.

Actions:
1. If new creator does not attend new booking, insert record for new creator to attend new booking.
1. Continue.

#### **Meeting Approver Department Check**
Activated on:
1. Before `INSERT` or `UPDATE` on `Bookings` table.

Actions: 
1. Raises exception if new approver's department does not match new meeting room's department.
1. Otherwise, continue.

#### **Booking Date Check**
Activated on:
1. Before `INSERT` or `UPDATE` on `Bookings` table.

Actions:
1. Raises exception if new booking time is before `NOW()`.
1. Otherwise, continue.

#### **Check Health Declaration Booking**
Activated on:
1. Before `INSERT` or `UPDATE` on `Bookings` table.

Actions:
1. Raises exception if new creator has declared their temperature for CURRENT_DATE and the declared temperature is above 37.5.
1. Otherwise, continue.

#### **Approval Only for Future Meetings Trigger**
Activated on:
1. Before `INSERT` or `UPDATE` on `Bookings` table.

Actions:
1. Raises exception if new approver ID is non-null, and the new booking time is in the past.
1. Otherwise, continue.

---

### Attends

#### **Prevent Creator Removal**
Activated on:
1. Before `DELETE` or `UPDATE` on `Attends` table.

Actions:
1. Raises exception if old employee is the creator of the associated booking.
1. Otherwise, continue.

#### **Check Attends Change**
Activated on:
1. Before `INSERT` or `UPDATE` or `DELETE` on `Attends` table.

Actions:
1. {WIP}

#### **Check Resignation Attends**
Activated on:
1. Before `INSERT` or `UPDATE` on `Attends` table.

Actions:
1. Raises exception if new employee has a non-null resignation date.
1. Otherwise, continue.

#### **Check Health Declaration Attends**
Activated on:
1. Before `INSERT` or `UPDATE` on `Attends` table.

Actions:
1. Raises exception if new employee has declared their temperature for CURRENT_DATE and the declared temperature is above 37.5.
1. Otherwise, continue.

#### **Employee Join Only Future Meetings Trigger**
Activated on:
1. Before `INSERT` or `UPDATE` on `Attends` table.

Actions:
1. Raises exception if new booking time is in the past.
1. Otherwise, continue.

#### **Check Meeting Capacity Trigger**
Activated on:
1. Before `INSERT` or `UPDATE` on `Attends` table.

Actions:
1. Raises exception if number of people attending a meeting exceeds the latest relevant capacity of the meeting room declared.
1. Otherwise, continue.

---

### Updates

#### **Check Update Capacity Permissions**
Activated on:
1. Before `INSERT` or `UPDATE` on `Updates` table.

Actions:
1. Raises exception if new manager's department does not match new meeting room's department.
1. Otherwise, continue.

#### **Check Resignation Updates**
Activated on:
1. Before `INSERT` or `UPDATE` on `Updates` table.

Actions:
1. Raises exception if new manager has a non-null resignation date.
1. Otherwise, continue.

#### **Check Future Meetings On Capacity Change Trigger**
Activated on:
1. After `INSERT` or `UPDATE` on `Updates` table.

Actions:
1. Deletes all entries from `Bookings` table where the meeting room used is the new meeting room and the number of referencing entries in the `Attends` table exceeds new capacity.
1. Continue.

---

### Health Declarations

#### **Check Resignation Health Declarations**
Activated on:
1. Before `INSERT` or `UPDATE` on `HealthDelcarations` table.

Actions:
1. Raises exception if new employee has a non-null resignation date.
1. Otherwise, continue.

#### **Health Declaration Date Check**
Activated on:
1. Before `INSERT` or `UPDATE` on `HealthDeclarations` table.

Actions:
1. Raises exception if new date is not CURRENT_DATE.
1. Raises exception if old date is not CURRENT_DATE.
1. Otherwise, continue.
