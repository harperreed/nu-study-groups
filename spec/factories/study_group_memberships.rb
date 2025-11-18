# ABOUTME: FactoryBot factory for creating test study group memberships
# ABOUTME: Supports pending, approved, and rejected states
FactoryBot.define do
  factory :study_group_membership do
    association :user
    association :study_group
    status { :pending }
    requested_at { Time.current }

    trait :approved do
      status { :approved }
      approved_at { Time.current }
      association :approved_by, factory: [:user, :teacher]
    end

    trait :rejected do
      status { :rejected }
      association :approved_by, factory: [:user, :teacher]
    end
  end
end
