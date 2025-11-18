# ABOUTME: SessionResource model for file attachments to sessions
# ABOUTME: Supports prep materials, notes, and recordings via ActiveStorage
class SessionResource < ApplicationRecord
  belongs_to :session
end
