class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # NOTE: Removed :registerable - only admins can create user accounts
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  # Password complexity validation
  validate :password_complexity, if: :password_required?

  # Enums
  enum :role, { leader: "leader", warehouse: "warehouse", admin: "admin" }

  # Associations
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :voivodeship, optional: true
  has_many :created_users, class_name: "User", foreign_key: "created_by_id", dependent: :nullify
  has_many :area_groups, foreign_key: "leader_id", dependent: :nullify
  has_many :orders, dependent: :destroy
  has_many :sales_reports, dependent: :destroy
  has_many :settlements, dependent: :destroy
  has_many :returns, dependent: :destroy
  has_many :leader_settings, dependent: :destroy
  has_many :created_regions, class_name: "Region",
           foreign_key: :created_by_id, dependent: :nullify
  has_many :created_allocations, class_name: "RegionAllocation",
           foreign_key: :created_by_id, dependent: :nullify
  has_many :allocation_changes, class_name: "AllocationChange",
           foreign_key: :changed_by_id, dependent: :nullify
  has_many :transferred_packages, class_name: "RegionTransfer",
           foreign_key: :transferred_by_id, dependent: :nullify
  has_many :recorded_payments, class_name: "RegionalPayment",
           foreign_key: :recorded_by_id, dependent: :nullify

  # Validations
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: roles.keys }

  # Scopes
  scope :leaders, -> { where(role: :leader) }
  scope :admins, -> { where(role: :admin) }
  scope :warehouse_staff, -> { where(role: :warehouse) }

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def effective_price_for(edition)
    leader_settings.find_by(edition: edition)&.custom_price || edition.default_price
  end

  def ordering_locked_for?(edition)
    return true if edition.nil? || edition.ordering_locked
    leader_settings.find_by(edition: edition)&.ordering_locked || false
  end

  # Generate a secure password that meets all complexity requirements
  # Returns a 20-character password guaranteed to contain:
  # - At least one uppercase letter (A-Z)
  # - At least one lowercase letter (a-z)
  # - At least one digit (0-9)
  def self.generate_secure_password
    # Guarantee each required character type
    uppercase = ("A".."Z").to_a.sample
    lowercase = ("a".."z").to_a.sample
    digit = ("0".."9").to_a.sample

    # Generate remaining 17 random alphanumeric characters
    remaining = SecureRandom.alphanumeric(17)

    # Combine and shuffle to avoid predictable patterns
    (uppercase + lowercase + digit + remaining).chars.shuffle.join
  end

  private

  def password_complexity
    return if password.blank?

    unless password.match?(/[A-Z]/)
      errors.add(:password, "musi zawierać co najmniej jedną wielką literę")
    end

    unless password.match?(/[a-z]/)
      errors.add(:password, "musi zawierać co najmniej jedną małą literę")
    end

    unless password.match?(/\d/)
      errors.add(:password, "musi zawierać co najmniej jedną cyfrę")
    end
  end

  def password_required?
    !persisted? || password.present? || password_confirmation.present?
  end
end
