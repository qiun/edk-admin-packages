module Admin
  class SettlementsController < Admin::BaseController
    before_action :set_settlement, only: [ :show, :mark_paid, :recalculate ]

    def index
      @edition = params[:edition_id] ? Edition.find(params[:edition_id]) : current_edition
      @settlements = Settlement.for_edition(@edition)
                               .includes(:user)
                               .order(:status, :amount_due)

      @summary = {
        total_due: @settlements.sum(:amount_due),
        total_paid: @settlements.sum(:amount_paid),
        pending_count: @settlements.pending.count
      }
    end

    def show
      @orders = @settlement.user.orders.for_edition(@settlement.edition)
      @returns = @settlement.user.returns.where(edition: @settlement.edition)
      @reports = @settlement.user.sales_reports.where(edition: @settlement.edition)
    end

    def mark_paid
      amount = params[:amount].to_d

      @settlement.update!(
        amount_paid: amount,
        status: :paid,
        settled_at: Time.current
      )

      redirect_to admin_settlement_path(@settlement), notice: "Płatność została zarejestrowana"
    end

    def recalculate
      @settlement.recalculate!
      redirect_to admin_settlement_path(@settlement), notice: "Rozliczenie zostało przeliczone"
    end

    def export
      @edition = params[:edition_id] ? Edition.find(params[:edition_id]) : current_edition
      @settlements = Settlement.for_edition(@edition).includes(:user)

      respond_to do |format|
        format.csv { send_data generate_csv(@settlements), filename: "rozliczenia-#{@edition.year}.csv" }
      end
    end

    private

    def set_settlement
      @settlement = Settlement.find(params[:id])
    end

    def generate_csv(settlements)
      require "csv"

      CSV.generate(headers: true) do |csv|
        csv << [ "Lider", "Email", "Wysłane", "Zwrócone", "Sprzedane", "Cena/szt", "Do zapłaty", "Wpłacone", "Status" ]

        settlements.each do |s|
          csv << [
            s.user.full_name,
            s.user.email,
            s.total_sent,
            s.total_returned,
            s.total_sold,
            s.price_per_unit,
            s.amount_due,
            s.amount_paid,
            s.status
          ]
        end
      end
    end
  end
end
