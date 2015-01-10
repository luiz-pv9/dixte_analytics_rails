require 'rails_helper'
require 'collections'

describe ProfileAliaser do
	before :each do
		@events = Collections::Events.collection
		@profiles = Collections::Profiles.collection

		@events.find.remove_all
		@profiles.find.remove_all

		@app = App.create :name => 'Dixte'

		@event_tracker = EventTracker.new
		@profile_tracker = ProfileTracker.new
		@profile_aliaser = ProfileAliaser.new
	end

	it 'updates the profile document with the new value' do
		@profile_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'lpvasco',
			'properties' => {}
		})

		expect {
			@profile_aliaser.perform({
				:app_token => @app.token,
				:previous => 'lpvasco',
				:current => 'luizpv9'
			})
		}.to change { @profiles.find.count }.by(0)

		profile = ProfileFinder.by_external_id({
			:app_token => @app.token, 
			:external_id => 'lpvasco'
		})
		expect(profile).to be_nil

		profile = ProfileFinder.by_external_id({
			:app_token => @app.token, 
			:external_id => 'luizpv9'
		})
		expect(profile).to be_truthy
	end


	it 'updates all events of the profile with the new value' do
		@profile_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'lpvasco',
			'properties' => {}
		})
		@event_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'lpvasco',
			'type' => 'click button',
			'properties' => {}
		})
		@event_tracker.perform({
			'app_token' => @app.token,
			'external_id' => 'luizpv9',
			'type' => 'click button',
			'properties' => {}
		})
		@profile_aliaser.perform({
			:app_token => @app.token,
			:previous => 'lpvasco',
			:current => 'luizpv9'
		})

		events = EventFinder.by_external_id({
			:app_token => @app.token,
			:external_id => 'lpvasco'
		})
		expect(events.count).to eq(0)

		events = EventFinder.by_external_id({
			:app_token => @app.token,
			:external_id => 'luizpv9'
		})
		expect(events.count).to eq(2)
	end

	it 'doesnt raise any errors if the profile being aliased doesnt exists' do
		@profile_aliaser.perform({
			:app_token => @app.token,
			:previous => 'lpvasco',
			:current => 'luizpv9'
 		})
	end
end