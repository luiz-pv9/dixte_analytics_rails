require 'rails_helper'
require 'collections'

describe ProfileFinder do

	def valid_app
		App.create :name => 'Dixte'
	end

	before :each do
		@profiles = Collections::Profiles.collection
		@events = Collections::Events.collection
		@profile_tracker = ProfileTracker.new
		@event_tracker = EventTracker.new
		@profiles.find.remove_all
		@events.find.remove_all
		@app = valid_app
	end

	def track_event(type, properties, external_id = 'lpvasco')
		@event_tracker.perform({
			'app_token' => @app.token,
			'external_id' => external_id,
			'type' => type,
			'properties' => properties
		})
	end

	def track_profile(app_token, external_id, properties = nil)
		properties = {'name' => 'Luiz'} unless properties
		@profile_tracker.perform({
			'app_token' => app_token,
			'external_id' => external_id,
			'properties' => properties
		})
	end

	describe '.by_external_id' do
		it 'finds a profile by the specified external_id' do
			app = valid_app
			profile = track_profile(app.token, 'lpvasco')
			found = ProfileFinder.by_external_id({
				:app_token => app.token, 
				:external_id => 'lpvasco'})
			expect(found).to be_truthy
			expect(found['external_id']).to eq('lpvasco')
		end

		it 'returns nil if no profile is found' do
			app = valid_app
			profile = ProfileFinder.by_external_id({:app_token => app.token, 
				:external_id => 'lpvasco'})
			expect(profile).to be_nil
		end
	end

	describe '.by_properties' do
		before :each do
			@app = valid_app
			@profile_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'user1',
				'properties' => {
					'name' => 'User 01',
					'premium' => false,
					'colors' => ['red', 'blue'],
					'age' => 20
				}
			})
			@profile_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'user2',
				'properties' => {
					'name' => 'User 02',
					'premium' => true,
					'colors' => ['red', 'yellow'],
					'age' => 15
				}
			})
			@profile_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'user3',
				'properties' => {
					'name' => 'User 03',
					'premium' => false,
					'colors' => ['blue', 'yellow'],
					'age' => 25
				}
			})
		end

		it 'finds profiles by property string value' do
			profiles = ProfileFinder.by_properties(@app.token, {'name' => 'User 01'})
			expect(profiles.count).to eq(1)
			expect(profiles.first['external_id']).to eq('user1')
		end

		it 'finds profiles by number value with greater than operation' do
			profiles = ProfileFinder.by_properties(@app.token, {'age' => {'$gt' => 19}})
			expect(profiles.count).to eq(2)
			profiles = Collections.query_to_array(profiles)
			expect(profiles[0]['external_id']).to eq('user1')
			expect(profiles[1]['external_id']).to eq('user3')
		end

		it 'finds profiles by number value with less than operation' do
			profiles = ProfileFinder.by_properties(@app.token, {'age' => {'$lt' => 25}})
			expect(profiles.count).to eq(2)
			profiles = Collections.query_to_array(profiles)
			expect(profiles[0]['external_id']).to eq('user1')
			expect(profiles[1]['external_id']).to eq('user2')
		end

		it 'finds profiles by property boolean value' do
			profiles = ProfileFinder.by_properties(@app.token, {'premium' => false})
			expect(profiles.count).to eq(2)
			profiles = Collections.query_to_array(profiles)
			expect(profiles[0]['external_id']).to eq('user1')
			expect(profiles[1]['external_id']).to eq('user3')
		end

		it 'finds profiles by values in array property' do
			profiles = ProfileFinder.by_properties(@app.token, {'colors' => {'$in' => ['yellow']}})
			expect(profiles.count).to eq(2)
			profiles = Collections.query_to_array(profiles)
			expect(profiles[0]['external_id']).to eq('user2')
			expect(profiles[1]['external_id']).to eq('user3')
		end

		it 'cleans bad formatted queries' do
			profiles = ProfileFinder.by_properties(@app.token, {'age' => 20, 'name' => {'$ne' => 'User 01'}})
			expect(profiles.count).to eq(1)
			profiles = Collections.query_to_array(profiles)
			expect(profiles[0]['external_id']).to eq('user1')
		end
	end

	describe '.performed' do

		def track_events_1
			track_profile(@app.token, 'lpvasco', {'type' => 'premium'})
			track_profile(@app.token, 'luiz', {'type' => 'normal'})
			track_profile(@app.token, 'fran')
			track_profile(@app.token, 'cat')

			track_event('click button', {'label' => 'help'}, 'lpvasco')
			track_event('click button', {'label' => 'help'}, 'luiz')
			track_event('click button', {'label' => 'exit'}, 'fran')
		end	

		it 'finds profiles who performed an event with properties' do
			track_events_1
			profiles = ProfileFinder.performed(@app.token, 'click button', {
				'label' => 'help'				
			})
			expect(profiles.count).to eq(2)
		end

		it 'finds profiles who performed an event with properties filtering the profiles with properties' do
			track_events_1
			profiles = ProfileFinder.performed(@app.token, 'click button', {
				'label' => 'help'
			}, nil, {
				'type' => 'premium'
			})
			expect(profiles.count).to eq(1)
		end
	end
end