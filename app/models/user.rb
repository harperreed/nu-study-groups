# ABOUTME: User model for authentication via OAuth (Google/GitHub)
# ABOUTME: Supports three roles: student, teacher, admin with enum
class User < ApplicationRecord
  has_many :course_teachers, dependent: :destroy
  has_many :teaching_courses, through: :course_teachers, source: :course

  has_many :created_study_groups, class_name: 'StudyGroup', foreign_key: 'creator_id', dependent: :destroy
  has_many :study_group_memberships, dependent: :destroy
  has_many :study_groups, through: :study_group_memberships

  has_many :session_rsvps, dependent: :destroy
  has_many :sessions, through: :session_rsvps

  enum role: { student: 0, teacher: 1, admin: 2 }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  def self.from_omniauth(auth)
    where(provider: auth['provider'], uid: auth['uid']).first_or_create do |user|
      user.email = auth['info']['email']
      user.name = auth['info']['name']
      user.role = :student
    end
  end
end
