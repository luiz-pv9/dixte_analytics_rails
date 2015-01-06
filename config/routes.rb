Rails.application.routes.draw do
	match '/track' => 'event_receiver#track', :via => [:get, :post]
	match '/profile' => 'profile_receiver#track', :via => [:get, :post]
end
