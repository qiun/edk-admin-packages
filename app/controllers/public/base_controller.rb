module Public
  class BaseController < ApplicationController
    layout "public"
    skip_before_action :authenticate_user!, raise: false

    protected

    def current_edition
      @current_edition ||= Edition.find_by(is_active: true) || Edition.order(year: :desc).first
    end
    helper_method :current_edition
  end
end
