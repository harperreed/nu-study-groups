# ABOUTME: StudyGroup model for organizing study sessions within courses
# ABOUTME: Supports official (teacher-created) and peer (student-created) groups
class StudyGroup < ApplicationRecord
  belongs_to :course
  belongs_to :creator, class_name: 'User'

  has_many :study_group_memberships, dependent: :destroy
  has_many :members, -> { where(study_group_memberships: { status: 'approved' }) }, through: :study_group_memberships, source: :user
  has_many :sessions, dependent: :destroy

  enum group_type: { official: 0, peer: 1 }
  enum status: { active: 0, archived: 1 }

  validates :name, presence: true
  validates :group_type, presence: true

  scope :active, -> { where(status: :active) }
end
