# ABOUTME: Admin controller for admin-only dashboard access
# ABOUTME: Displays platform statistics and recent activity for administrators
module Admin
  class AdminController < ApplicationController
    before_action :authenticate_user!

    def dashboard
      authorize :dashboard, :show?

      # User statistics
      @students_count = User.student.count
      @teachers_count = User.teacher.count
      @admins_count = User.admin.count

      # Course statistics
      @courses_count = Course.count

      # Study group statistics
      @total_groups_count = StudyGroup.count
      @active_groups_count = StudyGroup.active.count
      @archived_groups_count = StudyGroup.archived.count

      # Session statistics
      @total_sessions_count = Session.count
      @upcoming_sessions_count = Session.upcoming.count
      @past_sessions_count = Session.past.count

      # Recent activity (last 10 items)
      @recent_memberships = StudyGroupMembership.includes(:user, :study_group)
                                                .order(created_at: :desc)
                                                .limit(10)

      @recent_sessions = Session.includes(:study_group)
                               .order(created_at: :desc)
                               .limit(10)

      @recent_rsvps = SessionRsvp.includes(:user, :session)
                                 .order(created_at: :desc)
                                 .limit(10)

      # Pending approvals
      @pending_requests_count = StudyGroupMembership.pending.count
    end
  end
end
