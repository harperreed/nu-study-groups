# ABOUTME: Authorization policy for StudyGroup model
# ABOUTME: Creators and admins can manage groups; all users can view and create
class StudyGroupPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    user.student? || user.teacher? || user.admin?
  end

  def update?
    user.admin? || record.creator == user
  end

  def destroy?
    user.admin? || record.creator == user
  end
end
