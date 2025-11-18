# ABOUTME: Request specs for Courses controller
# ABOUTME: Tests admin-only CRUD operations on courses
require 'rails_helper'

RSpec.describe "Courses", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user) }
  let(:course) { create(:course) }

  # Helper to set up controller stubs for authentication
  def stub_current_user(user)
    allow_any_instance_of(CoursesController).to receive(:current_user).and_return(user)
    allow_any_instance_of(CoursesController).to receive(:user_signed_in?).and_return(true)
    allow_any_instance_of(CoursesController).to receive(:authenticate_user!).and_return(true)
  end

  describe "GET /courses" do
    it "shows courses list for any signed-in user" do
      stub_current_user(student)
      get courses_path
      expect(response).to have_http_status(:success)
    end

    it "redirects to login if not authenticated" do
      allow_any_instance_of(CoursesController).to receive(:current_user).and_return(nil)
      allow_any_instance_of(CoursesController).to receive(:user_signed_in?).and_return(false)
      get courses_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /courses/:id" do
    it "shows course details to any signed-in user" do
      stub_current_user(student)
      get course_path(course)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /courses/new" do
    it "allows admins to access new course form" do
      stub_current_user(admin)
      get new_course_path
      expect(response).to have_http_status(:success)
    end

    it "denies access to non-admins" do
      stub_current_user(student)
      get new_course_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /courses" do
    let(:valid_attributes) { { course: { name: 'Intro to CS', code: 'CS101', semester: 'Fall', year: 2025 } } }

    it "allows admins to create courses" do
      stub_current_user(admin)
      expect {
        post courses_path, params: valid_attributes
      }.to change(Course, :count).by(1)

      expect(response).to have_http_status(:redirect)
    end

    it "denies course creation to non-admins" do
      stub_current_user(student)
      expect {
        post courses_path, params: valid_attributes
      }.not_to change(Course, :count)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /courses/:id" do
    let(:new_attributes) { { course: { name: 'Updated Course Name' } } }

    it "allows admins to update courses" do
      stub_current_user(admin)
      patch course_path(course), params: new_attributes
      course.reload
      expect(course.name).to eq('Updated Course Name')
      expect(response).to have_http_status(:redirect)
    end

    it "denies updates to non-admins" do
      stub_current_user(student)
      original_name = course.name
      patch course_path(course), params: new_attributes
      course.reload
      expect(course.name).to eq(original_name)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /courses/:id" do
    let!(:course_to_delete) { create(:course) }

    it "allows admins to delete courses" do
      stub_current_user(admin)
      expect {
        delete course_path(course_to_delete)
      }.to change(Course, :count).by(-1)

      expect(response).to have_http_status(:redirect)
    end

    it "denies deletion to non-admins" do
      stub_current_user(student)
      expect {
        delete course_path(course_to_delete)
      }.not_to change(Course, :count)

      expect(response).to have_http_status(:redirect)
    end
  end
end
