require 'rails_helper'

describe ProfileTracker do

	def valid_app
		App.create :name => 'Dixte'
	end

	def valid_app_token
		valid_app.token
	end

	before :each do
		App.delete_all
		@profile_tracker = ProfileTracker.new
	end

	it 'returns -1 if the app_token is not present in the data' do
		expect(@profile_tracker.perform({'foo' => 'bar'})).to be(-1)
	end

	describe 'warning generation on bad formatted profiles' do
		it 'generates a warn if any property were removed in the cleaning process'
		it 'generates a warn if the properties hash is not present in the data'
		it 'generates a warn if the external_id is not present in the data'
		it 'generates a warn if the properties has invalid attributes'
	end

	describe 'storing the profile'
	describe 'incrementing a property in a profile'
	describe 'appending a value in a property in a profile'
end