Rails.application.routes.draw do
  devise_for :users
	match '/track' => 'event_receiver#track', :via => [:get, :post]
	match '/profile' => 'profile_receiver#track', :via => [:get, :post]
end
