Rails.application.routes.draw do
  root "admin/jobs#index"

  resource :session, only: [:new, :create, :destroy]

  namespace :admin do
    get "pipeline", to: "pipeline#index"
    get "production_logs", to: "production_logs#index"
    patch "production_logs/:id", to: "production_logs#update", as: :production_log

    process_log_routes = {
      profab: "PROFAB",
      procut: "PROCUT",
      profl: "PROFL",
      proprime: "PROPRIME",
      propb: "PROPB",
      proro: "PRORO",
      proguil: "PROGUIL"
    }

    process_log_routes.each do |slug, process_code|
      get slug.to_s, to: "process_logs#index", defaults: { process_code: process_code }, as: slug
      post "#{slug}/logs", to: "process_log_entries#create", defaults: { process_code: process_code }, as: "#{slug}_logs"
      patch "#{slug}/logs/:id", to: "process_log_entries#update", defaults: { process_code: process_code }, as: "#{slug}_log"
      delete "#{slug}/logs/:id", to: "process_log_entries#destroy", defaults: { process_code: process_code }
    end
    resources :fabricators, only: [:index, :create, :edit, :update]

    resources :jobs, only: [:index, :new, :create, :show, :edit, :update, :destroy] do
      member do
        patch :release
      end

      resources :production_logs, only: [:create, :update, :destroy], controller: "fabrication_logs"

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
