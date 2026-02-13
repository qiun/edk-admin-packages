module RetryShipmentHandler
  extend ActiveSupport::Concern

  private

  def ensure_old_shipment_cancelled(shipment)
    return { success: true } unless shipment.apaczka_order_id.present?

    client = Apaczka::Client.new
    cancel_result = client.cancel_order(shipment.apaczka_order_id)

    return { success: true } if cancel_result[:success]

    # Cancel failed - check if already cancelled externally
    status = client.get_order_status(shipment.apaczka_order_id)
    if %w[cancelled canceled failed].include?(status.to_s.downcase)
      { success: true }
    else
      { success: false, error: "Nie udało się anulować poprzedniego zamówienia w aPaczka (status: #{status || 'nieznany'}). Anuluj je ręcznie w panelu aPaczka przed ponowieniem." }
    end
  rescue => e
    Rails.logger.error "Failed to cancel aPaczka order #{shipment.apaczka_order_id}: #{e.message}"
    { success: false, error: "Błąd komunikacji z aPaczka: #{e.message}" }
  end

  def reset_and_retry_shipment(shipment)
    shipment.update!(
      status: "pending",
      apaczka_order_id: nil,
      waybill_number: nil,
      tracking_url: nil,
      label_pdf: nil,
      apaczka_response: nil
    )
    Apaczka::CreateShipmentJob.perform_later(shipment)
  end
end
