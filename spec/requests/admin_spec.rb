# ABOUTME: Request specs for admin dashboard
# ABOUTME: Tests admin-only access and dashboard statistics display
require 'rails_helper'

RSpec.describe 'Admin::Dashboard', type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:teacher) { create(:user, role: :teacher) }
  let(:student) { create(:user, role: :student) }

  # Helper to set up controller stubs for authentication
  def stub_current_user(user)
    allow_any_instance_of(Admin::AdminController).to receive(:current_user).and_return(user)
    allow_any_instance_of(Admin::AdminController).to receive(:user_signed_in?).and_return(true)
    allow_any_instance_of(Admin::AdminController).to receive(:authenticate_user!).and_return(true)
  end

  describe 'GET /admin/dashboard' do
    context 'when user is not authenticated' do
      it 'redirects to root path with alert' do
        allow_any_instance_of(Admin::AdminController).to receive(:current_user).and_return(nil)
        allow_any_instance_of(Admin::AdminController).to receive(:user_signed_in?).and_return(false)
        get admin_dashboard_path, headers: { 'Host' => 'localhost' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('You must be signed in to access this page.')
      end
    end

    context 'when user is not an admin' do
      it 'redirects students with authorization error' do
        stub_current_user(student)
        get admin_dashboard_path, headers: { 'Host' => 'localhost' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      end

      it 'redirects teachers with authorization error' do
        stub_current_user(teacher)
        get admin_dashboard_path, headers: { 'Host' => 'localhost' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      end
    end

    context 'when user is an admin' do
      before do
        stub_current_user(admin)
      end

      it 'returns success' do
        get admin_dashboard_path, headers: { 'Host' => 'localhost' }
        expect(response).to have_http_status(:success)
      end

      it 'displays user statistics by role' do
        create_list(:user, 5, role: :student)
        create_list(:user, 2, role: :teacher)
        create(:user, role: :admin)

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        expect(response.body).to include('6') # 5 created + 1 original student
        expect(response.body).to include('3') # 2 created + 1 original teacher
        expect(response.body).to include('2') # 1 created + logged in admin
      end

      it 'displays course statistics' do
        create_list(:course, 3)

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        expect(response.body).to include('3')
        expect(response.body).to match(/courses/i)
      end

      it 'displays study group statistics' do
        course = create(:course)
        create_list(:study_group, 4, course: course, status: :active)
        create_list(:study_group, 2, course: course, status: :archived)

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        expect(response.body).to include('6') # total groups
        expect(response.body).to include('4') # active groups
        expect(response.body).to include('2') # archived groups
      end

      it 'displays session statistics' do
        course = create(:course)
        group = create(:study_group, course: course)
        create_list(:session, 3, study_group: group, date: 1.day.from_now)
        create_list(:session, 2, study_group: group, date: 1.day.ago)

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        expect(response.body).to include('5') # total sessions
        expect(response.body).to include('3') # upcoming sessions
        expect(response.body).to include('2') # past sessions
      end

      it 'displays recent memberships' do
        course = create(:course)
        group = create(:study_group, course: course, name: 'Test Group')
        membership = create(:study_group_membership, study_group: group, user: student)

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        expect(response.body).to include('Test Group')
        expect(response.body).to include(student.name)
      end

      it 'displays pending join requests count' do
        course = create(:course)
        group = create(:study_group, course: course)
        create_list(:study_group_membership, 3, study_group: group, status: :pending)
        create_list(:study_group_membership, 2, study_group: group, status: :approved)

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        expect(response.body).to include('3') # pending requests
      end

      it 'displays recent sessions' do
        course = create(:course)
        group = create(:study_group, course: course)
        session = create(:session, study_group: group, title: 'Important Session')

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        expect(response.body).to include('Important Session')
      end

      it 'displays recent RSVPs' do
        course = create(:course)
        group = create(:study_group, course: course)
        session = create(:session, study_group: group, title: 'Study Session')
        rsvp = create(:session_rsvp, session: session, user: student)

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        expect(response.body).to include('Study Session')
        expect(response.body).to include(student.name)
      end

      it 'limits recent activity to last 10 items' do
        course = create(:course)
        group = create(:study_group, course: course, name: 'Unique Test Group')
        # Create 15 memberships
        15.times do |i|
          user = create(:user, name: "Limit Test User #{i}", email: "limituser#{i}@example.com")
          create(:study_group_membership, study_group: group, user: user)
        end

        get admin_dashboard_path, headers: { 'Host' => 'localhost' }

        # Verify the response is successful
        expect(response).to have_http_status(:success)

        # The dashboard should show recent memberships
        # We created 15, so the page should show evidence of the limit working
        # by not showing all 15 users
        # Check that at least the first user (oldest) is NOT shown
        expect(response.body).not_to include('Limit Test User 0')
        # But the most recent ones should be shown
        expect(response.body).to include('Limit Test User 14')
      end
    end
  end
end
