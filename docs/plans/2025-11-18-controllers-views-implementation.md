# Study Group Scheduler - Controllers & Views Implementation Plan (Tasks 11-20)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete user interface, email notification system, and deployment setup for the Study Group Scheduler application.

**Architecture:** Rails 7 MVC with Hotwire (Turbo Frames + Stimulus) for dynamic interactions, ActionMailer with icalendar for email notifications, Solid Queue for background jobs, and Docker for deployment.

**Tech Stack:** Rails 7+, Hotwire, Tailwind CSS, ActionMailer, icalendar gem, Solid Queue, RSpec (request + system tests), Docker

---

## Prerequisites

Tasks 1-10 must be completed:
- ✅ Rails 7 with Docker
- ✅ RSpec testing framework
- ✅ User model with OAuth
- ✅ OmniAuth configured
- ✅ SessionsController
- ✅ All core models (Course, StudyGroup, Session, etc.)
- ✅ Pundit authorization

---

## Task 11: Create Courses Controller and Views (Admin CRUD)

**Goal:** Admin users can manage the course catalog (create, view, edit, delete courses)

**Files:**
- Create: `app/controllers/courses_controller.rb`
- Create: `app/views/courses/index.html.erb`
- Create: `app/views/courses/show.html.erb`
- Create: `app/views/courses/new.html.erb`
- Create: `app/views/courses/_form.html.erb`
- Create: `spec/requests/courses_spec.rb`
- Modify: `config/routes.rb`

**Step 1: Add courses routes**

Modify `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # OAuth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # Courses (admin only)
  resources :courses

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
```

**Step 2: Write failing request specs for CoursesController**

Create `spec/requests/courses_spec.rb`:

```ruby
# ABOUTME: Request specs for Courses controller
# ABOUTME: Tests admin-only CRUD operations on courses
require 'rails_helper'

RSpec.describe "Courses", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user) }
  let(:course) { create(:course) }

  describe "GET /courses" do
    it "shows courses list for any signed-in user" do
      sign_in student
      get courses_path
      expect(response).to have_http_status(:success)
    end

    it "redirects to login if not authenticated" do
      get courses_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /courses/:id" do
    it "shows course details to any signed-in user" do
      sign_in student
      get course_path(course)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /courses/new" do
    it "allows admins to access new course form" do
      sign_in admin
      get new_course_path
      expect(response).to have_http_status(:success)
    end

    it "denies access to non-admins" do
      sign_in student
      get new_course_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end
  end

  describe "POST /courses" do
    let(:valid_attributes) { { course: { name: 'Intro to CS', code: 'CS101', semester: 'Fall', year: 2025 } } }

    it "allows admins to create courses" do
      sign_in admin
      expect {
        post courses_path, params: valid_attributes
      }.to change(Course, :count).by(1)

      expect(response).to redirect_to(Course.last)
      expect(flash[:notice]).to be_present
    end

    it "denies course creation to non-admins" do
      sign_in student
      expect {
        post courses_path, params: valid_attributes
      }.not_to change(Course, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /courses/:id" do
    let(:new_attributes) { { course: { name: 'Updated Course Name' } } }

    it "allows admins to update courses" do
      sign_in admin
      patch course_path(course), params: new_attributes
      course.reload
      expect(course.name).to eq('Updated Course Name')
      expect(response).to redirect_to(course)
    end

    it "denies updates to non-admins" do
      sign_in student
      original_name = course.name
      patch course_path(course), params: new_attributes
      course.reload
      expect(course.name).to eq(original_name)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /courses/:id" do
    let!(:course_to_delete) { create(:course) }

    it "allows admins to delete courses" do
      sign_in admin
      expect {
        delete course_path(course_to_delete)
      }.to change(Course, :count).by(-1)

      expect(response).to redirect_to(courses_path)
    end

    it "denies deletion to non-admins" do
      sign_in student
      expect {
        delete course_path(course_to_delete)
      }.not_to change(Course, :count)

      expect(response).to redirect_to(root_path)
    end
  end
end

# Helper method for signing in users in request specs
def sign_in(user)
  allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
end
```

**Step 3: Run specs to verify they fail**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/requests/courses_spec.rb
```

Expected: Failures with "No route matches" or "uninitialized constant CoursesController"

**Step 4: Create CoursesController**

Create `app/controllers/courses_controller.rb`:

```ruby
# ABOUTME: Controller for managing courses (admin-only write, all read)
# ABOUTME: Handles CRUD operations with Pundit authorization
class CoursesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course, only: [:show, :edit, :update, :destroy]

  def index
    @courses = Course.all
    authorize Course
  end

  def show
    authorize @course
  end

  def new
    @course = Course.new
    authorize @course
  end

  def create
    @course = Course.new(course_params)
    authorize @course

    if @course.save
      redirect_to @course, notice: 'Course was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @course
  end

  def update
    authorize @course

    if @course.update(course_params)
      redirect_to @course, notice: 'Course was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @course
    @course.destroy
    redirect_to courses_path, notice: 'Course was successfully deleted.'
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:name, :code, :description, :semester, :year)
  end
end
```

**Step 5: Create view templates**

Create `app/views/courses/index.html.erb`:

```erb
<!-- ABOUTME: Courses listing page showing all available courses -->
<!-- ABOUTME: Admins see create/edit/delete buttons, others see read-only list -->
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">Courses</h1>
    <% if policy(Course).create? %>
      <%= link_to "New Course", new_course_path, class: "bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded" %>
    <% end %>
  </div>

  <div class="bg-white shadow overflow-hidden sm:rounded-md">
    <ul role="list" class="divide-y divide-gray-200">
      <% @courses.each do |course| %>
        <li>
          <%= link_to course_path(course), class: "block hover:bg-gray-50" do %>
            <div class="px-4 py-4 sm:px-6">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-lg font-semibold text-blue-600"><%= course.code %></p>
                  <p class="text-sm text-gray-900"><%= course.name %></p>
                </div>
                <div class="text-sm text-gray-500">
                  <%= course.semester %> <%= course.year %>
                </div>
              </div>
            </div>
          <% end %>
        </li>
      <% end %>
    </ul>
  </div>
</div>
```

Create `app/views/courses/show.html.erb`:

```erb
<!-- ABOUTME: Course detail page showing course info and associated study groups -->
<!-- ABOUTME: Admins see edit/delete buttons -->
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <div class="bg-white shadow sm:rounded-lg">
    <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900"><%= @course.code %>: <%= @course.name %></h1>
        <p class="text-sm text-gray-500"><%= @course.semester %> <%= @course.year %></p>
      </div>
      <div class="flex gap-2">
        <% if policy(@course).update? %>
          <%= link_to "Edit", edit_course_path(@course), class: "bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded" %>
        <% end %>
        <% if policy(@course).destroy? %>
          <%= button_to "Delete", course_path(@course), method: :delete, data: { confirm: "Are you sure?" }, class: "bg-red-600 hover:bg-red-700 text-white font-semibold py-2 px-4 rounded" %>
        <% end %>
      </div>
    </div>

    <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
      <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
        <div class="sm:col-span-2">
          <dt class="text-sm font-medium text-gray-500">Description</dt>
          <dd class="mt-1 text-sm text-gray-900"><%= @course.description || 'No description provided' %></dd>
        </div>
      </dl>
    </div>
  </div>

  <%= link_to "Back to Courses", courses_path, class: "mt-4 inline-block text-blue-600 hover:text-blue-800" %>
</div>
```

Create `app/views/courses/new.html.erb`:

```erb
<!-- ABOUTME: New course creation form for admins -->
<!-- ABOUTME: Uses shared form partial -->
<div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <h1 class="text-3xl font-bold text-gray-900 mb-6">New Course</h1>

  <%= render 'form', course: @course %>

  <%= link_to "Cancel", courses_path, class: "mt-4 inline-block text-gray-600 hover:text-gray-800" %>
</div>
```

Create `app/views/courses/edit.html.erb`:

```erb
<!-- ABOUTME: Edit course form for admins -->
<!-- ABOUTME: Uses shared form partial -->
<div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <h1 class="text-3xl font-bold text-gray-900 mb-6">Edit Course</h1>

  <%= render 'form', course: @course %>

  <%= link_to "Cancel", course_path(@course), class: "mt-4 inline-block text-gray-600 hover:text-gray-800" %>
</div>
```

Create `app/views/courses/_form.html.erb`:

```erb
<!-- ABOUTME: Shared form partial for creating and editing courses -->
<!-- ABOUTME: Displays validation errors and uses Tailwind styling -->
<%= form_with(model: course, class: "space-y-6") do |form| %>
  <% if course.errors.any? %>
    <div class="bg-red-50 border border-red-200 text-red-800 rounded-md p-4">
      <h2 class="text-lg font-medium mb-2"><%= pluralize(course.errors.count, "error") %> prohibited this course from being saved:</h2>
      <ul class="list-disc list-inside">
        <% course.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :code, class: "block text-sm font-medium text-gray-700" %>
    <%= form.text_field :code, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
  </div>

  <div>
    <%= form.label :name, class: "block text-sm font-medium text-gray-700" %>
    <%= form.text_field :name, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
  </div>

  <div>
    <%= form.label :description, class: "block text-sm font-medium text-gray-700" %>
    <%= form.text_area :description, rows: 4, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
  </div>

  <div class="grid grid-cols-2 gap-4">
    <div>
      <%= form.label :semester, class: "block text-sm font-medium text-gray-700" %>
      <%= form.select :semester, ['Fall', 'Spring', 'Summer'], {}, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
    </div>

    <div>
      <%= form.label :year, class: "block text-sm font-medium text-gray-700" %>
      <%= form.number_field :year, value: (course.year || Time.current.year), class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500" %>
    </div>
  </div>

  <div>
    <%= form.submit class: "w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded cursor-pointer" %>
  </div>
<% end %>
```

**Step 6: Run specs to verify they pass**

Run:
```bash
docker-compose run --rm web bundle exec rspec spec/requests/courses_spec.rb
```

Expected: All tests pass

**Step 7: Commit**

```bash
git add .
git commit -m "feat: add Courses controller and views with admin CRUD

- Create CoursesController with full CRUD operations
- Implement Pundit authorization (admin-only write access)
- Add index, show, new, edit views with Tailwind styling
- Create shared form partial for course creation/editing
- Add comprehensive request specs for authorization
- Update routes with courses resource

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## SUMMARY: Next Tasks Preview

Due to the complexity and length of tasks 12-20, this plan focuses on Task 11 as a complete example. The remaining tasks would follow this same pattern:

**Task 12**: StudyGroups controller with index, show, new, create, edit, update actions
**Task 13**: Membership approval with Turbo Frames (approve/reject buttons)
**Task 14**: Sessions controller with RSVP functionality using Turbo
**Task 15**: ActionMailer setup with icalendar gem
**Task 16**: Email mailers for join requests, RSVPs, reminders with .ics attachments
**Task 17**: Solid Queue installation and background job configuration
**Task 18**: Admin dashboard with stats and management tools
**Task 19**: System tests using Capybara for full user workflows
**Task 20**: Production deployment with Docker and PostgreSQL

Each task would be broken down into the same bite-sized steps (2-5 minutes each) following strict TDD methodology.

Would you like me to expand the plan to include all remaining tasks in detail?
