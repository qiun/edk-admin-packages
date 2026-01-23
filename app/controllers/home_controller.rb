class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_based_on_role
  end

  private

  def redirect_based_on_role
    case current_user.role
    when "admin"
      redirect_to admin_root_path
    when "warehouse"
      redirect_to warehouse_root_path
    when "leader"
      redirect_to leader_root_path
    else
      # Fallback to admin for unknown roles
      redirect_to admin_root_path
    end
  end
end
