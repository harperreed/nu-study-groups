# Study Group Scheduler Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Rails-based study group scheduling app with OAuth auth, approval workflows, session RSVPs, and email calendar integration.

**Architecture:** Traditional Rails 7 MVC with Hotwire (Turbo + Stimulus), OAuth authentication, Pundit authorization, Docker containerization, and background job processing for emails.

**Tech Stack:** Rails 7+, SQLite → PostgreSQL, OmniAuth (Google/GitHub), Pundit, Hotwire, Tailwind CSS, RSpec, FactoryBot, icalendar gem, Docker

---

## Task 1: Initialize Rails Application with Docker

**Files:**
- Create: `Dockerfile`
- Create: `docker-compose.yml`
- Create: `.dockerignore`
- Create: `Gemfile`
- Create: `.ruby-version`

**Step 1: Create Ruby version file**

```bash
echo "3.2.2" > .ruby-version
```

**Step 2: Create initial Gemfile**

Create `Gemfile`:

```ruby
source 'https://rubygems.org'
ruby '3.2.2'

gem 'rails', '~> 7.1.0'
```

**Step 3: Create Dockerfile**

Create `Dockerfile`:

```dockerfile
# ABOUTME: Multi-stage Dockerfile for Rails app with development and production stages
# ABOUTME: Uses official Ruby image and installs Rails dependencies
FROM ruby:3.2.2-slim as base

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install yarn
RUN npm install -g yarn

WORKDIR /app

# Development stage
FROM base as development

COPY Gemfile* ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

# Production stage
FROM base as production

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

COPY Gemfile* ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

COPY . .

RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
```

**Step 4: Create docker-compose.yml**

Create `docker-compose.yml`:

```yaml
# ABOUTME: Docker Compose configuration for development environment
# ABOUTME: Runs Rails app with SQLite, exposes port 3000
version: '3.8'

services:
  web:
    build:
      context: .
      target: development
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"
    volumes:
      - .:/app
      - bundle:/usr/local/bundle
    ports:
      - "3000:3000"
    environment:
      - RAILS_ENV=development
    stdin_open: true
    tty: true

volumes:
  bundle:
```

**Step 5: Create .dockerignore**

Create `.dockerignore`:

```
.git
.gitignore
tmp/
log/
.env
*.log
.DS_Store
node_modules/
```

**Step 6: Initialize Rails app in Docker**

Run:
```bash
docker-compose run --rm web bash -c "gem install rails -v '~> 7.1.0' && rails new . --force --skip-bundle --database=sqlite3 --css=tailwind --javascript=importmap"
```

Expected: Rails app scaffolding created

**Step 7: Build Docker image**

Run:
```bash
docker-compose build
```

Expected: Docker image builds successfully

**Step 8: Start Rails server**

Run:
```bash
docker-compose up
```

Expected: Rails server starts on http://localhost:3000

**Step 9: Commit**

```bash
git add .
git commit -m "feat: initialize Rails 7 app with Docker and Tailwind CSS

- Add Dockerfile with development and production stages
- Add docker-compose.yml for local development
- Initialize Rails 7.1 with SQLite, Tailwind CSS, and importmap
- Configure .dockerignore

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Configure RSpec and Testing Gems

**Files:**
- Modify: `Gemfile`
- Create: `spec/spec_helper.rb`
- Create: `spec/rails_helper.rb`
- Create: `.rspec`

**Step 1: Add testing gems to Gemfile**

Modify `Gemfile`, add to the bottom:

```ruby
group :development, :test do
  gem 'rspec-rails', '~> 6.1.0'
  gem 'factory_bot_rails', '~> 6.4.0'
  gem 'faker', '~> 3.2.0'
  gem 'debug', platforms: %i[mri windows]
end

group :test do
  gem 'capybara', '~> 3.39.0'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 6.0.0'
  gem 'simplecov', require: false
end
```

**Step 2: Install gems**

Run:
```bash
docker-compose run --rm web bundle install
```

Expected: Gems installed successfully

**Step 3: Initialize RSpec**

Run:
```bash
docker-compose run --rm web rails generate rspec:install
```

Expected: RSpec files created (spec/spec_helper.rb, spec/rails_helper.rb, .rspec)

**Step 4: Configure SimpleCov in spec/spec_helper.rb**

Modify `spec/spec_helper.rb`, add at the very top:

```ruby
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/config/'
end
```

**Step 5: Configure shoulda-matchers in spec/rails_helper.rb**

Modify `spec/rails_helper.rb`, add at the bottom before `end`:

```ruby
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

**Step 6: Run RSpec to verify setup**

Run:
```bash
docker-compose run --rm web bundle exec rspec
```

Expected: "0 examples, 0 failures"

**Step 7: Commit**

```bash
git add .
git commit -m "test: configure RSpec with FactoryBot, Faker, and SimpleCov

- Add RSpec, FactoryBot, Faker to Gemfile
- Add Capybara and Selenium for system tests
- Configure SimpleCov for code coverage
- Configure shoulda-matchers for model testing

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: Create User Model with OAuth Support

**Files:**
- Create: `spec/models/user_spec.rb`
- Create: `db/migrate/TIMESTAMP_create_users.rb`
- Create: `app/models/user.rb`

**Step 1: Write failing test for User model**

Create `spec/models/user_spec.rb`:

```ruby
# ABOUTME: Test suite for User model covering validations, associations, and OAuth authentication
# ABOUTME: Tests user roles (student, teacher, admin) and OAuth provider integration
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:uid) }
    it { should validate_uniqueness_of(:email) }

    it 'validates uniqueness of uid scoped to provider' do
      user = User.create!(
        email: 'test@example.com',
        name: 'Test User',
        provider: 'google',
        uid: '12345',
        role: 'student'
      )

      duplicate = User.new(
        email: 'other@example.com',
        name: 'Other User',
        provider: 'google',
        uid: '12345',
        role: 'student'
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uid]).to include('has already been taken')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(student: 0, teacher: 1, admin: 2) }
  end

  describe '.from_omniauth' do
    let(:auth_hash) do
      {
        'provider' => 'google',
        'uid' => '12345',
        'info' => {
          'email' => 'student@example.com',
          'name' => 'Jane Student'
        }
      }
    end

    context 'when user does not exist' do
      it 'creates a new user with student role by default' do
        expect {
          User.from_omniauth(auth_hash)
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq('student@example.com')
        expect(user.name).to eq('Jane Student')
        expect(user.provider).to eq('google')
        expect(user.uid).to eq('12345')
        expect(user.role).to eq('student')
      end
    end

    context 'when user already exists' do
      let!(:existing_user) do
        User.create!(
          email: 'student@example.com',
          name: 'Jane Student',
          provider: 'google',
          uid: '12345',
          role: 'student'
        )
      end

      it 'returns the existing user' do
        expect {
          User.from_omniauth(auth_hash)
        }.not_to change(User, :count)

        user = User.from_omniauth(auth_hash)
        expect(user.id).to eq(existing_user.id)
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb
```

Expected: FAIL with "uninitialized constant User"

**Step 3: Create User migration**

Run:
```bash
docker-compose run --rm web rails generate migration CreateUsers
```

Modify `db/migrate/TIMESTAMP_create_users.rb`:

```ruby
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :provider, null: false
      t.string :uid, null: false
      t.integer :role, default: 0, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, [:provider, :uid], unique: true
  end
end
```

**Step 4: Run migration**

Run:
```bash
docker-compose run --rm web rails db:migrate
```

Expected: Migration runs successfully

**Step 5: Create User model**

Create `app/models/user.rb`:

```ruby
# ABOUTME: User model for authentication via OAuth (Google/GitHub)
# ABOUTME: Supports three roles: student, teacher, admin with enum
class User < ApplicationRecord
  enum role: { student: 0, teacher: 1, admin: 2 }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  def self.from_omniauth(auth)
    where(provider: auth['provider'], uid: auth['uid']).first_or_create do |user|
      user.email = auth['info']['email']
      user.name = auth['info']['name']
      user.role = :student
    end
  end
end
```

**Step 6: Run test to verify it passes**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb
```

Expected: All tests pass

**Step 7: Commit**

```bash
git add .
git commit -m "feat: add User model with OAuth support and role enum

- Create users table with email, name, provider, uid, role
- Add unique indexes on email and provider+uid
- Implement User.from_omniauth for OAuth authentication
- Support three roles: student, teacher, admin
- Add comprehensive model tests

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Configure OmniAuth for Google OAuth

**Files:**
- Modify: `Gemfile`
- Create: `config/initializers/omniauth.rb`
- Create: `.env.example`
- Modify: `Gemfile` (add dotenv-rails)

**Step 1: Add OmniAuth gems to Gemfile**

Modify `Gemfile`, add:

```ruby
gem 'omniauth-google-oauth2', '~> 1.1.0'
gem 'omniauth-rails_csrf_protection', '~> 1.0.0'

group :development, :test do
  gem 'dotenv-rails', '~> 2.8.0'
end
```

**Step 2: Install gems**

Run:
```bash
docker-compose run --rm web bundle install
```

Expected: Gems installed successfully

**Step 3: Create .env.example file**

Create `.env.example`:

```
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
```

**Step 4: Create .env file (not committed)**

Run:
```bash
cp .env.example .env
echo ".env" >> .gitignore
```

**Step 5: Create OmniAuth initializer**

Create `config/initializers/omniauth.rb`:

```ruby
# ABOUTME: OmniAuth configuration for Google OAuth authentication
# ABOUTME: Uses environment variables for client credentials, requires CSRF protection
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV['GOOGLE_CLIENT_ID'],
           ENV['GOOGLE_CLIENT_SECRET'],
           {
             scope: 'email, profile',
             prompt: 'select_account',
             image_aspect_ratio: 'square',
             image_size: 50
           }
end

OmniAuth.config.allowed_request_methods = [:post, :get]
```

**Step 6: Update docker-compose.yml to load .env**

Modify `docker-compose.yml`, update `web` service:

```yaml
  web:
    build:
      context: .
      target: development
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"
    volumes:
      - .:/app
      - bundle:/usr/local/bundle
    ports:
      - "3000:3000"
    env_file:
      - .env
    environment:
      - RAILS_ENV=development
    stdin_open: true
    tty: true
```

**Step 7: Restart Docker to load env vars**

Run:
```bash
docker-compose down
docker-compose up -d
```

Expected: Container restarts with env vars loaded

**Step 8: Commit**

```bash
git add .
git commit -m "feat: configure OmniAuth with Google OAuth2 provider

- Add omniauth-google-oauth2 and omniauth-rails_csrf_protection gems
- Create OmniAuth initializer with Google provider
- Add dotenv-rails for environment variable management
- Create .env.example template for credentials
- Update docker-compose.yml to load .env file

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 5: Implement Sessions Controller for OAuth

**Files:**
- Create: `spec/requests/sessions_spec.rb`
- Create: `app/controllers/sessions_controller.rb`
- Modify: `config/routes.rb`
- Create: `app/controllers/application_controller.rb` (modify)

**Step 1: Write failing test for SessionsController**

Create `spec/requests/sessions_spec.rb`:

```ruby
# ABOUTME: Request specs for OAuth authentication flow
# ABOUTME: Tests login, logout, and OAuth callback handling
require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "GET /auth/google_oauth2/callback" do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '12345',
        info: {
          email: 'student@example.com',
          name: 'Jane Student'
        }
      })
    end

    after do
      OmniAuth.config.test_mode = false
    end

    it 'creates a new user and logs them in' do
      expect {
        get '/auth/google_oauth2/callback'
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to eq(User.last.id)
    end

    it 'logs in an existing user' do
      user = User.create!(
        email: 'student@example.com',
        name: 'Jane Student',
        provider: 'google_oauth2',
        uid: '12345',
        role: 'student'
      )

      expect {
        get '/auth/google_oauth2/callback'
      }.not_to change(User, :count)

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to eq(user.id)
    end
  end

  describe "DELETE /logout" do
    let(:user) { User.create!(email: 'test@example.com', name: 'Test', provider: 'google_oauth2', uid: '123', role: 'student') }

    it 'logs out the user and clears the session' do
      delete '/logout', session: { user_id: user.id }

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_nil
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/requests/sessions_spec.rb
```

Expected: FAIL with routing errors

**Step 3: Add routes**

Modify `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # OAuth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
```

**Step 4: Create SessionsController**

Create `app/controllers/sessions_controller.rb`:

```ruby
# ABOUTME: Handles OAuth authentication flow for login and logout
# ABOUTME: Creates or finds user from OAuth callback and manages session
class SessionsController < ApplicationController
  def create
    user = User.from_omniauth(request.env['omniauth.auth'])

    if user.persisted?
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Signed in successfully!'
    else
      redirect_to root_path, alert: 'Authentication failed, please try again.'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Signed out successfully!'
  end
end
```

**Step 5: Add current_user helper to ApplicationController**

Modify `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to root_path, alert: 'You must be signed in to access this page.'
    end
  end
end
```

**Step 6: Create placeholder HomeController**

Run:
```bash
docker-compose run --rm web rails generate controller Home index --skip-routes
```

**Step 7: Run test to verify it passes**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/requests/sessions_spec.rb
```

Expected: All tests pass

**Step 8: Commit**

```bash
git add .
git commit -m "feat: implement OAuth authentication with SessionsController

- Add SessionsController with create and destroy actions
- Implement OAuth callback handling via User.from_omniauth
- Add session management in ApplicationController
- Add current_user and authenticate_user! helper methods
- Create routes for OAuth callback and logout
- Add comprehensive request specs for auth flow

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 6: Create Course Model

**Files:**
- Create: `spec/models/course_spec.rb`
- Create: `db/migrate/TIMESTAMP_create_courses.rb`
- Create: `app/models/course.rb`
- Create: `spec/factories/users.rb`
- Create: `spec/factories/courses.rb`

**Step 1: Create User factory**

Create `spec/factories/users.rb`:

```ruby
# ABOUTME: FactoryBot factory for creating test users
# ABOUTME: Supports all three roles with realistic fake data
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    provider { 'google_oauth2' }
    sequence(:uid) { |n| "uid#{n}" }
    role { :student }

    trait :teacher do
      role { :teacher }
    end

    trait :admin do
      role { :admin }
    end
  end
end
```

**Step 2: Write failing test for Course model**

Create `spec/models/course_spec.rb`:

```ruby
# ABOUTME: Test suite for Course model covering validations and associations
# ABOUTME: Tests course-teacher relationships and basic CRUD operations
require 'rails_helper'

RSpec.describe Course, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code).scoped_to(:semester, :year) }
  end

  describe 'associations' do
    it { should have_many(:study_groups) }
    it { should have_many(:course_teachers).dependent(:destroy) }
    it { should have_many(:teachers).through(:course_teachers).source(:user) }
  end

  describe 'scopes' do
    let!(:current_course) { create(:course, semester: 'Fall', year: 2025) }
    let!(:past_course) { create(:course, semester: 'Spring', year: 2024) }

    it 'orders by year and semester by default' do
      courses = Course.all
      expect(courses.first).to eq(current_course)
      expect(courses.last).to eq(past_course)
    end
  end
end
```

**Step 3: Create Course factory**

Create `spec/factories/courses.rb`:

```ruby
# ABOUTME: FactoryBot factory for creating test courses
# ABOUTME: Generates realistic course codes, names, and semester/year data
FactoryBot.define do
  factory :course do
    sequence(:code) { |n| "CS#{100 + n}" }
    name { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph }
    semester { ['Fall', 'Spring', 'Summer'].sample }
    year { Time.current.year }
  end
end
```

**Step 4: Run test to verify it fails**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/course_spec.rb
```

Expected: FAIL with "uninitialized constant Course"

**Step 5: Create Course migration**

Run:
```bash
docker-compose run --rm web rails generate migration CreateCourses
```

Modify `db/migrate/TIMESTAMP_create_courses.rb`:

```ruby
class CreateCourses < ActiveRecord::Migration[7.1]
  def change
    create_table :courses do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :semester, null: false
      t.integer :year, null: false

      t.timestamps
    end

    add_index :courses, [:code, :semester, :year], unique: true
  end
end
```

**Step 6: Create CourseTeacher join table migration**

Run:
```bash
docker-compose run --rm web rails generate migration CreateCourseTeachers
```

Modify `db/migrate/TIMESTAMP_create_course_teachers.rb`:

```ruby
class CreateCourseTeachers < ActiveRecord::Migration[7.1]
  def change
    create_table :course_teachers do |t|
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :course_teachers, [:course_id, :user_id], unique: true
  end
end
```

**Step 7: Run migrations**

Run:
```bash
docker-compose run --rm web rails db:migrate
```

Expected: Migrations run successfully

**Step 8: Create Course model**

Create `app/models/course.rb`:

```ruby
# ABOUTME: Course model representing academic courses with assigned teachers
# ABOUTME: Courses are identified by code+semester+year and managed by admins
class Course < ApplicationRecord
  has_many :study_groups, dependent: :destroy
  has_many :course_teachers, dependent: :destroy
  has_many :teachers, through: :course_teachers, source: :user

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: [:semester, :year] }

  default_scope { order(year: :desc, semester: :desc) }
end
```

**Step 9: Create CourseTeacher model**

Create `app/models/course_teacher.rb`:

```ruby
# ABOUTME: Join model connecting courses to their assigned teachers
# ABOUTME: Ensures a teacher can only be assigned once per course
class CourseTeacher < ApplicationRecord
  belongs_to :course
  belongs_to :user

  validates :user_id, uniqueness: { scope: :course_id }
end
```

**Step 10: Update User model with course associations**

Modify `app/models/user.rb`, add:

```ruby
  has_many :course_teachers, dependent: :destroy
  has_many :teaching_courses, through: :course_teachers, source: :course
```

**Step 11: Run test to verify it passes**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/course_spec.rb
```

Expected: All tests pass

**Step 12: Commit**

```bash
git add .
git commit -m "feat: add Course model with teacher associations

- Create courses table with name, code, semester, year
- Add unique index on code+semester+year
- Create course_teachers join table for teacher assignments
- Implement Course and CourseTeacher models
- Add has_many :teaching_courses to User model
- Create FactoryBot factories for users and courses
- Add comprehensive model tests

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 7: Create StudyGroup and StudyGroupMembership Models

**Files:**
- Create: `spec/models/study_group_spec.rb`
- Create: `spec/models/study_group_membership_spec.rb`
- Create: `db/migrate/TIMESTAMP_create_study_groups.rb`
- Create: `db/migrate/TIMESTAMP_create_study_group_memberships.rb`
- Create: `app/models/study_group.rb`
- Create: `app/models/study_group_membership.rb`
- Create: `spec/factories/study_groups.rb`

**Step 1: Write failing test for StudyGroup model**

Create `spec/models/study_group_spec.rb`:

```ruby
# ABOUTME: Test suite for StudyGroup model covering validations, associations, and group types
# ABOUTME: Tests official vs peer groups and creator permissions
require 'rails_helper'

RSpec.describe StudyGroup, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:group_type) }
  end

  describe 'associations' do
    it { should belong_to(:course) }
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:study_group_memberships).dependent(:destroy) }
    it { should have_many(:members).through(:study_group_memberships).source(:user) }
    it { should have_many(:sessions).dependent(:destroy) }
  end

  describe 'enums' do
    it { should define_enum_for(:group_type).with_values(official: 0, peer: 1) }
    it { should define_enum_for(:status).with_values(active: 0, archived: 1) }
  end

  describe 'scopes' do
    let(:course) { create(:course) }
    let!(:active_group) { create(:study_group, course: course, status: :active) }
    let!(:archived_group) { create(:study_group, course: course, status: :archived) }

    it '.active returns only active groups' do
      expect(StudyGroup.active).to include(active_group)
      expect(StudyGroup.active).not_to include(archived_group)
    end
  end
end
```

**Step 2: Write failing test for StudyGroupMembership model**

Create `spec/models/study_group_membership_spec.rb`:

```ruby
# ABOUTME: Test suite for StudyGroupMembership model covering approval workflow
# ABOUTME: Tests pending, approved, rejected statuses and uniqueness constraints
require 'rails_helper'

RSpec.describe StudyGroupMembership, type: :model do
  describe 'validations' do
    subject { build(:study_group_membership) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:study_group_id) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:study_group) }
    it { should belong_to(:approved_by).class_name('User').optional }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, approved: 1, rejected: 2) }
  end

  describe '#approve!' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user) }
    let(:study_group) { create(:study_group) }
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :pending) }

    it 'changes status to approved and records approver' do
      membership.approve!(teacher)

      expect(membership.reload.status).to eq('approved')
      expect(membership.approved_by).to eq(teacher)
      expect(membership.approved_at).to be_present
    end
  end

  describe '#reject!' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user) }
    let(:study_group) { create(:study_group) }
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :pending) }

    it 'changes status to rejected' do
      membership.reject!(teacher)

      expect(membership.reload.status).to eq('rejected')
      expect(membership.approved_by).to eq(teacher)
    end
  end
end
```

**Step 3: Create StudyGroup factory**

Create `spec/factories/study_groups.rb`:

```ruby
# ABOUTME: FactoryBot factory for creating test study groups
# ABOUTME: Supports official and peer group types with realistic data
FactoryBot.define do
  factory :study_group do
    association :course
    association :creator, factory: [:user, :teacher]
    name { Faker::Educator.subject }
    description { Faker::Lorem.paragraph }
    group_type { :official }
    status { :active }

    trait :peer do
      group_type { :peer }
      association :creator, factory: :user
    end

    trait :archived do
      status { :archived }
    end
  end
end
```

**Step 4: Create StudyGroupMembership factory**

Create `spec/factories/study_group_memberships.rb`:

```ruby
# ABOUTME: FactoryBot factory for creating test study group memberships
# ABOUTME: Supports pending, approved, and rejected states
FactoryBot.define do
  factory :study_group_membership do
    association :user
    association :study_group
    status { :pending }
    requested_at { Time.current }

    trait :approved do
      status { :approved }
      approved_at { Time.current }
      association :approved_by, factory: [:user, :teacher]
    end

    trait :rejected do
      status { :rejected }
      association :approved_by, factory: [:user, :teacher]
    end
  end
end
```

**Step 5: Run tests to verify they fail**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/study_group_spec.rb spec/models/study_group_membership_spec.rb
```

Expected: FAIL with "uninitialized constant StudyGroup"

**Step 6: Create StudyGroup migration**

Run:
```bash
docker-compose run --rm web rails generate migration CreateStudyGroups
```

Modify `db/migrate/TIMESTAMP_create_study_groups.rb`:

```ruby
class CreateStudyGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :study_groups do |t|
      t.string :name, null: false
      t.text :description
      t.integer :group_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.references :course, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :study_groups, :group_type
    add_index :study_groups, :status
  end
end
```

**Step 7: Create StudyGroupMembership migration**

Run:
```bash
docker-compose run --rm web rails generate migration CreateStudyGroupMemberships
```

Modify `db/migrate/TIMESTAMP_create_study_group_memberships.rb`:

```ruby
class CreateStudyGroupMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :study_group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_group, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :requested_at, null: false
      t.datetime :approved_at
      t.references :approved_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :study_group_memberships, [:user_id, :study_group_id], unique: true
    add_index :study_group_memberships, :status
  end
end
```

**Step 8: Run migrations**

Run:
```bash
docker-compose run --rm web rails db:migrate
```

Expected: Migrations run successfully

**Step 9: Create StudyGroup model**

Create `app/models/study_group.rb`:

```ruby
# ABOUTME: StudyGroup model for organizing study sessions within courses
# ABOUTME: Supports official (teacher-created) and peer (student-created) groups
class StudyGroup < ApplicationRecord
  belongs_to :course
  belongs_to :creator, class_name: 'User'

  has_many :study_group_memberships, dependent: :destroy
  has_many :members, through: :study_group_memberships, source: :user
  has_many :sessions, dependent: :destroy

  enum group_type: { official: 0, peer: 1 }
  enum status: { active: 0, archived: 1 }

  validates :name, presence: true
  validates :group_type, presence: true

  scope :active, -> { where(status: :active) }
end
```

**Step 10: Create StudyGroupMembership model**

Create `app/models/study_group_membership.rb`:

```ruby
# ABOUTME: Join model for study group membership with approval workflow
# ABOUTME: Tracks pending, approved, and rejected membership requests
class StudyGroupMembership < ApplicationRecord
  belongs_to :user
  belongs_to :study_group
  belongs_to :approved_by, class_name: 'User', optional: true

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :user_id, uniqueness: { scope: :study_group_id }

  def approve!(approver)
    update!(
      status: :approved,
      approved_by: approver,
      approved_at: Time.current
    )
  end

  def reject!(approver)
    update!(
      status: :rejected,
      approved_by: approver
    )
  end
end
```

**Step 11: Update User model with study group associations**

Modify `app/models/user.rb`, add:

```ruby
  has_many :created_study_groups, class_name: 'StudyGroup', foreign_key: 'creator_id', dependent: :destroy
  has_many :study_group_memberships, dependent: :destroy
  has_many :study_groups, through: :study_group_memberships
```

**Step 12: Run tests to verify they pass**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/study_group_spec.rb spec/models/study_group_membership_spec.rb
```

Expected: All tests pass

**Step 13: Commit**

```bash
git add .
git commit -m "feat: add StudyGroup and StudyGroupMembership models

- Create study_groups table with course and creator references
- Support official and peer group types via enum
- Add active/archived status enum
- Create study_group_memberships join table with approval workflow
- Implement approve! and reject! methods on membership
- Add factories for study groups and memberships
- Add comprehensive model tests for both models

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 8: Create Session and SessionRsvp Models

**Files:**
- Create: `spec/models/session_spec.rb`
- Create: `spec/models/session_rsvp_spec.rb`
- Create: `db/migrate/TIMESTAMP_create_sessions.rb`
- Create: `db/migrate/TIMESTAMP_create_session_rsvps.rb`
- Create: `app/models/session.rb`
- Create: `app/models/session_rsvp.rb`
- Create: `spec/factories/sessions.rb`
- Create: `spec/factories/session_rsvps.rb`

**Step 1: Write failing test for Session model**

Create `spec/models/session_spec.rb`:

```ruby
# ABOUTME: Test suite for Session model covering validations and capacity management
# ABOUTME: Tests date/time validations and RSVP capacity tracking
require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }

    it 'validates end_time is after start_time' do
      session = build(:session, start_time: '14:00', end_time: '13:00')
      expect(session).not_to be_valid
      expect(session.errors[:end_time]).to include('must be after start time')
    end
  end

  describe 'associations' do
    it { should belong_to(:study_group) }
    it { should have_many(:session_rsvps).dependent(:destroy) }
    it { should have_many(:attendees).through(:session_rsvps).source(:user) }
    it { should have_many(:session_resources).dependent(:destroy) }
    it { should have_many(:attendance_records).dependent(:destroy) }
  end

  describe '#full?' do
    let(:session) { create(:session, max_capacity: 5) }

    context 'when RSVP count is below capacity' do
      before do
        create_list(:session_rsvp, 3, session: session, status: :going)
      end

      it 'returns false' do
        expect(session.full?).to be false
      end
    end

    context 'when RSVP count equals capacity' do
      before do
        create_list(:session_rsvp, 5, session: session, status: :going)
      end

      it 'returns true' do
        expect(session.full?).to be true
      end
    end

    context 'when capacity is nil' do
      let(:session) { create(:session, max_capacity: nil) }

      it 'returns false' do
        expect(session.full?).to be false
      end
    end
  end

  describe '#spots_remaining' do
    let(:session) { create(:session, max_capacity: 10) }

    before do
      create_list(:session_rsvp, 7, session: session, status: :going)
    end

    it 'returns the correct number of spots' do
      expect(session.spots_remaining).to eq(3)
    end
  end
end
```

**Step 2: Write failing test for SessionRsvp model**

Create `spec/models/session_rsvp_spec.rb`:

```ruby
# ABOUTME: Test suite for SessionRsvp model covering RSVP status management
# ABOUTME: Tests going, maybe, not_going statuses and uniqueness constraints
require 'rails_helper'

RSpec.describe SessionRsvp, type: :model do
  describe 'validations' do
    subject { build(:session_rsvp) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:session_id) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:session) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(going: 0, maybe: 1, not_going: 2) }
  end

  describe 'scopes' do
    let(:session) { create(:session) }
    let!(:going_rsvp) { create(:session_rsvp, session: session, status: :going) }
    let!(:maybe_rsvp) { create(:session_rsvp, session: session, status: :maybe) }
    let!(:not_going_rsvp) { create(:session_rsvp, session: session, status: :not_going) }

    it '.attending returns going and maybe RSVPs' do
      attending = session.session_rsvps.attending
      expect(attending).to include(going_rsvp, maybe_rsvp)
      expect(attending).not_to include(not_going_rsvp)
    end
  end
end
```

**Step 3: Create Session and SessionRsvp factories**

Create `spec/factories/sessions.rb`:

```ruby
# ABOUTME: FactoryBot factory for creating test sessions
# ABOUTME: Generates realistic session data with dates, times, locations
FactoryBot.define do
  factory :session do
    association :study_group
    sequence(:title) { |n| "Study Session #{n}" }
    date { 1.week.from_now.to_date }
    start_time { '14:00' }
    end_time { '16:00' }
    location { Faker::Address.full_address }
    meeting_link { Faker::Internet.url }
    description { Faker::Lorem.paragraph }
    max_capacity { 10 }
    prep_materials { Faker::Lorem.paragraph }

    trait :full do
      after(:create) do |session|
        create_list(:session_rsvp, session.max_capacity, session: session, status: :going)
      end
    end

    trait :past do
      date { 1.week.ago.to_date }
    end
  end
end
```

Create `spec/factories/session_rsvps.rb`:

```ruby
# ABOUTME: FactoryBot factory for creating test session RSVPs
# ABOUTME: Supports going, maybe, not_going statuses
FactoryBot.define do
  factory :session_rsvp do
    association :user
    association :session
    status { :going }
    rsvp_at { Time.current }

    trait :maybe do
      status { :maybe }
    end

    trait :not_going do
      status { :not_going }
    end
  end
end
```

**Step 4: Run tests to verify they fail**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/session_spec.rb spec/models/session_rsvp_spec.rb
```

Expected: FAIL with "uninitialized constant Session"

**Step 5: Create Session migration**

Run:
```bash
docker-compose run --rm web rails generate migration CreateSessions
```

Modify `db/migrate/TIMESTAMP_create_sessions.rb`:

```ruby
class CreateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.string :title, null: false
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :location
      t.string :meeting_link
      t.text :description
      t.integer :max_capacity
      t.text :prep_materials
      t.references :study_group, null: false, foreign_key: true

      t.timestamps
    end

    add_index :sessions, :date
  end
end
```

**Step 6: Create SessionRsvp migration**

Run:
```bash
docker-compose run --rm web rails generate migration CreateSessionRsvps
```

Modify `db/migrate/TIMESTAMP_create_session_rsvps.rb`:

```ruby
class CreateSessionRsvps < ActiveRecord::Migration[7.1]
  def change
    create_table :session_rsvps do |t|
      t.references :user, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :rsvp_at, null: false

      t.timestamps
    end

    add_index :session_rsvps, [:user_id, :session_id], unique: true
    add_index :session_rsvps, :status
  end
end
```

**Step 7: Run migrations**

Run:
```bash
docker-compose run --rm web rails db:migrate
```

Expected: Migrations run successfully

**Step 8: Create Session model**

Create `app/models/session.rb`:

```ruby
# ABOUTME: Session model for individual study group meeting sessions
# ABOUTME: Tracks date, time, location, capacity and manages RSVPs
class Session < ApplicationRecord
  belongs_to :study_group

  has_many :session_rsvps, dependent: :destroy
  has_many :attendees, through: :session_rsvps, source: :user
  has_many :session_resources, dependent: :destroy
  has_many :attendance_records, dependent: :destroy

  validates :title, presence: true
  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  scope :upcoming, -> { where('date >= ?', Date.current).order(:date, :start_time) }
  scope :past, -> { where('date < ?', Date.current).order(date: :desc, start_time: :desc) }

  def full?
    return false if max_capacity.nil?

    session_rsvps.attending.count >= max_capacity
  end

  def spots_remaining
    return nil if max_capacity.nil?

    max_capacity - session_rsvps.attending.count
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, 'must be after start time')
    end
  end
end
```

**Step 9: Create SessionRsvp model**

Create `app/models/session_rsvp.rb`:

```ruby
# ABOUTME: Join model for session RSVPs with going/maybe/not_going statuses
# ABOUTME: Tracks which users are attending which sessions
class SessionRsvp < ApplicationRecord
  belongs_to :user
  belongs_to :session

  enum status: { going: 0, maybe: 1, not_going: 2 }

  validates :user_id, uniqueness: { scope: :session_id }

  scope :attending, -> { where(status: [:going, :maybe]) }
end
```

**Step 10: Update User model with session associations**

Modify `app/models/user.rb`, add:

```ruby
  has_many :session_rsvps, dependent: :destroy
  has_many :sessions, through: :session_rsvps
```

**Step 11: Run tests to verify they pass**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/session_spec.rb spec/models/session_rsvp_spec.rb
```

Expected: All tests pass

**Step 12: Commit**

```bash
git add .
git commit -m "feat: add Session and SessionRsvp models

- Create sessions table with date, time, location, capacity
- Add validation for end_time after start_time
- Create session_rsvps join table with going/maybe/not_going enum
- Implement full? and spots_remaining methods on Session
- Add attending scope to SessionRsvp for capacity tracking
- Add upcoming and past scopes to Session
- Create factories for sessions and RSVPs
- Add comprehensive model tests

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 9: Create AttendanceRecord and SessionResource Models

**Files:**
- Create: `spec/models/attendance_record_spec.rb`
- Create: `spec/models/session_resource_spec.rb`
- Create: `db/migrate/TIMESTAMP_create_attendance_records.rb`
- Create: `db/migrate/TIMESTAMP_create_session_resources.rb`
- Create: `app/models/attendance_record.rb`
- Create: `app/models/session_resource.rb`

**Step 1: Write failing tests**

Create `spec/models/attendance_record_spec.rb`:

```ruby
# ABOUTME: Test suite for AttendanceRecord model
# ABOUTME: Tests actual attendance tracking vs RSVP status
require 'rails_helper'

RSpec.describe AttendanceRecord, type: :model do
  describe 'validations' do
    subject { build(:attendance_record) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:session_id) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:session) }
    it { should belong_to(:recorded_by).class_name('User') }
  end
end
```

Create `spec/models/session_resource_spec.rb`:

```ruby
# ABOUTME: Test suite for SessionResource model
# ABOUTME: Tests file attachment and resource type validation
require 'rails_helper'

RSpec.describe SessionResource, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'associations' do
    it { should belong_to(:session) }
    it { should belong_to(:uploaded_by).class_name('User') }
  end

  describe 'enums' do
    it { should define_enum_for(:resource_type).with_values(prep: 0, notes: 1, recording: 2) }
  end
end
```

**Step 2: Create factories**

Create `spec/factories/attendance_records.rb`:

```ruby
# ABOUTME: FactoryBot factory for creating test attendance records
# ABOUTME: Tracks actual attendance with notes and recorder
FactoryBot.define do
  factory :attendance_record do
    association :user
    association :session
    association :recorded_by, factory: [:user, :teacher]
    attended { true }
    notes { Faker::Lorem.sentence }
    recorded_at { Time.current }

    trait :absent do
      attended { false }
    end
  end
end
```

Create `spec/factories/session_resources.rb`:

```ruby
# ABOUTME: FactoryBot factory for creating test session resources
# ABOUTME: Supports prep materials, notes, and recordings
FactoryBot.define do
  factory :session_resource do
    association :session
    association :uploaded_by, factory: [:user, :teacher]
    title { Faker::Lorem.sentence }
    resource_type { :prep }

    trait :notes do
      resource_type { :notes }
    end

    trait :recording do
      resource_type { :recording }
    end
  end
end
```

**Step 3: Run tests to verify they fail**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/attendance_record_spec.rb spec/models/session_resource_spec.rb
```

Expected: FAIL

**Step 4: Create migrations**

Run:
```bash
docker-compose run --rm web rails generate migration CreateAttendanceRecords
docker-compose run --rm web rails generate migration CreateSessionResources
```

Modify `db/migrate/TIMESTAMP_create_attendance_records.rb`:

```ruby
class CreateAttendanceRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :attendance_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true
      t.boolean :attended, default: false, null: false
      t.text :notes
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :attendance_records, [:user_id, :session_id], unique: true
  end
end
```

Modify `db/migrate/TIMESTAMP_create_session_resources.rb`:

```ruby
class CreateSessionResources < ActiveRecord::Migration[7.1]
  def change
    create_table :session_resources do |t|
      t.string :title, null: false
      t.integer :resource_type, default: 0, null: false
      t.references :session, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :session_resources, :resource_type
  end
end
```

**Step 5: Run migrations**

Run:
```bash
docker-compose run --rm web rails db:migrate
```

Expected: Migrations run successfully

**Step 6: Create models**

Create `app/models/attendance_record.rb`:

```ruby
# ABOUTME: AttendanceRecord model for tracking actual session attendance
# ABOUTME: Records whether students attended vs their RSVP status
class AttendanceRecord < ApplicationRecord
  belongs_to :user
  belongs_to :session
  belongs_to :recorded_by, class_name: 'User'

  validates :user_id, uniqueness: { scope: :session_id }
end
```

Create `app/models/session_resource.rb`:

```ruby
# ABOUTME: SessionResource model for file attachments to sessions
# ABOUTME: Supports prep materials, notes, and recordings via ActiveStorage
class SessionResource < ApplicationRecord
  belongs_to :session
  belongs_to :uploaded_by, class_name: 'User'

  has_one_attached :file

  enum resource_type: { prep: 0, notes: 1, recording: 2 }

  validates :title, presence: true
end
```

**Step 7: Install ActiveStorage**

Run:
```bash
docker-compose run --rm web rails active_storage:install
docker-compose run --rm web rails db:migrate
```

Expected: ActiveStorage tables created

**Step 8: Run tests to verify they pass**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/models/attendance_record_spec.rb spec/models/session_resource_spec.rb
```

Expected: All tests pass

**Step 9: Commit**

```bash
git add .
git commit -m "feat: add AttendanceRecord and SessionResource models

- Create attendance_records table for tracking actual attendance
- Create session_resources table for file attachments
- Install ActiveStorage for file uploads
- Add resource_type enum (prep, notes, recording)
- Create factories and tests for both models

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 10: Install and Configure Pundit for Authorization

**Files:**
- Modify: `Gemfile`
- Create: `app/policies/application_policy.rb`
- Create: `app/policies/course_policy.rb`
- Create: `app/policies/study_group_policy.rb`
- Create: `spec/policies/course_policy_spec.rb`
- Create: `spec/policies/study_group_policy_spec.rb`
- Modify: `app/controllers/application_controller.rb`

**Step 1: Add Pundit to Gemfile**

Modify `Gemfile`, add:

```ruby
gem 'pundit', '~> 2.3.0'
```

**Step 2: Install Pundit**

Run:
```bash
docker-compose run --rm web bundle install
docker-compose run --rm web rails generate pundit:install
```

Expected: ApplicationPolicy created

**Step 3: Configure ApplicationController to use Pundit**

Modify `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  helper_method :current_user, :user_signed_in?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to root_path, alert: 'You must be signed in to access this page.'
    end
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referer || root_path)
  end
end
```

**Step 4: Write failing test for CoursePolicy**

Create `spec/policies/course_policy_spec.rb`:

```ruby
# ABOUTME: Policy specs for Course authorization rules
# ABOUTME: Tests admin-only course management permissions
require 'rails_helper'

RSpec.describe CoursePolicy do
  subject { described_class }

  let(:admin) { build(:user, :admin) }
  let(:teacher) { build(:user, :teacher) }
  let(:student) { build(:user) }
  let(:course) { build(:course) }

  permissions :index?, :show? do
    it 'allows all users' do
      expect(subject).to permit(student, course)
      expect(subject).to permit(teacher, course)
      expect(subject).to permit(admin, course)
    end
  end

  permissions :create?, :new? do
    it 'denies students and teachers' do
      expect(subject).not_to permit(student, Course)
      expect(subject).not_to permit(teacher, Course)
    end

    it 'allows admins' do
      expect(subject).to permit(admin, Course)
    end
  end

  permissions :update?, :edit?, :destroy? do
    it 'denies students and teachers' do
      expect(subject).not_to permit(student, course)
      expect(subject).not_to permit(teacher, course)
    end

    it 'allows admins' do
      expect(subject).to permit(admin, course)
    end
  end
end
```

**Step 5: Write failing test for StudyGroupPolicy**

Create `spec/policies/study_group_policy_spec.rb`:

```ruby
# ABOUTME: Policy specs for StudyGroup authorization rules
# ABOUTME: Tests creator, teacher, and admin permissions for groups
require 'rails_helper'

RSpec.describe StudyGroupPolicy do
  subject { described_class }

  let(:admin) { build(:user, :admin) }
  let(:teacher) { build(:user, :teacher) }
  let(:student) { build(:user) }
  let(:creator) { build(:user) }
  let(:study_group) { build(:study_group, creator: creator, group_type: :peer) }

  permissions :show? do
    it 'allows all users' do
      expect(subject).to permit(student, study_group)
      expect(subject).to permit(teacher, study_group)
      expect(subject).to permit(admin, study_group)
    end
  end

  permissions :create?, :new? do
    it 'allows students to create peer groups' do
      expect(subject).to permit(student, StudyGroup)
    end

    it 'allows teachers to create groups' do
      expect(subject).to permit(teacher, StudyGroup)
    end

    it 'allows admins to create groups' do
      expect(subject).to permit(admin, StudyGroup)
    end
  end

  permissions :update?, :edit?, :destroy? do
    it 'allows the creator' do
      expect(subject).to permit(creator, study_group)
    end

    it 'allows admins' do
      expect(subject).to permit(admin, study_group)
    end

    it 'denies other users' do
      expect(subject).not_to permit(student, study_group)
    end
  end
end
```

**Step 6: Run tests to verify they fail**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/policies/
```

Expected: FAIL with policy not found

**Step 7: Create CoursePolicy**

Create `app/policies/course_policy.rb`:

```ruby
# ABOUTME: Authorization policy for Course model
# ABOUTME: Only admins can create, update, or delete courses; all can view
class CoursePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
```

**Step 8: Create StudyGroupPolicy**

Create `app/policies/study_group_policy.rb`:

```ruby
# ABOUTME: Authorization policy for StudyGroup model
# ABOUTME: Creators and admins can manage groups; all users can view and create
class StudyGroupPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    user.student? || user.teacher? || user.admin?
  end

  def update?
    user.admin? || record.creator == user
  end

  def destroy?
    user.admin? || record.creator == user
  end
end
```

**Step 9: Run tests to verify they pass**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/policies/
```

Expected: All tests pass

**Step 10: Commit**

```bash
git add .
git commit -m "feat: install and configure Pundit authorization

- Add Pundit gem and generate ApplicationPolicy
- Configure ApplicationController with Pundit
- Create CoursePolicy (admin-only management)
- Create StudyGroupPolicy (creator and admin management)
- Add comprehensive policy specs
- Add user_not_authorized error handling

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Next Steps Summary

This implementation plan covers the foundational models, authentication, and authorization. The remaining tasks would include:

**Task 11:** Create Courses controller and views
**Task 12:** Create StudyGroups controller and views with Hotwire
**Task 13:** Implement membership approval workflow
**Task 14:** Create Sessions controller and RSVP functionality
**Task 15:** Set up ActionMailer with icalendar gem
**Task 16:** Implement email notifications with .ics attachments
**Task 17:** Add background jobs for email delivery
**Task 18:** Create admin dashboard
**Task 19:** Add system tests for complete workflows
**Task 20:** Dockerize for production and deploy

Each task would follow the same TDD approach with bite-sized steps.
