# frozen_string_literal: true

# Mailer for leader order-related emails
class OrderMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  # Send order confirmation email to leader
  # @param order [Order] the order record
  def confirmed(order)
    @order = order
    @user = order.user
    @edition = order.edition

    mail(
      to: @user.email,
      subject: "Twoje zamówienie #{@order.quantity} pakietów EDK zostało potwierdzone"
    )
  end

  # Notify admins about new order
  # @param order [Order] the order record
  def new_order_notification(order)
    @order = order
    @user = order.user

    mail(
      to: User.admin.pluck(:email),
      subject: "[PAKIETY EDK] Nowe zamówienie #{order.quantity} pakietów - #{order.user.full_name}"
    )
  end

  # Notify leader about order status change
  # @param order [Order] the order record
  # @param old_status [String] previous status
  # @param new_status [String] current status
  def status_changed(order, old_status, new_status)
    @order = order
    @user = order.user
    @old_status = old_status
    @new_status = new_status

    mail(
      to: @user.email,
      subject: "Status zamówienia #{@order.id} zmienił się: #{I18n.t("order.status.#{new_status}")}"
    )
  end

  # Send shipment notification email when package is sent
  # @param order [Order] the order record
  # @param tracking_number [String] the shipment tracking number
  def shipment_sent(order, tracking_number)
    @order = order
    @user = order.user
    @tracking_number = tracking_number
    @edition = order.edition

    mail(
      to: @user.email,
      subject: "Twoje pakiety EDK zostały przygotowane i są gotowe do wysyłki!"
    )
  end

  # Notify admins when leader cancels their order
  # @param order [Order] the cancelled order record
  def cancelled_by_leader(order)
    @order = order
    @user = order.user
    @edition = order.edition

    admin_emails = User.admin.pluck(:email)

    mail(
      to: admin_emails,
      subject: "[PAKIETY EDK] Zamówienie anulowane przez lidera - #{@user.full_name}"
    )
  end
end
