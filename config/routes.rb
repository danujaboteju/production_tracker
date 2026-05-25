Rails.application.routes.draw do
  root "admin/jobs#index"

  namespace :admin do
    get "pipeline", to: "pipeline#index"

    resources :jobs, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        patch :release
      end
    end
  end
end