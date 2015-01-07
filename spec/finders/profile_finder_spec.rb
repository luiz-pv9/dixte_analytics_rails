require 'rails_helper'

describe ProfileFinder do

	before :each do
		@profile_tracker = ProfileTracker.new
	end

	def valid_app
		App.create :name => 'Dixte'
	end

	def track_profile(external_id)
		app = valid_app
		@profile_tracker.perform({
			'app_token' => app.token,
			'external_id' => external_id,
			'properties' => {
				'name' => 'Luiz'
			}
		})
	end

	describe 'finding by external_id' do
		it 'finds a profile by the specified external_id' do
			profile = track_profile('lpvasco')
			found = ProfileFinder.by_external_id('lpvasco')
			expect(found).to be_truthy
			expect(found['external_id']).to eq('lpvasco')
		end
	end
end