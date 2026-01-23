# frozen_string_literal: true

# Mailer for donation-related emails
class DonationMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  # Send payment confirmation email to donor
  # @param donation [Donation] the donation record
  def confirmation(donation)
    @donation = donation
    @edition = donation.edition

    mail(
      to: donation.email,
      subject: "Dziękujemy za wsparcie EDK #{@edition&.year || Time.current.year}!"
    )
  end

  # Send shipment notification email when package is sent
  # @param donation [Donation] the donation record
  # @param tracking_number [String] the shipment tracking number
  def shipment_sent(donation, tracking_number)
    @donation = donation
    @tracking_number = tracking_number
    @edition = donation.edition

    mail(
      to: donation.email,
      subject: "Twój upominek EDK został wysłany!"
    )
  end
end
