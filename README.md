# Study Group Scheduler 📚

A Rails 7 web application for organizing and managing study groups, sessions, and RSVPs with OAuth authentication, email notifications with calendar integration, and admin dashboard.

## Summary

This Study Group Scheduler enables students, teachers, and administrators to coordinate study sessions across academic courses. The app features a complete approval workflow for group membership, session scheduling with capacity management, RSVP system with email notifications including .ics calendar attachments, and an admin dashboard for platform oversight.

**Key Features:**
- 🔐 OAuth authentication (Google/GitHub) with role-based access
- 👥 Study group creation (official teacher-led & peer student-led)
- 📅 Session scheduling with date/time/location/capacity management
- ✅ RSVP system (Going/Maybe/Not Going) with capacity tracking
- 📧 Email notifications with .ics calendar attachments
- 🔄 Background job processing for email delivery
- 👨‍💼 Admin dashboard with platform statistics and management tools
- 📱 Responsive design with Tailwind CSS

## How to Use

### Development Setup

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd study-group-scheduler
   ```

2. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Edit .env with your Google OAuth credentials
   ```

3. **Docker Development**
   ```bash
   # Start all services (web + background worker)
   docker-compose up -d
   
   # Setup database
   docker-compose run --rm web bundle exec rails db:setup
   
   # View logs
   docker-compose logs -f
   ```

4. **Access Application**
   - Web app: http://localhost:3000
   - Email previews: http://localhost:3000/rails/mailers

### Production Deployment

1. **Setup Environment**
   ```bash
   cp .env.production.example .env.production
   # Configure production values (see docs/DEPLOYMENT.md)
   ```

2. **Generate Secret Key**
   ```bash
   docker run --rm ruby:3.2.2-slim bash -c "gem install rails && rails secret"
   # Add to .env.production as SECRET_KEY_BASE
   ```

3. **Deploy with Docker**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

### User Workflows

**Students:**
1. Sign in via Google OAuth → Browse courses → View study groups
2. Request to join group → Wait for approval from creator
3. Once approved: View sessions → RSVP (Going/Maybe/Not Going)
4. Receive email confirmations with calendar attachments

**Teachers:**
1. Create official study groups for courses
2. Schedule sessions with details (date, time, location, capacity)
3. Approve/reject student join requests
4. Track attendance and manage group members

**Admins:**
1. Access admin dashboard for platform statistics
2. Create/edit/delete courses in the catalog  
3. Oversee all study groups and approve memberships
4. Manage user roles and platform oversight

### Key Commands

```bash
# Development
docker-compose up -d                    # Start services
docker-compose run --rm web rails c    # Rails console
docker-compose run --rm web bundle exec rspec  # Run tests

# Production  
docker-compose -f docker-compose.prod.yml up -d        # Deploy
docker-compose -f docker-compose.prod.yml logs -f      # View logs
docker-compose -f docker-compose.prod.yml exec web bundle exec rails db:migrate  # Migrate
```

## Tech Stack & Architecture

### Framework & Core Technologies
- **Ruby 3.2.2** with **Rails 7.1+**
- **Hotwire (Turbo + Stimulus)** for dynamic interactions without heavy JavaScript
- **Tailwind CSS** for responsive UI styling
- **Docker** with multi-stage builds for development and production

### Authentication & Authorization
- **OmniAuth** with Google OAuth2 provider
- **Pundit** for role-based authorization policies
- Three user roles: Student, Teacher, Admin

### Database & Models
- **SQLite** for development/test (simple setup)
- **PostgreSQL** for production (robust, scalable)
- Rich data model with 9 core models:
  - `User` (OAuth authentication, roles)
  - `Course` (admin-managed course catalog)
  - `StudyGroup` (official vs peer groups)
  - `StudyGroupMembership` (approval workflow)
  - `Session` (study sessions with capacity)
  - `SessionRsvp` (RSVP tracking)
  - `AttendanceRecord` (actual vs RSVP tracking)
  - `SessionResource` (file attachments via ActiveStorage)

### Email & Calendar Integration
- **ActionMailer** with **icalendar gem** for .ics calendar file generation
- **Solid Queue** for background job processing (Rails 7.1 default)
- Email notifications for:
  - Join request submitted → Group creator
  - Join request approved/rejected → Student  
  - RSVP confirmation with .ics attachment → Student
  - Session reminders (24h before) → All "going" RSVPs
  - New session announcements → All group members

### Testing & Quality
- **RSpec** with comprehensive test suite (90%+ coverage)
- **FactoryBot** for test data generation
- **Capybara + Selenium** for system/integration tests
- **SimpleCov** for code coverage reporting
- **Shoulda Matchers** for model testing
- **Pundit Matchers** for authorization testing

### Development Workflow
- **TDD (Test-Driven Development)** approach
- Request specs, model specs, policy specs, system specs
- Email preview system for development
- Docker-based development environment
- Background job processing in development

### Production Architecture
```
┌─────────────────┐    ┌─────────────────┐
│   nginx/proxy   │────│   Rails Web     │
│   (optional)    │    │   (Puma server) │
└─────────────────┘    └─────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  PostgreSQL     │  │  Solid Queue    │  │  PostgreSQL     │
│  (App Data)     │  │  Worker         │  │  (Queue Data)   │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Security Features
- OAuth-only authentication (no passwords stored)
- Role-based authorization with Pundit policies
- CSRF protection enabled
- Non-root Docker container user
- Environment variable configuration
- SQL injection prevention via ActiveRecord
- XSS protection via Rails defaults

### Deployment Options
- **Development:** Docker Compose with SQLite
- **Production:** Docker Compose with PostgreSQL
- **Monitoring:** Health check endpoints (`/up`)
- **Scaling:** Separate web and worker containers
- **SSL:** Force HTTPS in production environment

For detailed deployment instructions, see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

---

*Built with ❤️ using Rails 7, Docker, and modern web development practices*
