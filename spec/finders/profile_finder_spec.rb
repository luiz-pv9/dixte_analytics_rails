require 'rails_helper'
require 'collections'

describe ProfileFinder do

	before :each do
		@profiles = Collections::Profiles.collection
		@profile_tracker = ProfileTracker.new

		@profiles.find.remove_all
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

	describe '.by_external_id' do
		it 'finds a profile by the specified external_id' do
			profile = track_profile('lpvasco')
			found = ProfileFinder.by_external_id('lpvasco')
			expect(found).to be_truthy
			expect(found['external_id']).to eq('lpvasco')
		end

		it 'returns nil if no profile is found' do
			profile = ProfileFinder.by_external_id('lpvasco')
			expect(profile).to be_nil
		end
	end

	describe '.by_properties' do
		def store_profiles
			app = 
		end
		it 'finds profiles by the properties they have'
		it 'cleans bad formatted queries'
	end
end