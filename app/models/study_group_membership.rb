# ABOUTME: Join model for study group membership with approval workflow
# ABOUTME: Tracks pending, approved, and rejected membership requests
class StudyGroupMembership < ApplicationRecord
  belongs_to :user
  belongs_to :study_group
  belongs_to :approved_by, class_name: 'User', optional: true

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :user_id, uniqueness: {
    scope: :study_group_id,
    conditions: -> { where.not(status: :rejected) },
    message: "already has an active membership request"
  }

  def approve!(approver)
    update!(
      status: :approved,
      approved_by: approver,
      approved_at: Time.current
    )
  end

  def reject!(approver)
    update!(
      status: :rejected,
      approved_by: approver
    )
  end
end
