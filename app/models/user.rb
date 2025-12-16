class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles: 0=user, 1=admin, 2=super_admin
  enum :role, { user: 0, admin: 1, super_admin: 2 }, default: :user

  # Associations
  has_many :child_memberships, dependent: :destroy
  has_many :child_profiles, through: :child_memberships
  has_many :primary_child_profiles, class_name: "ChildProfile", foreign_key: "primary_caregiver_id", dependent: :nullify
  has_many :onboarding_sessions, dependent: :destroy
  has_many :ai_documents, class_name: "AiDocument", foreign_key: "created_by_id", dependent: :nullify
end
