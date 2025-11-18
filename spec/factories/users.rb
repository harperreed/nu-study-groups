# ABOUTME: FactoryBot factory for creating test users
# ABOUTME: Supports all three roles with realistic fake data
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    provider { 'google_oauth2' }
    sequence(:uid) { |n| "uid#{n}" }
    role { :student }

    trait :teacher do
      role { :teacher }
    end

    trait :admin do
      role { :admin }
    end
  end
end
