# frozen_string_literal: true

# Mailer for shipment-related emails
class ShipmentMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")
  # Send email when shipment is created and shipped
  # @param shipment [Shipment] the shipment record
  def shipped(shipment)
    @shipment = shipment
    @source = shipment.source # Order or Donation
    @tracking_url = shipment.tracking_url

    # Determine recipient based on source type
    if @source.is_a?(Donation)
      @recipient_email = @source.email
      @recipient_name = "#{@source.first_name} #{@source.last_name}"
    else # Order (leader)
      @recipient_email = @source.user.email
      @recipient_name = @source.user.full_name
    end

    mail(
      to: @recipient_email,
      subject: "Twoja paczka z pakietami EDK została wysłana!"
    )
  end

  # Send email when shipment is delivered
  # @param shipment [Shipment] the shipment record
  def delivered(shipment)
    @shipment = shipment
    @source = shipment.source

    # Determine recipient based on source type
    if @source.is_a?(Donation)
      @recipient_email = @source.email
      @recipient_name = "#{@source.first_name} #{@source.last_name}"
    else # Order (leader)
      @recipient_email = @source.user.email
      @recipient_name = @source.user.full_name
    end

    mail(
      to: @recipient_email,
      subject: "Twoja paczka z pakietami EDK została dostarczona!"
    )
  end
end
