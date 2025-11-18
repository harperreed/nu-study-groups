# ABOUTME: Authorization policy for Course model
# ABOUTME: Only admins can create, update, or delete courses; all can view
class CoursePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin?
  end

  def destroy?
    user&.admin?
  end
end
