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

	def track_event_at_time(type, properties, time, external_id = 'lpvasco')
		@event_tracker.perform({
			'app_token' => @app.token,
			'external_id' => external_id,
			'happened_at' => time,
			'type' => type,
			'properties' => properties
		})
	end

	def track_events_1
		track_event('visit page', {})
		track_event('click button', {})
		track_event('visit page', {})
	end

	def track_events_1_time
		track_event_at_time('visit page', {}, 1000)
		track_event_at_time('click button', {}, 1001)
		track_event_at_time('visit page', {}, 1002)
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

		it 'may specify the range for the events to happen' do
			track_events_1_time
			events = EventFinder.by_type(@app.token, 'visit page')
			expect(events.count).to eq(2)
		end
	end

	def track_events_2
		track_event('click button', {'label' => 'help', 'size' => 2})
		track_event('click button', {'label' => 'what', 'size' => 1})
		track_event('open modal', {'title' => 'title 1'})
		track_event('open modal', {'title' => 'title 2'})
		track_event('open modal', {'title' => 'title 3'})
	end

	describe '.by_type_with_properties' do
		it 'finds events by type and properties' do
			track_events_2
			# events = EventFinder.by_type_with_properties(@app.token, 'click button', {
			# })
		end
	end
end