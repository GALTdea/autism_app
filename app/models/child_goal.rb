class ChildGoal < ApplicationRecord
  belongs_to :child_profile
  belongs_to :profile_domain
end
