# ABOUTME: Mailer for study group membership notifications
# ABOUTME: Sends emails for join requests submitted, approved, and rejected
class StudyGroupMailer < ApplicationMailer
  # Notifies the group creator when a student submits a join request
  #
  # @param membership [StudyGroupMembership] The pending membership request
  def join_request_submitted(membership)
    @membership = membership
    @student = membership.user
    @group = membership.study_group
    @creator = @group.creator
    @course = @group.course

    mail(
      to: @creator.email,
      subject: "New join request for #{@group.name}"
    )
  end

  # Notifies the student when their join request is approved
  #
  # @param membership [StudyGroupMembership] The approved membership
  def join_request_approved(membership)
    @membership = membership
    @student = membership.user
    @group = membership.study_group
    @course = @group.course
    @upcoming_sessions = @group.sessions.upcoming.limit(5)

    mail(
      to: @student.email,
      subject: "You've been added to #{@group.name}"
    )
  end

  # Notifies the student when their join request is rejected
  #
  # @param membership [StudyGroupMembership] The rejected membership
  def join_request_rejected(membership)
    @membership = membership
    @student = membership.user
    @group = membership.study_group
    @course = @group.course

    mail(
      to: @student.email,
      subject: "Update on your request for #{@group.name}"
    )
  end
end
