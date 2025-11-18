# ABOUTME: FactoryBot factory for creating test session resources
# ABOUTME: Supports prep materials, notes, and recordings
FactoryBot.define do
  factory :session_resource do
    association :session
    association :uploaded_by, factory: [:user, :teacher]
    title { Faker::Lorem.sentence }
    resource_type { :prep }

    trait :notes do
      resource_type { :notes }
    end

    trait :recording do
      resource_type { :recording }
    end
  end
end
