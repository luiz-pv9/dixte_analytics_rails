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
		end

		it 'untracks the event properties'
	end

	describe 'untracking by list of ids' do
	end
	
	describe 'untracking by profile'
	describe 'untracking by time range'
end