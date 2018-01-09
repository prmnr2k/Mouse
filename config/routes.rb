Rails.application.routes.draw do
  #Auth routes
  post 'auth/login', action: :login, controller: 'authenticate'
  post 'auth/google', action: :login_google, controller: 'authenticate'
  post 'auth/twitter', action: :login_twitter, controller: 'authenticate'
  post 'auth/logout', action: :logout, controller: 'authenticate'

  #User routes
  post 'users', action: :create, controller: 'users'
  post 'users/validate_phone', action: :validate_phone, controller: 'users'
  get 'users/me', action: :get_me, controller: 'users'
  patch 'users/me', action: :update_me, controller: 'users'

  #Account routes
  get 'accounts', action: :get_all, controller: 'accounts'
  get 'accounts/search', action: :search, controller: 'accounts'
  get 'accounts/my', action: :get_my_accounts, controller: 'accounts'
  get 'accounts/:id', action: :get, controller: 'accounts'
  get 'accounts/:account_id/events', action: :get_events, controller: 'accounts'
  get 'accounts/images/:id', action: :get_images, controller: 'accounts'
  get 'accounts/followers/:id', action: :get_followers, controller: 'accounts'
  get 'accounts/following/:id', action: :get_followed, controller: 'accounts'
  post 'accounts', action: :create, controller: 'accounts'
  post 'accounts/images/:account_id', action: :upload_image, controller: 'accounts'
  post 'accounts/follow/:account_id', action: :follow, controller: 'accounts'
  patch 'accounts/:account_id', action: :update, controller: 'accounts'
  delete 'accounts/unfollow/:account_id', action: :unfollow, controller: 'accounts'
  #delete 'users/delete/:id', action: :delete, controller: 'users'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # images routes
  get 'images/:id', action: :show, controller: 'images'
  get 'images/:id/preview', action: :preview, controller: 'images'
  delete 'images/:id', action: :delete_image, controller: 'images'


  # phone validations routes
  get 'phone_validations/codes', action: :get_codes, controller: 'phone_validations'
  post 'phone_validations', action: :create, controller: 'phone_validations'
  patch 'phone_validations', action: :update, controller: 'phone_validations'

  # event routes
  get 'events/search', action: :search, controller: 'events'
  resources :events do
    resources :tickets, except: :index
  end
  post 'events/:id/artist', action: :set_artist, controller: 'events'
  post 'events/:id/venue', action: :set_venue, controller: 'events'
  post 'events/:id/activate', action: :set_active, controller: 'events'
  post 'events/:id/like', action: :like, controller: 'events'
  post 'events/:id/unlike', action: :unlike, controller: 'events'
  get 'events/:id/click', action: :click, controller: 'events'
  get 'events/:id/view', action: :view, controller: 'events'
  get 'events/:id/analytics', action: :analytics, controller: 'events'

  # genre routes
  get 'genres/all', action: :all, controller: 'genres'

  # fan tickets routes
  resources :fan_tickets, except: :update
end
