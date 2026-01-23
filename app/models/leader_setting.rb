class LeaderSetting < ApplicationRecord
  belongs_to :user
  belongs_to :edition

  validates :user_id, uniqueness: { scope: :edition_id }
  validates :custom_price, numericality: { greater_than: 0 }, allow_nil: true
end
