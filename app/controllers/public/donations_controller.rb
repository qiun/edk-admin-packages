module Public
  class DonationsController < Public::BaseController
    def new
      @donation = Donation.new(quantity: 1, want_gift: true)
      @edition = current_edition
      @brick_price = @edition&.donor_brick_price || 30.0
      @shipping_cost = @edition&.donor_shipping_cost || 20.0
    end

    def create
      @edition = current_edition
      @brick_price = @edition&.donor_brick_price || 30.0
      @shipping_cost = @edition&.donor_shipping_cost || 20.0

      @donation = Donation.new(donation_params)
      @donation.edition = @edition
      # Nowa formuła: wysyłka + (ilość × cena_cegiełki)
      @donation.amount = @shipping_cost + (@donation.quantity.to_i * @brick_price)
      @donation.payment_id = generate_payment_id
      @donation.payment_status = "pending"

      ActiveRecord::Base.transaction do
        if @donation.save
          # Reserve inventory for gifts (if available)
          if @donation.want_gift? && @edition&.inventory
            begin
              @edition.inventory.reserve(@donation.quantity)
            rescue Inventory::InsufficientStock => e
              if @edition.check_donation_inventory
                # Inventory checking is enabled - block the donation
                @donation.destroy
                flash.now[:error] = "Przepraszamy, ale nie mamy wystarczającej liczby pakietów w magazynie. Dostępne: #{@edition.inventory.available} szt."
                render :new, status: :unprocessable_entity
                return
              else
                # Inventory checking is disabled - just mark that gift cannot be fulfilled
                @donation.update_column(:gift_pending, true)
              end
            end

            # Check stock levels and notify admins if low
            InventoryServices::StockAlertService.new(@edition).check_and_notify!
          end

          # Create Przelewy24 payment and redirect
          begin
            payment_result = create_przelewy24_payment(@donation)
            redirect_to payment_result[:redirect_url], allow_other_host: true
          rescue Przelewy24::Client::Error => e
            Rails.logger.error "Przelewy24 payment creation failed: #{e.message}"
            @donation.update_column(:payment_status, "failed")
            flash[:error] = "Nie udało się utworzyć płatności. Spróbuj ponownie."
            render :new, status: :unprocessable_entity
          end
        else
          render :new, status: :unprocessable_entity
        end
      end
    end

    def success
      # User returns from Przelewy24 after payment
      # We'll receive payment confirmation via webhook, so just show thank you page
      # Optional: try to find donation by session_id if available in params
      @donation = Donation.find_by(payment_id: params[:session_id]) if params[:session_id].present?
    end

    def error
      # User cancelled payment or payment failed
    end

    private

    def donation_params
      params.require(:donation).permit(
        :email, :first_name, :last_name, :phone, :quantity, :want_gift,
        :locker_code, :locker_name, :locker_address, :locker_city, :locker_post_code,
        :terms_accepted
      )
    end

    def generate_payment_id
      "DON-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
    end

    def create_przelewy24_payment(donation)
      client = Przelewy24::Client.new(
        merchant_id: ENV.fetch("PRZELEWY24_MERCHANT_ID"),
        pos_id: ENV.fetch("PRZELEWY24_POS_ID"),
        api_key: ENV.fetch("PRZELEWY24_API_KEY"),
        crc_key: ENV.fetch("PRZELEWY24_CRC_KEY"),
        sandbox: ENV.fetch("PRZELEWY24_SANDBOX", Rails.env.development?.to_s) == "true"
      )

      # URLs from environment or fallback to generated URLs
      return_url = ENV.fetch("PRZELEWY24_RETURN_URL", cegielka_sukces_url)
      status_url = ENV.fetch("PRZELEWY24_STATUS_URL", webhooks_przelewy24_url)

      client.create_transaction(
        session_id: donation.payment_id,
        amount: donation.amount,
        currency: "PLN",
        description: "Cegiełka EDK #{@edition&.year} - #{donation.quantity} pakiet(y)",
        email: donation.email,
        country: "PL",
        language: "pl",
        url_return: return_url,
        url_status: status_url,
        client: "#{donation.first_name} #{donation.last_name}",
        phone: donation.phone
      )
    end
  end
end
