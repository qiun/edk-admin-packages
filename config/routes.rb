Rails.application.routes.draw do
  devise_for :users

  # Admin panel - only for admin users (warehouse users have limited access to inventory only)
  authenticate :user, ->(u) { u.admin? || u.warehouse? } do
    namespace :admin do
      root "dashboard#index"

      resources :editions do
        member do
          post :activate
          post :lock_ordering
          post :unlock_ordering
        end
      end

      resources :users do
        collection do
          get :import
          post :import, action: :process_import
        end
        member do
          post :lock_ordering
          post :unlock_ordering
        end
      end

      resource :inventory, only: [ :show, :edit, :update ] do
        post :add_stock
        get :movements
      end

      resources :orders do
        member do
          post :confirm
          post :cancel
          get :print_label
        end
      end

      resources :shipments, only: [ :index, :show ] do
        member do
          post :refresh_status
          get :download_waybill
        end
      end

      resources :settlements do
        member do
          post :mark_paid
          post :recalculate
        end
        collection do
          get :export
        end
      end

      resources :donations, only: [ :index, :show ] do
        member do
          post :mark_as_paid
        end
      end
      resources :returns, only: [ :index, :show, :update ] do
        member do
          post :approve
          post :reject
          post :mark_received
        end
      end
      
      resources :notifications, only: [ :index, :show ] do
        member do
          post :mark_read
        end
        collection do
          post :mark_all_read
        end
      end
    end
  end

  # Warehouse panel - for warehouse staff
  authenticate :user, ->(u) { u.warehouse? || u.admin? } do
    namespace :warehouse do
      root "dashboard#index"
      resources :shipments, only: [ :index, :show ]
      resources :donations, only: [ :index, :show ]
      resources :donation_shipments, only: [ :index, :show ] do
        member do
          post :mark_shipped
          post :unmark_shipped
          get :download_waybill
        end
      end
      resources :leader_shipments, only: [ :index, :show ] do
        member do
          post :mark_shipped
          post :unmark_shipped
          get :download_waybill
        end
      end
    end
  end

  # Leader panel - for area leaders
  authenticate :user, ->(u) { u.leader? } do
    namespace :leader do
      root "dashboard#index"
      resources :orders, only: [ :index, :new, :create, :show, :edit, :update ] do
        member do
          post :cancel
        end
      end
      resources :sales_reports, only: [ :index, :new, :create ]
      resources :returns, only: [ :index, :new, :create, :show ]

      resources :regions do
        resource :region_allocation, only: [ :edit, :update ] do
          get :history
        end

        resources :regional_payments, only: [ :index, :new, :create, :show, :destroy ]

        get 'allocation_summary', to: 'regions#allocation_summary'
      end

      resources :region_transfers, only: [ :index, :new, :create, :show, :destroy ]

      get 'regional_reports', to: 'regional_reports#show', as: :regional_reports
      get 'regional_reports/export_csv', to: 'regional_reports#export_csv', as: :export_csv_regional_reports
      get 'regional_reports/export_pdf', to: 'regional_reports#export_pdf', as: :export_pdf_regional_reports
    end
  end

  # Public donation page
  scope module: "public" do
    get "cegielka", to: "donations#new", as: :cegielka
    post "cegielka", to: "donations#create"
    get "cegielka/sukces", to: "donations#success", as: :cegielka_sukces
    get "cegielka/blad", to: "donations#error", as: :cegielka_blad
    post "webhooks/przelewy24", to: "webhooks#przelewy24"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path - redirect based on role
  root "home#index"
end
