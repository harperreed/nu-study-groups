# ABOUTME: Authorization policy for StudyGroupMembership model
# ABOUTME: Only group creators and admins can approve/reject membership requests
class StudyGroupMembershipPolicy < ApplicationPolicy
  def index?
    user&.admin? || user == record.study_group.creator
  end

  def approve?
    user&.admin? || user == record.study_group.creator
  end

  def reject?
    user&.admin? || user == record.study_group.creator
  end
end
