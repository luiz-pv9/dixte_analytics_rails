require 'rails_helper'
require 'collections'

describe EventUntracker do
	before :each do
		@app = App.create :name => 'Dixte'
		@events = Collections::Events.collection
		@properties = Collections::Properties.collection

		@events.find.remove_all
		@properties.find.remove_all

		@event_tracker = EventTracker.new
		@event_untracker = EventUntracker.new
	end

	describe 'untracking by id' do
		it 'removes an event by id' do
			expect {
				event = @event_tracker.perform({
					'app_token' => @app.token,
					'external_id' => 'lpvasco',
					'type' => 'click button',
					'properties' => {}
				})
			}.to change { @events.find.count }.by(1)

			event_id = @events.find.first['_id']
			expect {
				@event_untracker.perform({
					:id => event_id
				})
			}.to change { @events.find.count }.by(-1)
		end

		it 'doesnt raise any errors if no event is found for the id' do
			expect {
				event = @event_tracker.perform({
					'app_token' => @app.token,
					'external_id' => 'lpvasco',
					'type' => 'click button',
					'properties' => {}
				})
			}.to change { @events.find.count }.by(1)

			event_id = 'cat'
			expect {
				@event_untracker.perform({
					:id => event_id
				})
			}.to change { @events.find.count }.by(0)
		end

		it 'removes the properties in the event and the reference if there is no events' do
			expect {
				event = @event_tracker.perform({
					'app_token' => @app.token,
					'external_id' => 'lpvasco',
					'type' => 'click button',
					'properties' => {
						'label' => 'Help'
					}
				})
			}.to change { @properties.find.count }.by(2)

			event_id = @events.find.first['_id']
			expect {
				@event_untracker.perform({
					:id => event_id
				})
			}.to change { @properties.find.count }.by(-2)
		end

		it 'untracks the event reference for the app' do
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {
					'label' => 'Help'
				}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {
					'label' => 'Exit'
				}
			})

			event = @events.find.first
			expect {
				@event_untracker.perform({
					:id => event['_id']
				})
			}.to change { @properties.find.count }.by(0)

			event_types = PropertyFinder.event_types(@app.token)
			# Only one reference to click button now
			expect(event_types['properties']['type']['values']['click button']).to eq(1)
		end

		it 'untracks the event properties' do
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {
					'label' => 'Help'
				}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {
					'label' => 'Exit'
				}
			})

			event = @events.find.first
			expect {
				@event_untracker.perform({
					:id => event['_id']
				})
			}.to change { @properties.find.count }.by(0)

			property = PropertyFinder.event(@app.token, 'click button')
			expect(property['properties']['label']['values'].size).to eq(1)
		end
	end

	describe 'untracking by list of ids' do
		# There is no need to test more because the same method is used
		# when untracking by a single id
		it 'may receive a list of event ids to untrack' do
			event = @event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {}
			})
			event = @event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {}
			})

			events_ids = @events.find.distinct(:_id)
			expect {
				@event_untracker.perform({
					:ids => events_ids					
				})
			}.to change { @events.find.count }.by(-2)
		end
	end
	
	describe 'untracking by profile' do
		it 'removes all events of a profile' do
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'luiz',
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'open modal',
				'properties' => {}
			})

			expect {
				@event_untracker.perform({
					:app_token => @app.token,
					:external_id => 'lpvasco'
				})
			}.to change { @events.find.count }.by(-2)
		end

		it 'untracks the properties and reference' do
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {'label' => 'what'}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'luiz',
				'type' => 'click button',
				'properties' => {'label' => 'exit'}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'open modal',
				'properties' => {'size' => 3}
			})

			expect {
				@event_untracker.perform({
					:app_token => @app.token,
					:external_id => 'lpvasco'
				})
			}.to change { @properties.find.count }.by(-1)

			property = PropertyFinder.event_types(@app.token)
			expect(property['properties']['type']['values'].size).to eq(1)

			click_button = PropertyFinder.event(@app.token, 'click button')
			expect(click_button['properties']['label']['values'].size).to eq(1)
		end
	end

	describe 'untracking by time range'
end