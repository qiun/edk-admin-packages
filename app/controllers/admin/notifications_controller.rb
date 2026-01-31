module Admin
  class NotificationsController < Admin::BaseController
    before_action :require_admin! # Only admins can manage notifications

    def index
      @notifications = Notification.for_admins.recent.page(params[:page]).per(20)
    end

    def show
      @notification = Notification.find(params[:id])
      @notification.mark_as_read!
    end

    def mark_read
      @notification = Notification.find(params[:id])
      @notification.mark_as_read!
      redirect_back(fallback_location: admin_notifications_path)
    end

    def mark_all_read
      Notification.for_admins.unread.update_all(read_at: Time.current)
      redirect_back(fallback_location: admin_notifications_path, notice: "Wszystkie powiadomienia oznaczone jako przeczytane")
    end
  end
end
