# ABOUTME: Authorization policy for Session model
# ABOUTME: Creators and admins can manage sessions; approved members can view
class SessionPolicy < ApplicationPolicy
  def index?
    return false unless user.present?

    # User must be an approved member of the study group or creator or admin
    membership = record.study_group.study_group_memberships.find_by(user: user)
    membership&.approved? || record.study_group.creator == user || user.admin?
  end

  def show?
    return false unless user.present?

    # User must be an approved member of the study group or creator or admin
    membership = record.study_group.study_group_memberships.find_by(user: user)
    membership&.approved? || record.study_group.creator == user || user.admin?
  end

  def create?
    user&.admin? || record.study_group.creator == user
  end

  def update?
    user&.admin? || record.study_group.creator == user
  end

  def destroy?
    user&.admin? || record.study_group.creator == user
  end
end
