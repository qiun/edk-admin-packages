class AreaGroup < ApplicationRecord
  belongs_to :leader, class_name: "User", optional: true
  belongs_to :edition

  has_many :orders

  validates :name, presence: true
end
