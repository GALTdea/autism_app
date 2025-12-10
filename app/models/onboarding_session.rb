class OnboardingSession < ApplicationRecord
  belongs_to :child_profile
  belongs_to :user
end
