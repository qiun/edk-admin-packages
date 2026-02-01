class Region < ApplicationRecord
  belongs_to :area_group
  belongs_to :edition
  belongs_to :created_by, class_name: "User"

  has_many :region_allocations, dependent: :destroy
  has_many :regional_payments, dependent: :destroy
  has_many :transfers_from, class_name: "RegionTransfer",
           foreign_key: :from_region_id, dependent: :restrict_with_error
  has_many :transfers_to, class_name: "RegionTransfer",
           foreign_key: :to_region_id, dependent: :restrict_with_error

  validates :name, presence: true
  validates :name, uniqueness: { scope: [ :area_group_id, :edition_id ],
                                 message: "już istnieje w tym okręgu dla tej edycji" }
  validates :phone, format: { with: /\A\d{9,}\z/, allow_blank: true,
                              message: "musi zawierać co najmniej 9 cyfr" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }

  scope :for_area_group, ->(area_group) { where(area_group: area_group) }
  scope :for_edition, ->(edition) { where(edition: edition) }
  scope :alphabetical, -> { order(:name) }

  def display_name
    contact_person.present? ? "#{name} (#{contact_person})" : name
  end

  def total_allocated
    region_allocations.sum(:allocated_quantity)
  end

  def total_sold
    region_allocations.sum(:sold_quantity)
  end

  def total_paid
    regional_payments.sum(:amount)
  end
end
