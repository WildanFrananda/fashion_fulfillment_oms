Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :orders, only: [ :create ] do
        collection do
          get :queue
        end
        member do
          patch :status, to: "orders#update_status"
          post :label, to: "orders#generate_label"
        end
        resource :returns, only: [ :create ], controller: "returns"
      end

      resources :returns, only: [] do
        member do
          patch :status, to: "returns#update_status"
        end
      end
    end
  end
  get "/health", to: "health#show"
  get "/orders", to: "orders_dashboard#index"
  post "/orders/:id/print_label", to: "orders_dashboard#print_label", as: "print_label_dashboard"
  get "/orders/:id/label_view", to: "orders_dashboard#label_view", as: "label_view_dashboard"
  post "/orders/:id/dispatch_fleet_pulse", to: "orders_dashboard#dispatch_fleet_pulse", as: "dispatch_fleet_pulse_dashboard"
  patch "/orders/:id/update_status", to: "orders_dashboard#update_status", as: "update_status_dashboard"
end



