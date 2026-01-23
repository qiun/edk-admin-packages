module Settlements
  class Calculator
    def initialize(user, edition)
      @user = user
      @edition = edition
    end

    def call
      settlement = @user.settlements.find_or_initialize_by(edition: @edition)

      # Pobierz dane do obliczeń
      orders = @user.orders.for_edition(@edition).where(status: [:shipped, :delivered])
      returns = @user.returns.where(edition: @edition, status: :received)
      reports = @user.sales_reports.where(edition: @edition)

      # Oblicz sumy
      total_sent = orders.sum(:quantity)
      total_returned = returns.sum(:quantity)
      total_sold = reports.sum(:quantity_sold)

      # Lider płaci tylko za sprzedane pakiety
      price = @user.effective_price_for(@edition)
      amount_due = total_sold * price

      # Zaktualizuj rozliczenie
      settlement.assign_attributes(
        total_sent: total_sent,
        total_returned: total_returned,
        total_sold: total_sold,
        price_per_unit: price,
        amount_due: amount_due
      )

      # Ustaw status na podstawie wpłat
      settlement.status = determine_status(settlement)

      settlement.save!
      settlement
    end

    private

    def determine_status(settlement)
      if settlement.amount_paid.to_d >= settlement.amount_due
        :paid
      elsif settlement.amount_paid.to_d > 0
        :calculated
      else
        :pending
      end
    end
  end
end
