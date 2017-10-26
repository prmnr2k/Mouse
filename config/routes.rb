Rails.application.routes.draw do
  #Auth routes
  post 'auth/login', action: :login, controller: 'authenticate'
  post 'auth/login_google', action: :login_google, controller: 'authenticate'
  post 'auth/login_twitter', action: :login_twitter, controller: 'authenticate'
  post 'auth/logout', action: :logout, controller: 'authenticate'

  #User routes
   post 'users/create', action: :create, controller: 'users'

  #Account routes
  get 'accounts/get_all', action: :get_all, controller: 'accounts'
  get 'accounts/get/:id', action: :get, controller: 'accounts'
  get 'accounts/get_me', action: :get_me, controller: 'accounts'
  get 'accounts/get_my_accounts', action: :get_my_accounts, controller: 'accounts'
  get 'accounts/get_images/:id', action: :get_images, controller: 'accounts'
  get 'accounts/get_followers/:id', action: :get_followers, controller: 'accounts'
  get 'accounts/get_followed/:id', action: :get_followed, controller: 'accounts'
  post 'accounts/create', action: :create, controller: 'accounts'
  post 'accounts/upload_image', action: :upload_image, controller: 'accounts'
  post 'accounts/follow/:id', action: :follow, controller: 'accounts'

  #put 'users/update/:id', action: :update, controller: 'users'
  put 'accounts/update_me', action: :update_me, controller: 'accounts'
  delete 'accounts/delete_image/:id', action: :delete_image, controller: 'accounts'
  delete 'accounts/unfollow/:id', action: :unfollow, controller: 'accounts'
  #delete 'users/delete/:id', action: :delete, controller: 'users'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # images routes
  get 'images/get/:id', action: :show, controller: 'images'
end
