Rails.application.routes.draw do
  #Auth routes
  post 'auth/login', action: :login, controller: 'authenticate'
  post 'auth/google', action: :login_google, controller: 'authenticate'
  post 'auth/twitter', action: :login_twitter, controller: 'authenticate'
  post 'auth/logout', action: :logout, controller: 'authenticate'

  #User routes
  post 'users', action: :create, controller: 'users'
  get 'users/me', action: :get_me, controller: 'users'
  put 'users/me', action: :update_me, controller: 'users'

  #Account routes
  get 'accounts', action: :get_all, controller: 'accounts'
  get 'accounts/:id', action: :get, controller: 'accounts'
  get 'accounts/my', action: :get_my_accounts, controller: 'accounts'
  get 'accounts/images/:id', action: :get_images, controller: 'accounts'
  get 'accounts/followers/:id', action: :get_followers, controller: 'accounts'
  get 'accounts/following/:id', action: :get_followed, controller: 'accounts'
  post 'accounts', action: :create, controller: 'accounts'
  post 'accounts/images/:id', action: :upload_image, controller: 'accounts'
  post 'accounts/follow/:id', action: :follow, controller: 'accounts'
  put 'accounts/:id', action: :update, controller: 'users'
  delete 'accounts/unfollow/:id', action: :unfollow, controller: 'accounts'
  #delete 'users/delete/:id', action: :delete, controller: 'users'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # images routes
  get 'images/:id', action: :show, controller: 'images'
  delete 'images/:id', action: :delete, controller: 'accounts'

end
