class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums
  enum :role, { admin: 0, warehouse: 1, leader: 2 }

  # Validations
  validates :name, presence: true
  validates :role, presence: true

  # Associations (to be added in later phases)
  # belongs_to :okręg, optional: true
end
