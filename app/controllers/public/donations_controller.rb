module Public
  class DonationsController < Public::BaseController
    def new
      @donation = Donation.new(quantity: 1, want_gift: true)
      @edition = current_edition
      @price_per_unit = @edition&.donor_price || 50.0
    end

    def create
      @edition = current_edition
      @price_per_unit = @edition&.donor_price || 50.0

      @donation = Donation.new(donation_params)
      @donation.edition = @edition
      @donation.amount = @donation.quantity.to_i * @price_per_unit

      ActiveRecord::Base.transaction do
        if @donation.save
          # Reserve inventory for gifts (if available)
          if @donation.want_gift? && @edition&.inventory
            begin
              @edition.inventory.reserve(@donation.quantity)
            rescue Inventory::InsufficientStock
              # Don't block the order - just mark that gift cannot be fulfilled
              @donation.update_column(:gift_pending, true)
            end
            
            # Check stock levels and notify admins if low
            ::Inventory::StockAlertService.new(@edition).check_and_notify!
          end

          # For now, redirect to success page (Przelewy24 integration later)
          # TODO: Create Przelewy24 payment and redirect
          redirect_to cegielka_sukces_path(session_id: @donation.id)
        else
          render :new, status: :unprocessable_entity
        end
      end
    end

    def success
      @donation = Donation.find_by(id: params[:session_id])
    end

    private

    def donation_params
      params.require(:donation).permit(
        :email, :first_name, :last_name, :phone, :quantity, :want_gift,
        :locker_code, :locker_name, :locker_address, :locker_city, :locker_post_code,
        :terms_accepted
      )
    end
  end
end
