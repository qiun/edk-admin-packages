module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin_or_warehouse!

    layout "admin"

    private

    def require_admin_or_warehouse!
      unless current_user&.admin? || current_user&.warehouse?
        redirect_to root_path, alert: "Brak dostępu"
      end
    end

    # For controllers that should be admin-only (not warehouse)
    def require_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: "Brak dostępu. Ta sekcja jest tylko dla administratorów."
      end
    end

    def current_edition
      @current_edition ||= Edition.current
    end
    helper_method :current_edition
  end
end
