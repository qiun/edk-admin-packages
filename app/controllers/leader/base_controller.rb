module Leader
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_leader!
    layout "admin"  # Use same TailAdmin layout as admin

    private

    def ensure_leader!
      unless current_user.leader?
        redirect_to root_path, alert: "Brak dostępu. Ta sekcja jest tylko dla liderów okręgowych."
      end
    end

    def current_edition
      @current_edition ||= Edition.current
    end
    helper_method :current_edition
  end
end
