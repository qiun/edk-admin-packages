class Edition < ApplicationRecord
  # Enums
  enum :status, { draft: "draft", active: "active", closed: "closed" }

  # Associations
  has_one :inventory, dependent: :destroy
  has_many :area_groups, dependent: :destroy
  has_many :leader_settings, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :donations, dependent: :destroy
  has_many :settlements, dependent: :destroy
  has_many :returns, dependent: :destroy
  has_many :sales_reports, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :year, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :default_price, presence: true, numericality: { greater_than: 0 }
  validates :donor_price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: statuses.keys }

  validate :only_one_active_edition

  # Scopes
  scope :active_edition, -> { find_by(is_active: true) }
  scope :by_year, ->(year) { where(year: year) }
  scope :recent, -> { order(year: :desc, created_at: :desc) }

  # Callbacks
  after_create :create_inventory_record

  # Class methods
  def self.current
    find_by(is_active: true) || order(year: :desc).first
  end

  # Instance methods
  def activate!
    transaction do
      Edition.where.not(id: id).update_all(is_active: false)
      update!(is_active: true, status: :active)
    end
  end

  def lock_ordering!
    update!(ordering_locked: true)
  end

  def unlock_ordering!
    update!(ordering_locked: false)
  end

  private

  def only_one_active_edition
    if is_active && Edition.where(is_active: true).where.not(id: id).exists?
      errors.add(:is_active, "może być tylko jedna aktywna edycja")
    end
  end

  def create_inventory_record
    create_inventory!
  end
end
