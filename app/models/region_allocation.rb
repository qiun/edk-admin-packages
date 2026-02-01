class RegionAllocation < ApplicationRecord
  belongs_to :region
  belongs_to :edition
  belongs_to :created_by, class_name: "User"

  has_many :allocation_changes, dependent: :destroy

  validates :allocated_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :sold_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :sold_quantity, numericality: {
    less_than_or_equal_to: :allocated_quantity,
    message: "nie może być większa niż przydzielona ilość"
  }
  validates :region_id, uniqueness: {
    scope: :edition_id,
    message: "już ma przydzielone pakiety w tej edycji"
  }

  after_update :record_allocation_change, if: :saved_change_to_quantities?

  def remaining_quantity
    allocated_quantity - sold_quantity
  end

  private

  def saved_change_to_quantities?
    saved_change_to_allocated_quantity? || saved_change_to_sold_quantity?
  end

  def record_allocation_change
    allocation_changes.create!(
      previous_allocated: allocated_quantity_before_last_save,
      new_allocated: allocated_quantity,
      previous_sold: sold_quantity_before_last_save,
      new_sold: sold_quantity,
      changed_by: Current.user || created_by,
      reason: Current.change_reason
    )
  end
end
