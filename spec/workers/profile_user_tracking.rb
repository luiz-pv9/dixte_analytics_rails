require 'rails_helper'
require 'collections'

describe ProfileTracker do
	before :each do
		@profile_tracker = ProfileTracker.new
		delete_all
		@app = App.create :name => 'Dixte'
		@user = User.create(:email => 'luiz.pv9@gmail.com', :password => '1234',
			:password_confirmation => '1234')
	end

	it 'tracks the user who created the profile in the modified_by array' do
		profile = @profile_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'lpvasco',
			'properties' => {
				'name' => 'Luiz Paulo'
			}
		}, @user)

		expect(profile['modified_by']).to eq([@user.id])
	end

	it 'tracks the user who updated appending to the modified_by array' do
		profile = @profile_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'lpvasco',
			'properties' => {
				'name' => 'Luiz Paulo'
			}
		}, @user)

		@profile_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'lpvasco',
			'properties' => {
			}
		})

		profile = ProfileFinder.by_external_id({:app_token => @app.token, :external_id => 'lpvasco'})
		expect(profile['modified_by']).to eq([@user.id, @user.id])
	end
end