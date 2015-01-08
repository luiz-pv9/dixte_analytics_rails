require 'rails_helper'
require 'collections'

describe EventFinder do
	def valid_app
		App.create :name => 'Dixte'
	end

	before :each do
		@app = valid_app
		Collections::Events.collection.find.remove_all
		@event_tracker = EventTracker.new
	end

	def track_event(type, properties, external_id = 'lpvasco')
		@event_tracker.perform({
			'app_token' => @app.token,
			'external_id' => external_id,
			'type' => type,
			'properties' => properties
		})
	end


	def track_events_1
		track_event('visit page', {})
		track_event('click button', {})
		track_event('visit page', {})
	end

	describe '.by_type' do
		it 'finds all events with the specified type' do
			track_events_1
			events = EventFinder.by_type(@app.token, 'visit page')
			expect(events.count).to eq(2)
		end

		it 'returns an empty query if no event is found' do
			track_events_1
			events = EventFinder.by_type(@app.token, 'foobar')
			expect(events.count).to eq(0)
		end
	end

	describe '.by_type_with_properties' do
	end
end