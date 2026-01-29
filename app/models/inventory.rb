class Inventory < ApplicationRecord
  belongs_to :edition
  has_many :inventory_moves, dependent: :destroy

  validates :total_stock, :available, :reserved, :shipped, :returned,
            numericality: { greater_than_or_equal_to: 0 }

  def add_stock(quantity, notes: nil, user: nil)
    transaction do
      self.total_stock += quantity
      self.available += quantity
      save!

      record_move(:stock_in, quantity, notes: notes, user: user)
    end
  end

  def reserve(quantity, reference: nil)
    transaction do
      raise InsufficientStock, "Niewystarczająca ilość pakietów na magazynie" if available < quantity

      self.available -= quantity
      self.reserved += quantity
      save!

      record_move(:reserve, quantity, reference: reference)
    end
  end

  def release_reserved(quantity)
    transaction do
      self.reserved -= quantity
      self.available += quantity
      save!

      record_move(:release, quantity)
    end
  end

  def ship(quantity, reference: nil)
    transaction do
      self.reserved -= quantity
      self.shipped += quantity
      save!

      record_move(:ship, quantity, reference: reference)
    end
  end

  def receive_return(quantity, reference: nil)
    transaction do
      self.returned += quantity
      self.available += quantity
      save!

      record_move(:return_received, quantity, reference: reference)
    end
  end

  private

  def record_move(move_type, quantity, notes: nil, user: nil, reference: nil)
    inventory_moves.create!(
      move_type: move_type,
      quantity: quantity,
      notes: notes,
      created_by: user,
      reference_type: reference&.class&.name,
      reference_id: reference&.id
    )
  end

  class InsufficientStock < StandardError; end
end
