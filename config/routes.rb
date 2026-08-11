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

      resource :returns, only: [] do
        member do
          patch :status, to: "returns#update_status"
        end
      end
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
