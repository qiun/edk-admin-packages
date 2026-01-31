module Warehouse
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_warehouse_access!
    layout "admin"  # Use same TailAdmin layout as admin

    private

    def ensure_warehouse_access!
      unless current_user.warehouse? || current_user.admin?
        redirect_to root_path, alert: "Brak dostępu. Ta sekcja jest tylko dla pracowników magazynu."
      end
    end

    def current_edition
      @current_edition ||= Edition.current
    end
    helper_method :current_edition
  end
end
