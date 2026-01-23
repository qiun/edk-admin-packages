module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    layout "admin"

    private

    def require_admin!
      unless current_user&.admin?
        redirect_to root_path, alert: "Brak dostępu"
      end
    end

    def current_edition
      @current_edition ||= Edition.current
    end
    helper_method :current_edition
  end
end
