class Answer < ApplicationRecord
  belongs_to :onboarding_session
  belongs_to :question
  belongs_to :question_option
end
