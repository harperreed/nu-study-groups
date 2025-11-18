# ABOUTME: Request specs for study group membership join/approve/reject workflows
# ABOUTME: Tests authorization, duplicate prevention, and Turbo Stream responses
require 'rails_helper'

RSpec.describe "StudyGroupMemberships", type: :request do
  let(:student) { create(:user, :student) }
  let(:other_student) { create(:user, :student) }
  let(:teacher) { create(:user, :teacher) }
  let(:admin) { create(:user, :admin) }
  let(:course) { create(:course) }
  let(:study_group) { create(:study_group, course: course, creator: teacher) }

  describe "POST /study_groups/:id/join" do
    context "when authenticated" do
      before { sign_in student }

      it "creates a pending membership" do
        expect {
          post join_study_group_path(study_group)
        }.to change(StudyGroupMembership, :count).by(1)

        membership = StudyGroupMembership.last
        expect(membership.user).to eq(student)
        expect(membership.study_group).to eq(study_group)
        expect(membership.status).to eq('pending')
      end

      it "redirects back to study group with notice" do
        post join_study_group_path(study_group)
        expect(response).to redirect_to(study_group_path(study_group))
        follow_redirect!
        expect(response.body).to include('join request')
      end

      it "prevents duplicate join requests" do
        create(:study_group_membership, user: student, study_group: study_group, status: :pending)

        expect {
          post join_study_group_path(study_group)
        }.not_to change(StudyGroupMembership, :count)

        expect(response).to redirect_to(study_group_path(study_group))
      end

      it "allows rejoin after rejection" do
        create(:study_group_membership, user: student, study_group: study_group, status: :rejected)

        expect {
          post join_study_group_path(study_group)
        }.to change(StudyGroupMembership, :count).by(1)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post join_study_group_path(study_group)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /study_group_memberships/:id/approve" do
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :pending) }

    context "when creator approves" do
      before { sign_in teacher }

      it "approves the membership" do
        patch approve_study_group_membership_path(membership)
        membership.reload
        expect(membership.status).to eq('approved')
        expect(membership.approved_by).to eq(teacher)
        expect(membership.approved_at).to be_present
      end

      it "redirects with notice" do
        patch approve_study_group_membership_path(membership)
        expect(response).to redirect_to(study_group_path(study_group))
        follow_redirect!
        expect(response.body).to include('approved')
      end
    end

    context "when admin approves" do
      before { sign_in admin }

      it "approves the membership" do
        patch approve_study_group_membership_path(membership)
        membership.reload
        expect(membership.status).to eq('approved')
        expect(membership.approved_by).to eq(admin)
      end
    end

    context "when non-creator student tries to approve" do
      before { sign_in other_student }

      it "denies access" do
        patch approve_study_group_membership_path(membership)
        expect(response).to have_http_status(:forbidden)
      end

      it "does not change membership status" do
        expect {
          patch approve_study_group_membership_path(membership)
        }.not_to change { membership.reload.status }
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch approve_study_group_membership_path(membership)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /study_group_memberships/:id/reject" do
    let(:membership) { create(:study_group_membership, user: student, study_group: study_group, status: :pending) }

    context "when creator rejects" do
      before { sign_in teacher }

      it "rejects the membership" do
        patch reject_study_group_membership_path(membership)
        membership.reload
        expect(membership.status).to eq('rejected')
        expect(membership.approved_by).to eq(teacher)
      end

      it "redirects with notice" do
        patch reject_study_group_membership_path(membership)
        expect(response).to redirect_to(study_group_path(study_group))
        follow_redirect!
        expect(response.body).to include('rejected')
      end
    end

    context "when admin rejects" do
      before { sign_in admin }

      it "rejects the membership" do
        patch reject_study_group_membership_path(membership)
        membership.reload
        expect(membership.status).to eq('rejected')
      end
    end

    context "when non-creator student tries to reject" do
      before { sign_in other_student }

      it "denies access" do
        patch reject_study_group_membership_path(membership)
        expect(response).to have_http_status(:forbidden)
      end

      it "does not change membership status" do
        expect {
          patch reject_study_group_membership_path(membership)
        }.not_to change { membership.reload.status }
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch reject_study_group_membership_path(membership)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /study_group_memberships" do
    let!(:pending_membership) { create(:study_group_membership, user: student, study_group: study_group, status: :pending) }
    let!(:approved_membership) { create(:study_group_membership, user: other_student, study_group: study_group, status: :approved) }

    context "when creator views" do
      before { sign_in teacher }

      it "shows pending requests" do
        get study_group_memberships_path(study_group_id: study_group.id)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(student.name)
      end
    end

    context "when admin views" do
      before { sign_in admin }

      it "shows pending requests" do
        get study_group_memberships_path(study_group_id: study_group.id)
        expect(response).to have_http_status(:success)
      end
    end

    context "when non-creator views" do
      before { sign_in other_student }

      it "denies access" do
        get study_group_memberships_path(study_group_id: study_group.id)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
