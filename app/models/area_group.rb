class AreaGroup < ApplicationRecord
  belongs_to :leader, class_name: "User", optional: true
  belongs_to :edition

  has_many :orders
  has_many :regions, dependent: :destroy

  validates :name, presence: true
end
