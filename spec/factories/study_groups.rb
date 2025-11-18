# ABOUTME: FactoryBot factory for creating test study groups
# ABOUTME: Supports official and peer group types with realistic data
FactoryBot.define do
  factory :study_group do
    association :course
    association :creator, factory: [:user, :teacher]
    name { Faker::Educator.subject }
    description { Faker::Lorem.paragraph }
    group_type { :official }
    status { :active }

    trait :peer do
      group_type { :peer }
      association :creator, factory: :user
    end

    trait :archived do
      status { :archived }
    end
  end
end
