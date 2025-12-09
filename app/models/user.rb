class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

# Roles: 0=user, 1=admin, 2=super_admin
enum :role, { user: 0, admin: 1, super_admin: 2 }, default: :user
end
