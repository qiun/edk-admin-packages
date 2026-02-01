class AllocationChange < ApplicationRecord
  belongs_to :region_allocation
  belongs_to :changed_by, class_name: "User"

  validates :previous_allocated, :new_allocated, :previous_sold, :new_sold,
            presence: true

  scope :recent, -> { order(created_at: :desc) }

  def formatted_change
    changes = []

    if previous_allocated != new_allocated
      changes << "Przydzielone pakiety: #{previous_allocated} → #{new_allocated}"
    end
    if previous_sold != new_sold
      changes << "Sprzedane pakiety: #{previous_sold} → #{new_sold}"
    end

    if previous_allocated_posters.present? || new_allocated_posters.present?
      changes << "Przydzielone plakaty: #{previous_allocated_posters || 0} → #{new_allocated_posters || 0}"
    end
    if previous_distributed_posters.present? || new_distributed_posters.present?
      changes << "Wydane plakaty: #{previous_distributed_posters || 0} → #{new_distributed_posters || 0}"
    end

    changes.join(", ")
  end
end
