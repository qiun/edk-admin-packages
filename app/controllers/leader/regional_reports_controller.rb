require "csv"

module Leader
  class RegionalReportsController < Leader::BaseController
    before_action :set_edition

    def show
      @regions = current_user.area_groups
                             .flat_map { |ag| ag.regions.for_edition(@edition) }
                             .sort_by(&:name)

      @report_data = @regions.map do |region|
        allocation = region.region_allocations.find_by(edition: @edition)
        {
          region: region,
          allocation: allocation,
          payments_sum: region.regional_payments.for_edition(@edition).sum(:amount),
          payments_count: region.regional_payments.for_edition(@edition).count,
          transfers_in: region.transfers_to.for_edition(@edition).sum(:quantity),
          transfers_out: region.transfers_from.for_edition(@edition).sum(:quantity)
        }
      end

      @totals = {
        regions: @regions.count,
        allocated: @report_data.sum { |d| d[:allocation]&.allocated_quantity || 0 },
        sold: @report_data.sum { |d| d[:allocation]&.sold_quantity || 0 },
        remaining: @report_data.sum { |d| d[:allocation]&.remaining_quantity || 0 },
        payments: @report_data.sum { |d| d[:payments_sum] },
        transfers_in: @report_data.sum { |d| d[:transfers_in] },
        transfers_out: @report_data.sum { |d| d[:transfers_out] }
      }
    end

    def export_csv
      @regions = current_user.area_groups
                             .flat_map { |ag| ag.regions.for_edition(@edition) }
                             .sort_by(&:name)

      csv_data = CSV.generate(headers: true) do |csv|
        csv << [
          "Rejon",
          "Okręg",
          "Osoba kontaktowa",
          "Telefon",
          "Email",
          "Przydzielone",
          "Sprzedane",
          "Pozostałe",
          "Suma płatności",
          "Liczba płatności",
          "Transfery przychodzące",
          "Transfery wychodzące"
        ]

        @regions.each do |region|
          allocation = region.region_allocations.find_by(edition: @edition)
          payments_sum = region.regional_payments.for_edition(@edition).sum(:amount)
          payments_count = region.regional_payments.for_edition(@edition).count
          transfers_in = region.transfers_to.for_edition(@edition).sum(:quantity)
          transfers_out = region.transfers_from.for_edition(@edition).sum(:quantity)

          csv << [
            region.name,
            region.area_group.name,
            region.contact_person,
            region.phone,
            region.email,
            allocation&.allocated_quantity || 0,
            allocation&.sold_quantity || 0,
            allocation&.remaining_quantity || 0,
            payments_sum,
            payments_count,
            transfers_in,
            transfers_out
          ]
        end
      end

      send_data csv_data,
                filename: "raport_regionalny_#{@edition.year}_#{Date.current.strftime('%Y%m%d')}.csv",
                type: "text/csv; charset=utf-8"
    end

    def export_pdf
      # Placeholder for PDF export - requires prawn gem
      # For now, redirect with a notice
      redirect_to leader_regional_report_path,
                  alert: "Eksport PDF będzie dostępny wkrótce. Użyj eksportu CSV."
    end

    private

    def set_edition
      @edition = Edition.find_by(is_active: true) || Edition.last
    end
  end
end
