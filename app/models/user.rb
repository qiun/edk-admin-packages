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
  has_many :created_users, class_name: "User", foreign_key: "created_by_id", dependent: :nullify
  has_many :area_groups, foreign_key: "leader_id", dependent: :nullify
  has_many :orders, dependent: :destroy
  has_many :sales_reports, dependent: :destroy
  has_many :settlements, dependent: :destroy
  has_many :returns, dependent: :destroy
  has_many :leader_settings, dependent: :destroy

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
    return true if edition.ordering_locked
    leader_settings.find_by(edition: edition)&.ordering_locked || false
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
