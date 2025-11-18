# System Tests

This directory contains end-to-end system tests using Capybara that verify complete user workflows.

## Test Files

- `student_workflow_spec.rb` - Tests student journey from browsing courses to RSVPing for sessions
- `teacher_workflow_spec.rb` - Tests teacher creating groups, scheduling sessions, and approving members
- `admin_workflow_spec.rb` - Tests admin dashboard, course management, and platform oversight

## Running System Tests

### Prerequisites

**For JavaScript-enabled tests (with Selenium/Chrome):**
- Google Chrome or Chromium must be installed
- chromedriver must be available on PATH
- Tests marked with `js: true` require a browser

**For non-JS tests:**
- Uses rack_test driver (no browser needed)
- Much faster, suitable for most navigation/form tests

### Running Tests

```bash
# Run all system tests
RAILS_ENV=test bundle exec rspec spec/system

# Run a specific test file
RAILS_ENV=test bundle exec rspec spec/system/student_workflow_spec.rb

# Run with documentation format
RAILS_ENV=test bundle exec rspec spec/system --format documentation
```

### Docker Setup

To run tests in Docker, you need to:

1. Stop the web server (database locking issue)
```bash
docker-compose stop web
```

2. Run tests in a one-off container
```bash
docker-compose run --rm web bundle exec rspec spec/system
```

3. Or install Chrome in the Docker container (add to Dockerfile):
```dockerfile
RUN apt-get update -qq && apt-get install -y \
    chromium \
    chromium-driver
```

## Test Configuration

- **Capybara config**: `spec/support/capybara.rb`
- **Auth helpers**: `spec/support/system_authentication_helpers.rb`
- **OmniAuth mocks**: `spec/support/omniauth.rb`

## Features Tested

### Student Workflow
- Sign in via OAuth
- Browse courses and study groups
- Request to join a group (see pending status)
- Get approved by creator
- View sessions for approved groups
- RSVP to sessions (going/maybe/not_going)
- See capacity limits

### Teacher Workflow
- Create official study groups
- Schedule sessions with all details
- Approve/reject join requests
- Edit and delete sessions
- View group members

### Admin Workflow
- Access admin dashboard
- View platform statistics
- Create/edit/delete courses
- Approve memberships for any group
- Oversee all study groups

## Turbo Frame Testing

Tests marked with `js: true` verify:
- RSVP buttons update without page reload
- Approve/reject buttons work dynamically
- Flash messages appear correctly

## Screenshots on Failure

When a JavaScript test fails:
- A screenshot is automatically saved to `tmp/screenshots/`
- Filename format: `screenshot-{test_file}-{line_number}.png`
- Check these screenshots to debug UI issues

## Tips

- Run non-JS tests first (faster feedback)
- Use `js: true` only when testing dynamic interactions
- Check `tmp/screenshots/` if tests fail mysteriously
- Verify factories are creating valid test data
- Check that routes and views exist for all tested paths
