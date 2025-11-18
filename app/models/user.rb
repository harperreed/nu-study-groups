# ABOUTME: User model for authentication via OAuth (Google/GitHub)
# ABOUTME: Supports three roles: student, teacher, admin with enum
class User < ApplicationRecord
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
