module Inventory
  class StockAlertService
    LOW_STOCK_THRESHOLD = 50
    
    def initialize(edition)
      @edition = edition
      @inventory = edition.inventory
    end

    def check_and_notify!
      return unless @inventory
      
      available = @inventory.available

      if available <= 0
        notify_out_of_stock!
      elsif available <= LOW_STOCK_THRESHOLD
        notify_low_stock!(available)
      end
    end

    private

    def notify_low_stock!(available)
      # Don't spam - check if we already sent a notification in last 24h
      return if recent_low_stock_notification?

      # Create panel notification
      Notification.notify_low_stock!(edition: @edition, available: available)

      # Send email to admins
      admin_emails = User.where(role: :admin).pluck(:email)
      if admin_emails.any?
        AdminMailer.low_stock_alert(
          edition: @edition,
          available: available,
          admin_emails: admin_emails
        ).deliver_later
      end
    end

    def notify_out_of_stock!
      # Don't spam - check if we already sent a notification in last 24h
      return if recent_out_of_stock_notification?

      # Create panel notification
      Notification.notify_out_of_stock!(edition: @edition)

      # Send email to admins
      admin_emails = User.where(role: :admin).pluck(:email)
      if admin_emails.any?
        AdminMailer.out_of_stock_alert(
          edition: @edition,
          admin_emails: admin_emails
        ).deliver_later
      end
    end

    def recent_low_stock_notification?
      Notification.where(
        edition: @edition,
        notification_type: Notification::LOW_STOCK,
        created_at: 24.hours.ago..
      ).exists?
    end

    def recent_out_of_stock_notification?
      Notification.where(
        edition: @edition,
        notification_type: Notification::OUT_OF_STOCK,
        created_at: 24.hours.ago..
      ).exists?
    end
  end
end
