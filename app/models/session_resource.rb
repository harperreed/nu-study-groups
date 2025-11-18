# ABOUTME: SessionResource model for file attachments to sessions
# ABOUTME: Supports prep materials, notes, and recordings via ActiveStorage
class SessionResource < ApplicationRecord
  belongs_to :session
  belongs_to :uploaded_by, class_name: 'User'

  has_one_attached :file

  enum resource_type: { prep: 0, notes: 1, recording: 2 }

  validates :title, presence: true
end
