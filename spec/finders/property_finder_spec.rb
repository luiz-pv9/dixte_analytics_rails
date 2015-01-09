require 'rails_helper'
require 'collections'

describe PropertyFinder do

	before :each do
		Collections::Properties.collection.find.remove_all
		Collections::Events.collection.find.remove_all
		Collections::Profiles.collection.find.remove_all
	end

	describe '.by_key' do
		it 'finds the property by the key' do
			tracker = PropertyTracker.new(['foo', 'bar'], {
				'name' => 'what'
			})
			tracker.track!
			property = PropertyFinder.by_key(['foo', 'bar'])
			expect(property.except('_id')).to eq({
				'key' => 'foo#bar',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'what' => 1
						}
					}
				}
			})
		end

		it 'returns nil if no property is found' do
			property = PropertyFinder.by_key(['foo', 'bar'])
			expect(property).to be_nil
		end
	end

	describe '.app_event(token, type)' do
		before :each do
			@app = App.create :name => 'Dixte'
			@event_tracker = EventTracker.new
		end

		it 'returns the property for the specified event type' do
			@event_tracker.perform({
				'app_token' => @app.token,
				'type' => 'click button',
				'external_id' => 'lpvasco',
				'properties' => {
					'label' => 'what'
				}
			})

			property = PropertyFinder.event(@app.token, 'click button')
			expect(property['key']).to eq(@app.token + '#click button')
			expect(property['properties'].size).to eq(1)
		end

		it 'returns nil if no property is found' do
			property = PropertyFinder.event(@app.token, 'click button')
			expect(property).to be_nil
		end
	end

	describe '.app_events(token)' do
		before :each do
			@app = App.create :name => 'Dixte'
			@event_tracker = EventTracker.new
		end

		it 'returns the proprety of list of events of the specified app' do
			@event_tracker.perform({
				'app_token' => @app.token,
				'type' => 'click button',
				'external_id' => 'lpvasco',
				'properties' => {
					'label' => 'what'
				}
			})

			property = PropertyFinder.event_types(@app.token)
			expect(property['key']).to eq(@app.token + '#event_types')
			expect(property['properties']['type']['values']['click button']).to be_truthy
		end

		it 'returns nil if there are no events registered for the app' do
			property = PropertyFinder.event_types(@app.token)
			expect(property).to be_nil
		end
	end

	describe '.profiles(token)' do
		before :each do
			@app = App.create :name => 'Dixte'
			@profile_tracker = ProfileTracker.new
		end

		it 'returns the properties of the profiles for an app' do
			@profile_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'properties' => {
					'name' => 'Luiz Paulo'
				}
			})

			property = PropertyFinder.profiles(@app.token)
			expect(property['key']).to eq(@app.token + '#profiles')
			expect(property['properties']['name']).to be_truthy
		end

		it 'returns nil if no profiles are registered for the app' do
			property = PropertyFinder.profiles(@app.token)
			expect(property).to be_nil
		end
	end
end