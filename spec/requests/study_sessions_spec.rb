# ABOUTME: Request specs for StudySessionsController (nested under study groups)
# ABOUTME: Tests CRUD operations with authorization (creator/admin can manage, members can view)
require 'rails_helper'

RSpec.describe "StudySessions", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user) }
  let(:other_student) { create(:user) }
  let(:course) { create(:course) }
  let(:study_group) { create(:study_group, creator: teacher, course: course) }
  let!(:approved_membership) { create(:study_group_membership, user: student, study_group: study_group, status: :approved) }
  let(:session) { create(:session, study_group: study_group) }

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  def sign_in_user(user)
    auth_hash = OmniAuth::AuthHash.new({
      'provider' => user.provider,
      'uid' => user.uid,
      'info' => {
        'email' => user.email,
        'name' => user.name
      }
    })
    OmniAuth.config.add_mock(:google_oauth2, auth_hash)
    Rails.application.env_config['omniauth.auth'] = auth_hash
    post '/auth/google_oauth2'
    get '/auth/google_oauth2/callback'
    Rails.application.env_config['omniauth.auth'] = nil
  end

  describe "GET /study_groups/:study_group_id/study_sessions" do
    it "shows sessions list for approved group members" do
      sign_in_user(student)
      get study_group_study_sessions_path(study_group)
      expect(response).to have_http_status(:success)
    end

    it "shows sessions list for group creator" do
      sign_in_user(teacher)
      get study_group_study_sessions_path(study_group)
      expect(response).to have_http_status(:success)
    end

    it "denies access to non-members" do
      sign_in_user(other_student)
      get study_group_study_sessions_path(study_group)
      expect(response).to have_http_status(:redirect)
    end

    it "redirects to login if not authenticated" do
      get study_group_study_sessions_path(study_group)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /study_groups/:study_group_id/study_sessions/:id" do
    it "shows session details to approved group members" do
      sign_in_user(student)
      get study_group_study_session_path(study_group, session)
      expect(response).to have_http_status(:success)
    end

    it "shows session details to group creator" do
      sign_in_user(teacher)
      get study_group_study_session_path(study_group, session)
      expect(response).to have_http_status(:success)
    end

    it "denies access to non-members" do
      sign_in_user(other_student)
      get study_group_study_session_path(study_group, session)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /study_groups/:study_group_id/study_sessions/new" do
    it "allows group creator to access new session form" do
      sign_in_user(teacher)
      get new_study_group_study_session_path(study_group)
      expect(response).to have_http_status(:success)
    end

    it "allows admin to access new session form" do
      sign_in_user(admin)
      get new_study_group_study_session_path(study_group)
      expect(response).to have_http_status(:success)
    end

    it "denies access to regular members" do
      sign_in_user(student)
      get new_study_group_study_session_path(study_group)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /study_groups/:study_group_id/study_sessions" do
    let(:valid_attributes) do
      {
        session: {
          title: 'Midterm Review Session',
          date: Date.tomorrow,
          start_time: Time.zone.parse('14:00'),
          end_time: Time.zone.parse('16:00'),
          location: 'Library Room 301',
          meeting_link: 'https://zoom.us/j/123',
          description: 'Review session for midterm',
          max_capacity: 10,
          prep_materials: 'Read chapters 1-5'
        }
      }
    end

    it "allows group creator to create sessions" do
      sign_in_user(teacher)
      expect {
        post study_group_study_sessions_path(study_group), params: valid_attributes
      }.to change(Session, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(Session.last.study_group).to eq(study_group)
    end

    it "allows admin to create sessions" do
      sign_in_user(admin)
      expect {
        post study_group_study_sessions_path(study_group), params: valid_attributes
      }.to change(Session, :count).by(1)

      expect(response).to have_http_status(:redirect)
    end

    it "denies creation to regular members" do
      sign_in_user(student)
      expect {
        post study_group_study_sessions_path(study_group), params: valid_attributes
      }.not_to change(Session, :count)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /study_groups/:study_group_id/study_sessions/:id/edit" do
    it "allows group creator to access edit form" do
      sign_in_user(teacher)
      get edit_study_group_study_session_path(study_group, session)
      expect(response).to have_http_status(:success)
    end

    it "allows admin to access edit form" do
      sign_in_user(admin)
      get edit_study_group_study_session_path(study_group, session)
      expect(response).to have_http_status(:success)
    end

    it "denies access to regular members" do
      sign_in_user(student)
      get edit_study_group_study_session_path(study_group, session)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /study_groups/:study_group_id/study_sessions/:id" do
    let(:new_attributes) { { session: { title: 'Updated Session Title' } } }

    it "allows group creator to update session" do
      sign_in_user(teacher)
      patch study_group_study_session_path(study_group, session), params: new_attributes
      session.reload
      expect(session.title).to eq('Updated Session Title')
      expect(response).to have_http_status(:redirect)
    end

    it "allows admin to update session" do
      sign_in_user(admin)
      patch study_group_study_session_path(study_group, session), params: new_attributes
      session.reload
      expect(session.title).to eq('Updated Session Title')
      expect(response).to have_http_status(:redirect)
    end

    it "denies updates to regular members" do
      sign_in_user(student)
      original_title = session.title
      patch study_group_study_session_path(study_group, session), params: new_attributes
      session.reload
      expect(session.title).to eq(original_title)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /study_groups/:study_group_id/study_sessions/:id" do
    let!(:session_to_delete) { create(:session, study_group: study_group) }

    it "allows group creator to delete session" do
      sign_in_user(teacher)
      expect {
        delete study_group_study_session_path(study_group, session_to_delete)
      }.to change(Session, :count).by(-1)

      expect(response).to have_http_status(:redirect)
    end

    it "allows admin to delete session" do
      sign_in_user(admin)
      session_to_delete_by_admin = create(:session, study_group: study_group)
      expect {
        delete study_group_study_session_path(study_group, session_to_delete_by_admin)
      }.to change(Session, :count).by(-1)

      expect(response).to have_http_status(:redirect)
    end

    it "denies deletion to regular members" do
      sign_in_user(student)
      expect {
        delete study_group_study_session_path(study_group, session_to_delete)
      }.not_to change(Session, :count)

      expect(response).to have_http_status(:redirect)
    end
  end
end
