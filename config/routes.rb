Rails.application.routes.draw do
  root "admin/jobs#index"

  namespace :admin do
    get "pipeline", to: "pipeline#index"
    resources :fabricators, only: [:index, :create, :edit, :update]

    resources :jobs, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        patch :release
      end

      resources :job_processes, only: [] do
        resources :fabrication_logs, only: [:create, :update, :destroy]

        member do
          patch :start
          patch :complete
          patch :hold
          patch :resume
          patch :reopen
        end
      end
    end
  end
end
