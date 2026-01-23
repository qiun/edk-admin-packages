# frozen_string_literal: true

# Mailer for settlement-related emails (for leaders)
class SettlementMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  # Send payment reminder for outstanding settlement
  # @param settlement [Settlement] the settlement record
  def reminder(settlement)
    @settlement = settlement
    @user = settlement.user
    @edition = settlement.edition
    @amount_remaining = settlement.amount_due - settlement.amount_paid

    mail(
      to: @user.email,
      subject: "Przypomnienie o rozliczeniu EDK #{@edition.year} - #{@amount_remaining} zł"
    )
  end

  # Send settlement confirmation
  # @param settlement [Settlement] the settlement record
  def confirmed(settlement)
    @settlement = settlement
    @user = settlement.user
    @edition = settlement.edition

    mail(
      to: @user.email,
      subject: "Rozliczenie EDK #{@edition.year} potwierdzone"
    )
  end

  # Send settlement summary
  # @param settlement [Settlement] the settlement record
  def summary(settlement)
    @settlement = settlement
    @user = settlement.user
    @edition = settlement.edition

    mail(
      to: @user.email,
      subject: "Podsumowanie rozliczenia EDK #{@edition.year}"
    )
  end
end
