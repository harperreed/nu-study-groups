# ABOUTME: Request specs for StudyGroups controller
# ABOUTME: Tests authorization rules (creator/admin can manage, all can view/create)
require 'rails_helper'

RSpec.describe "StudyGroups", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:teacher) { create(:user, :teacher) }
  let(:student) { create(:user) }
  let(:course) { create(:course) }
  let(:study_group) { create(:study_group, creator: teacher, course: course) }

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  # Helper to sign in a user by setting the session
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

  describe "GET /study_groups" do
    it "shows study groups list for any signed-in user" do
      sign_in_user(student)
      get study_groups_path
      expect(response).to have_http_status(:success)
    end

    it "redirects to login if not authenticated" do
      # Don't sign in, just make the request
      get study_groups_path
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /study_groups/:id" do
    it "shows study group details to any signed-in user" do
      sign_in_user(student)
      get study_group_path(study_group)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /study_groups/new" do
    it "allows students to access new study group form" do
      sign_in_user(student)
      get new_study_group_path
      expect(response).to have_http_status(:success)
    end

    it "allows teachers to access new study group form" do
      sign_in_user(teacher)
      get new_study_group_path
      expect(response).to have_http_status(:success)
    end

    it "allows admins to access new study group form" do
      sign_in_user(admin)
      get new_study_group_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /study_groups" do
    let(:valid_attributes) do
      {
        study_group: {
          name: 'Test Study Group',
          description: 'A test study group',
          group_type: 'peer',
          course_id: course.id
        }
      }
    end

    it "allows students to create study groups" do
      sign_in_user(student)
      expect {
        post study_groups_path, params: valid_attributes
      }.to change(StudyGroup, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(StudyGroup.last.creator).to eq(student)
    end

    it "allows teachers to create study groups" do
      sign_in_user(teacher)
      expect {
        post study_groups_path, params: valid_attributes
      }.to change(StudyGroup, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(StudyGroup.last.creator).to eq(teacher)
    end

    it "allows admins to create study groups" do
      sign_in_user(admin)
      expect {
        post study_groups_path, params: valid_attributes
      }.to change(StudyGroup, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(StudyGroup.last.creator).to eq(admin)
    end
  end

  describe "GET /study_groups/:id/edit" do
    it "allows creator to access edit form" do
      sign_in_user(teacher)
      get edit_study_group_path(study_group)
      expect(response).to have_http_status(:success)
    end

    it "allows admin to access edit form" do
      sign_in_user(admin)
      get edit_study_group_path(study_group)
      expect(response).to have_http_status(:success)
    end

    it "denies access to non-creator students" do
      sign_in_user(student)
      get edit_study_group_path(study_group)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /study_groups/:id" do
    let(:new_attributes) { { study_group: { name: 'Updated Study Group Name' } } }

    it "allows creator to update study group" do
      sign_in_user(teacher)
      patch study_group_path(study_group), params: new_attributes
      study_group.reload
      expect(study_group.name).to eq('Updated Study Group Name')
      expect(response).to have_http_status(:redirect)
    end

    it "allows admin to update study group" do
      sign_in_user(admin)
      patch study_group_path(study_group), params: new_attributes
      study_group.reload
      expect(study_group.name).to eq('Updated Study Group Name')
      expect(response).to have_http_status(:redirect)
    end

    it "denies updates to non-creator students" do
      sign_in_user(student)
      original_name = study_group.name
      patch study_group_path(study_group), params: new_attributes
      study_group.reload
      expect(study_group.name).to eq(original_name)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /study_groups/:id" do
    let!(:study_group_to_delete) { create(:study_group, creator: teacher, course: course) }

    it "allows creator to delete study group" do
      sign_in_user(teacher)
      expect {
        delete study_group_path(study_group_to_delete)
      }.to change(StudyGroup, :count).by(-1)

      expect(response).to have_http_status(:redirect)
    end

    it "allows admin to delete study group" do
      sign_in_user(admin)
      study_group_to_delete_by_admin = create(:study_group, creator: teacher, course: course)
      expect {
        delete study_group_path(study_group_to_delete_by_admin)
      }.to change(StudyGroup, :count).by(-1)

      expect(response).to have_http_status(:redirect)
    end

    it "denies deletion to non-creator students" do
      sign_in_user(student)
      expect {
        delete study_group_path(study_group_to_delete)
      }.not_to change(StudyGroup, :count)

      expect(response).to have_http_status(:redirect)
    end
  end
end
