module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: [ :show, :edit, :update, :destroy, :lock_ordering, :unlock_ordering ]

    def index
      @users = User.all.order(:role, :last_name, :first_name)
      @users = @users.where(role: params[:role]) if params[:role].present?
      @edition = current_edition

      # Preload leader settings for current edition
      if @edition
        @leader_settings = LeaderSetting.where(
          user_id: @users.select { |u| u.leader? }.map(&:id),
          edition: @edition
        ).index_by(&:user_id)
      else
        @leader_settings = {}
      end
    end

    def show
      @orders = @user.orders.includes(:edition, :shipment).order(created_at: :desc).limit(10)
      @settlements = @user.settlements.includes(:edition).order(created_at: :desc)
    end

    def new
      @user = User.new(role: :leader)
    end

    def create
      @user = User.new(user_params)
      @user.created_by = current_user
      password = SecureRandom.hex(8)
      @user.password = password
      @user.password_confirmation = password

      if @user.save
        # TODO: Send welcome email with password
        # UserMailer.welcome(@user, password).deliver_later
        redirect_to admin_user_path(@user), notice: "Użytkownik został utworzony. Hasło: #{password}"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      if @user.leader? && current_edition
        @leader_setting = @user.leader_settings.find_or_initialize_by(edition: current_edition)
      end
    end

    def update
      # Remove password params if empty
      params_to_use = user_params
      if params_to_use[:password].blank?
        params_to_use = params_to_use.except(:password, :password_confirmation)
      end

      ActiveRecord::Base.transaction do
        if @user.update(params_to_use)
          # Update leader settings if leader and edition exists
          if @user.leader? && current_edition && params[:leader_setting].present?
            leader_setting = @user.leader_settings.find_or_initialize_by(edition: current_edition)
            leader_setting.update!(leader_setting_params)
          end

          redirect_to admin_user_path(@user), notice: "Użytkownik został zaktualizowany"
        else
          @leader_setting = @user.leader_settings.find_or_initialize_by(edition: current_edition) if @user.leader? && current_edition
          render :edit, status: :unprocessable_entity
        end
      end
    end

    def destroy
      if @user.orders.any?
        redirect_to admin_users_path, alert: "Nie można usunąć użytkownika z zamówieniami"
      else
        @user.destroy
        redirect_to admin_users_path, notice: "Użytkownik został usunięty"
      end
    end

    def import
      # Show import form
    end

    def process_import
      require_dependency 'user_csv_importer'

      if params[:file].blank?
        redirect_to import_admin_users_path, alert: "Wybierz plik do importu"
        return
      end

      result = ::UserCsvImporter.new(params[:file], created_by: current_user).call

      if result[:errors].any?
        flash[:alert] = "Import zakończony z błędami: #{result[:errors].join(', ')}"
      end

      redirect_to admin_users_path, notice: "Zaimportowano #{result[:created]} użytkowników"
    end

    def lock_ordering
      edition = current_edition
      setting = @user.leader_settings.find_or_initialize_by(edition: edition)
      setting.update!(ordering_locked: true)
      redirect_to admin_user_path(@user), notice: "Zamawianie zostało zablokowane dla tego lidera"
    end

    def unlock_ordering
      edition = current_edition
      setting = @user.leader_settings.find_by(edition: edition)
      setting&.update!(ordering_locked: false)
      redirect_to admin_user_path(@user), notice: "Zamawianie zostało odblokowane dla tego lidera"
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :first_name, :last_name, :phone, :role, :password, :password_confirmation)
    end

    def leader_setting_params
      params.require(:leader_setting).permit(:custom_price, :ordering_locked)
    end
  end
end
