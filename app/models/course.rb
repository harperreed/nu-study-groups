# ABOUTME: Course model representing academic courses with assigned teachers
# ABOUTME: Courses are identified by code+semester+year and managed by admins
class Course < ApplicationRecord
  has_many :study_groups, dependent: :destroy
  has_many :course_teachers, dependent: :destroy
  has_many :teachers, through: :course_teachers, source: :user

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: [:semester, :year] }

  default_scope { order(year: :desc, semester: :desc) }
end
