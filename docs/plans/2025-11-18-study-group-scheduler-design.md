# Study Group Scheduling App - Design Document

**Date:** 2025-11-18
**Status:** Approved

## Overview

A responsive web application built with Ruby on Rails that helps students, teachers, and administrators coordinate study groups across courses. The app handles group creation, session scheduling, approval workflows, attendance tracking, and calendar integration through email.

## User Roles

### Students
- Browse courses and study groups
- Request to join groups (requires approval)
- Create peer-led study groups
- RSVP for individual sessions
- Upload/access study materials
- Track their attendance

### Teachers/TAs
- Create official study groups for their courses
- Approve student join requests
- Schedule sessions
- Track attendance
- Upload resources
- Manage group membership

### Admins
- Create and manage the course catalog
- Assign teachers to courses
- Oversee all study groups across the platform
- Manage user roles/permissions

## Key Features

- OAuth authentication (Google/GitHub) for easy school integration
- Approval-based group membership for quality control
- Per-session RSVP system (join group, then choose which sessions to attend)
- Email notifications with .ics calendar attachments
- Attendance tracking and session notes
- Resource/material sharing per session
- Both teacher-led official groups and student-led peer groups

---

## Data Model

### User
**Attributes:**
- email (string, unique)
- name (string)
- role (enum: student/teacher/admin)
- provider (string: google/github)
- uid (string, unique per provider)

**Associations:**
- has_many :study_group_memberships
- has_many :session_rsvps
- has_many :created_study_groups, class_name: 'StudyGroup', foreign_key: 'creator_id'
- has_many :study_groups, through: :study_group_memberships
- has_many :sessions, through: :session_rsvps

### Course
**Attributes:**
- name (string)
- code (string, e.g., "CS101")
- description (text)
- semester (string)
- year (integer)

**Associations:**
- has_many :study_groups
- has_many :course_teachers
- has_many :teachers, through: :course_teachers, source: :user

**Notes:** Managed by admins only

### StudyGroup
**Attributes:**
- name (string)
- description (text)
- group_type (enum: official/peer)
- status (enum: active/archived)
- creator_id (references users)
- course_id (references courses)

**Associations:**
- belongs_to :course
- belongs_to :creator, class_name: 'User'
- has_many :study_group_memberships
- has_many :sessions
- has_many :members, through: :study_group_memberships, source: :user

### StudyGroupMembership
**Attributes:**
- user_id (references users)
- study_group_id (references study_groups)
- status (enum: pending/approved/rejected)
- requested_at (datetime)
- approved_at (datetime)
- approved_by_id (references users)

**Associations:**
- belongs_to :user
- belongs_to :study_group
- belongs_to :approved_by, class_name: 'User', optional: true

**Notes:** Tracks who's in each group and approval workflow

### Session
**Attributes:**
- title (string)
- date (date)
- start_time (time)
- end_time (time)
- location (string)
- meeting_link (string)
- description (text)
- max_capacity (integer)
- prep_materials (text)
- study_group_id (references study_groups)

**Associations:**
- belongs_to :study_group
- has_many :session_rsvps
- has_many :session_resources
- has_many :attendance_records
- has_many :attendees, through: :session_rsvps, source: :user

### SessionRsvp
**Attributes:**
- user_id (references users)
- session_id (references sessions)
- status (enum: going/maybe/not_going)
- rsvp_at (datetime)

**Associations:**
- belongs_to :user
- belongs_to :session

**Notes:** Tracks per-session attendance commitments

### AttendanceRecord
**Attributes:**
- user_id (references users)
- session_id (references sessions)
- attended (boolean)
- notes (text)
- recorded_by_id (references users)
- recorded_at (datetime)

**Associations:**
- belongs_to :user
- belongs_to :session
- belongs_to :recorded_by, class_name: 'User'

**Notes:** Tracks actual attendance vs. RSVP

### SessionResource
**Attributes:**
- title (string)
- resource_type (enum: prep/notes/recording)
- uploaded_by_id (references users)
- session_id (references sessions)

**Associations:**
- belongs_to :session
- belongs_to :uploaded_by, class_name: 'User'
- has_one_attached :file (ActiveStorage)

---

## Architecture & Technology Stack

### Framework & Libraries
- **Rails 7+** with Hotwire (Turbo + Stimulus) for dynamic interactions
- **OmniAuth** (omniauth-google-oauth2, omniauth-github) for OAuth authentication
- **ActiveStorage** for file uploads (session resources, materials)
- **ActionMailer** with **icalendar gem** for email notifications and .ics calendar attachments
- **Pundit** or **CanCanCan** for authorization (role-based permissions)
- **Tailwind CSS** for responsive styling
- **ViewComponent** for reusable UI components

### Database
- **SQLite** for local development (Rails default)
- Easy migration path to **PostgreSQL** for production

### Development & Deployment
- **Docker** with docker-compose for containerized development and deployment
- Multi-stage Dockerfile for optimized production image
- **RSpec** for testing (models, controllers, system tests)
- **FactoryBot** for test fixtures
- **Faker** for seed data

### Application Architecture
- Traditional Rails MVC with Hotwire for SPA-like UX without heavy JavaScript
- Turbo Frames for partial page updates (RSVP buttons, approval workflows)
- Turbo Streams for real-time updates (new sessions, approval notifications)
- Stimulus controllers for client-side interactivity (form validation, modals)
- Background jobs with **Solid Queue** (Rails 7.1+) or **Sidekiq** for email sending

---

## Core User Workflows

### Student Workflow
1. **Sign in** via Google/GitHub OAuth
2. **Browse courses** - view available courses in the catalog
3. **Discover study groups** - see official (teacher-led) and peer (student-led) groups for a course
4. **Request to join group** - submit join request (goes to group creator for approval)
5. **Get approved** - receive email notification when approved
6. **View sessions** - see all scheduled sessions for groups they're in
7. **RSVP for sessions** - choose which sessions to attend (updates capacity count)
8. **Receive calendar invite** - get email with .ics attachment for each RSVP'd session
9. **Access resources** - view prep materials before session, notes/recordings after
10. **Create peer group** (optional) - students can start their own study groups and invite peers

### Teacher Workflow
1. **Sign in** via OAuth
2. **View assigned courses** - see courses they're teaching (set by admin)
3. **Create study group** - make official study group for a course
4. **Schedule sessions** - add multiple sessions with dates, times, locations, capacity
5. **Review join requests** - approve/reject students wanting to join
6. **Manage sessions** - upload prep materials, update details, add meeting links
7. **Track attendance** - mark who actually attended each session
8. **Upload post-session resources** - share notes, recordings, additional materials

### Admin Workflow
1. **Manage courses** - create/edit/archive courses in the catalog
2. **Assign teachers** - link teachers to their courses
3. **Oversee all groups** - view and manage any study group across the platform
4. **Manage users** - handle role assignments, resolve issues

---

## Email Notifications & Calendar Integration

### Email Notification Types

**1. Join Request Submitted** (to group creator)
- Subject: "New join request for [Group Name]"
- Content: Student name, link to approve/reject

**2. Join Request Approved** (to student)
- Subject: "You've been added to [Group Name]"
- Content: Group details, upcoming sessions, link to view sessions

**3. Join Request Rejected** (to student)
- Subject: "Update on your request for [Group Name]"
- Content: Polite message, suggest other groups

**4. Session RSVP Confirmation** (to student)
- Subject: "[Session Title] - [Date]"
- Content: Session details, location/link, prep materials
- **Attachment: .ics calendar file** (can import to any calendar app)

**5. Session Reminder** (to all RSVP'd students, 24h before)
- Subject: "Reminder: [Session Title] tomorrow"
- Content: Session details, meeting link
- Attachment: .ics file again (in case they deleted it)

**6. Session Updates** (when details change)
- Subject: "[Session Title] has been updated"
- Content: What changed, updated details
- Attachment: Updated .ics file

**7. New Session Added** (to all group members)
- Subject: "New session scheduled for [Group Name]"
- Content: Session details, RSVP link

### Calendar File (.ics) Details
- Generated using `icalendar` gem
- Includes: event title, start/end time, location, description, meeting link
- ORGANIZER field set to group creator
- ATTENDEE field includes student email
- Supports "Add to Calendar" for Google, Outlook, Apple Calendar, etc.

### Email Delivery
- Background jobs via Solid Queue (async sending, don't block requests)
- ActionMailer with configured SMTP (SendGrid, Postmark, or AWS SES for production)
- Email templates use Rails layouts for consistent branding

---

## Error Handling & Edge Cases

### Capacity Management
- Sessions have `max_capacity` attribute
- RSVP button disabled when session is full (via Turbo Frame update)
- If student RSVPs "not_going", spot opens up automatically
- Display "X/Y spots filled" on session cards
- Teachers can override capacity if needed (admin permission)

### Approval Workflow Edge Cases
- Students can't see pending join requests from others (privacy)
- Group creator can't accidentally approve same request twice (idempotent)
- If group is archived, new join requests are blocked
- When membership is rejected, student can request again after 7 days (prevent spam)

### Calendar/Email Edge Cases
- If email fails to send, log error and retry via background job (3 attempts)
- If session is cancelled, send cancellation email with CANCELLED .ics status
- If student updates RSVP from "going" to "not going", send updated .ics with DECLINED status
- Handle timezone properly - store in UTC, display in user's local timezone

### Concurrent Access
- Use database transactions for RSVP creation to prevent overbooking
- Optimistic locking on sessions to prevent conflicting updates
- Flash messages for "session is now full" if race condition occurs

### Data Validation
- Session end_time must be after start_time
- Session date must be in the future (when creating)
- Email addresses validated via OAuth provider
- File upload size limits (max 10MB per resource)

### Permissions & Authorization
- Students can only RSVP to sessions in groups they're approved members of
- Only group creator or admins can approve memberships
- Only teachers assigned to a course can create official groups for it
- Students can only edit/delete their own peer groups

---

## Testing Strategy

### Unit Tests (Models)
- Validations: presence, format, custom validations (dates, capacity)
- Associations: belongs_to, has_many, dependent destroy behavior
- Scopes: active groups, upcoming sessions, pending approvals
- Methods: `full?` on Session, `can_rsvp?` on User, `approve!` on Membership
- Edge cases: timezone conversions, capacity calculations, approval state transitions

### Controller Tests
- Authentication: OAuth callback handling, session management
- Authorization: Pundit policies for each action (who can create/edit/delete)
- CRUD operations: create study group, schedule session, approve membership
- Error responses: proper status codes, flash messages
- Redirects: after successful actions

### Integration Tests
- Complete workflows: student joins group → RSVP → receives email
- Multi-user scenarios: teacher creates group, students request, teacher approves
- Background jobs: email delivery, reminder scheduling
- File uploads: session resources via ActiveStorage

### System Tests (Browser/E2E)
- Full user journeys with Capybara
- Student: browse → request join → get approved → RSVP → view resources
- Teacher: create group → schedule sessions → approve requests → track attendance
- Admin: create course → assign teacher → oversee groups
- Responsive design: test on mobile viewport sizes
- Turbo interactions: RSVP buttons, approval workflows without page reload

### Email Tests
- Mailer specs: correct recipient, subject, body content
- .ics attachment present and valid format
- Preview emails in development via `/rails/mailers`

### Test Data
- FactoryBot for creating test objects (users, courses, groups, sessions)
- Faker for realistic fake data (names, emails, descriptions)
- Seed file for local development data

### CI/CD
- Run full test suite on every commit
- Code coverage reporting (SimpleCov, aim for 90%+)
- Linting with RuboCop (Rails style guide)

---

## Next Steps

1. Set up Rails application with Docker
2. Configure OAuth authentication
3. Create database migrations for core models
4. Implement authorization with Pundit
5. Build core CRUD functionality
6. Implement Hotwire interactions
7. Set up email system with .ics generation
8. Write comprehensive test suite
9. Deploy to production environment
