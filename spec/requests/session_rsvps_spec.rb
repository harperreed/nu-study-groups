# ABOUTME: Request specs for SessionRsvpsController (RSVP management)
# ABOUTME: Tests RSVP create/update/destroy with capacity checks and authorization
require 'rails_helper'

RSpec.describe "SessionRsvps", type: :request do
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user) }
  let(:other_student) { create(:user) }
  let(:course) { create(:course) }
  let(:study_group) { create(:study_group, creator: teacher, course: course) }
  let!(:approved_membership) { create(:study_group_membership, user: student, study_group: study_group, status: :approved) }
  let!(:other_approved_membership) { create(:study_group_membership, user: other_student, study_group: study_group, status: :approved) }
  let(:session) { create(:session, study_group: study_group, max_capacity: 2) }

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

  describe "POST /session_rsvps" do
    let(:valid_attributes) do
      {
        session_rsvp: {
          session_id: session.id,
          status: 'going'
        }
      }
    end

    it "allows approved member to create RSVP" do
      sign_in_user(student)
      expect {
        post session_rsvps_path, params: valid_attributes
      }.to change(SessionRsvp, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(SessionRsvp.last.user).to eq(student)
      expect(SessionRsvp.last.status).to eq('going')
    end

    it "prevents creating RSVP when session is full" do
      sign_in_user(student)
      create(:session_rsvp, user: teacher, session: session, status: :going)
      create(:session_rsvp, user: other_student, session: session, status: :going)

      expect {
        post session_rsvps_path, params: valid_attributes
      }.not_to change(SessionRsvp, :count)

      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include('full')
    end

    it "allows creating 'maybe' RSVP even when session is full" do
      sign_in_user(student)
      create(:session_rsvp, user: teacher, session: session, status: :going)
      create(:session_rsvp, user: other_student, session: session, status: :going)

      maybe_attributes = { session_rsvp: { session_id: session.id, status: 'maybe' } }
      expect {
        post session_rsvps_path, params: maybe_attributes
      }.to change(SessionRsvp, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(SessionRsvp.last.status).to eq('maybe')
    end

    it "allows creating 'not_going' RSVP" do
      sign_in_user(student)
      not_going_attributes = { session_rsvp: { session_id: session.id, status: 'not_going' } }
      expect {
        post session_rsvps_path, params: not_going_attributes
      }.to change(SessionRsvp, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(SessionRsvp.last.status).to eq('not_going')
    end

    it "redirects to login if not authenticated" do
      expect {
        post session_rsvps_path, params: valid_attributes
      }.not_to change(SessionRsvp, :count)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /session_rsvps/:id" do
    let!(:rsvp) { create(:session_rsvp, user: student, session: session, status: :maybe) }

    it "allows user to update their own RSVP" do
      sign_in_user(student)
      patch session_rsvp_path(rsvp), params: { session_rsvp: { status: 'going' } }
      rsvp.reload
      expect(rsvp.status).to eq('going')
      expect(response).to have_http_status(:redirect)
    end

    it "allows changing from 'going' to 'not_going'" do
      sign_in_user(student)
      rsvp.update!(status: :going)
      patch session_rsvp_path(rsvp), params: { session_rsvp: { status: 'not_going' } }
      rsvp.reload
      expect(rsvp.status).to eq('not_going')
      expect(response).to have_http_status(:redirect)
    end

    it "prevents updating to 'going' when session is full" do
      sign_in_user(student)
      create(:session_rsvp, user: teacher, session: session, status: :going)
      create(:session_rsvp, user: other_student, session: session, status: :going)

      patch session_rsvp_path(rsvp), params: { session_rsvp: { status: 'going' } }
      rsvp.reload
      expect(rsvp.status).to eq('maybe')
      expect(response).to have_http_status(:redirect)
    end

    it "denies updating other users' RSVPs" do
      sign_in_user(other_student)
      original_status = rsvp.status
      patch session_rsvp_path(rsvp), params: { session_rsvp: { status: 'going' } }
      rsvp.reload
      expect(rsvp.status).to eq(original_status)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /session_rsvps/:id" do
    let!(:rsvp) { create(:session_rsvp, user: student, session: session, status: :going) }

    it "allows user to delete their own RSVP" do
      sign_in_user(student)
      expect {
        delete session_rsvp_path(rsvp)
      }.to change(SessionRsvp, :count).by(-1)

      expect(response).to have_http_status(:redirect)
    end

    it "denies deleting other users' RSVPs" do
      sign_in_user(other_student)
      expect {
        delete session_rsvp_path(rsvp)
      }.not_to change(SessionRsvp, :count)

      expect(response).to have_http_status(:redirect)
    end
  end
end
