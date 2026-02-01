class AllocationChange < ApplicationRecord
  belongs_to :region_allocation
  belongs_to :changed_by, class_name: "User"

  validates :previous_allocated, :new_allocated, :previous_sold, :new_sold,
            presence: true

  scope :recent, -> { order(created_at: :desc) }

  def formatted_change
    changes = []
    if previous_allocated != new_allocated
      changes << "Przydzielone: #{previous_allocated} → #{new_allocated}"
    end
    if previous_sold != new_sold
      changes << "Sprzedane: #{previous_sold} → #{new_sold}"
    end
    changes.join(", ")
  end
end
