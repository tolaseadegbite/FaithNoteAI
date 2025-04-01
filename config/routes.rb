Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "notes#index"

  get "/pricing", to: "pages#pricing"
  get "/home", to: "pages#home"
  get "/privacy", to: "pages#privacy"
  get "/documentation", to: "pages#documentation"
  get "/donations", to: "pages#donations"

  resources :notes do
    resources :note_chats, only: [:create]
    member do
      post :generate_summary
    end
    collection do
      post :generate_summary
      post :quick_record
    end
  end

  resources :bible_verses, only: [:index], path: 'bible' do
    collection do
      get 'search'
    end
  end

  resources :bible_chat_conversations, path: 'bible/chat/conversations' do
    resources :bible_chat_messages, only: [:create], controller: 'bible_chats'
  end
  
  resources :bible_chats, path: 'bible/chat', only: [:index, :create] do
    collection do
      patch :update_translation
    end
  end
  
  get 'bible/:book/:chapter/:verse', to: 'bible_verses#show', as: 'bible_verse'
  get 'bible/:book/:chapter', to: 'bible_verses#chapter', as: 'bible_chapter'
end
