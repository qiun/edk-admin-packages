module RetryShipmentHandler
  extend ActiveSupport::Concern

  private

  CANCELLED_STATUSES = %w[
    cancelled canceled failed anulowane anulowany anulowana
  ].freeze

  def ensure_old_shipment_cancelled(shipment)
    return { success: true } unless shipment.apaczka_order_id.present?

    client = Apaczka::Client.new
    cancel_result = client.cancel_order(shipment.apaczka_order_id)

    # Cancel succeeded or order already cancelled (API may return error for already-cancelled orders)
    if cancel_result[:success]
      { success: true }
    elsif already_cancelled?(cancel_result, client, shipment.apaczka_order_id)
      { success: true }
    else
      { success: false, error: "Nie udało się anulować poprzedniego zamówienia w aPaczka. Anuluj je ręcznie w panelu aPaczka przed ponowieniem. (#{cancel_result[:error]})" }
    end
  rescue => e
    Rails.logger.error "Failed to cancel aPaczka order #{shipment.apaczka_order_id}: #{e.message}"
    { success: false, error: "Błąd komunikacji z aPaczka: #{e.message}" }
  end

  def already_cancelled?(cancel_result, client, order_id)
    # Check if the error message suggests order is already cancelled
    error_msg = cancel_result[:error].to_s.downcase
    return true if CANCELLED_STATUSES.any? { |s| error_msg.include?(s) }

    # Fallback: query order status from API
    status = client.get_order_status(order_id)
    Rails.logger.info "aPaczka order #{order_id} status check: #{status.inspect}"
    CANCELLED_STATUSES.include?(status.to_s.downcase)
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
