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
			events = EventFinder.by_type(@app.token, 'visit page', TimeRange.new(1000, 1001))
			expect(events.count).to eq(1)
		end
	end

	def track_events_2
		track_event('click button', {'label' => 'help', 'size' => 2, 'colors' => ['red', 'blue']})
		track_event('click button', {'label' => 'what', 'size' => 1, 'colors' => ['blue', 'yellow']})
		track_event('open modal', {'title' => 'title 1', 'type' => 1})
		track_event('open modal', {'title' => 'title 2', 'type' => 2})
		track_event('open modal', {'title' => 'title 3', 'type' => 2})
	end

	def track_events_2_time
		track_event_at_time('click button', {'label' => 'help', 'size' => 2, 'colors' => ['red', 'blue']}, 1000)
		track_event_at_time('click button', {'label' => 'what', 'size' => 1, 'colors' => ['blue', 'yellow']}, 1001)
		track_event_at_time('open modal', {'title' => 'title 1', 'type' => 1}, 1002)
		track_event_at_time('open modal', {'title' => 'title 2', 'type' => 2}, 1003)
		track_event_at_time('open modal', {'title' => 'title 3', 'type' => 2}, 1004)
	end

	describe '.by_type_with_properties' do
		it 'finds events by type and properties' do
			track_events_2
			events = EventFinder.by_type_and_properties(@app.token, 'click button', {
				'label' => 'what'
			})
			expect(events.count).to eq(1)

			events = EventFinder.by_type_and_properties(@app.token, 'open modal', {
				'type' => 2
			})
			expect(events.count).to eq(2)
		end

		it 'finds events by proeprty simple value' do
			track_events_2
			events = EventFinder.by_type_and_properties(@app.token, 'click button', {
				'size' => 1
			})
			expect(events.count).to eq(1)
		end

		it 'finds events by property numeric value with $gt operator' do
			track_events_2
			events = EventFinder.by_type_and_properties(@app.token, 'click button', {
				'size' => {'$gt' => 1}
			})
			expect(events.count).to eq(1)
		end

		it 'finds events by property numeric value with $lt operator' do
			track_events_2
			events = EventFinder.by_type_and_properties(@app.token, 'click button', {
				'size' => {'$lt' => 2}
			})
			expect(events.count).to eq(1)
		end

		it 'finds events by array property with $in operator' do
			track_events_2
			events = EventFinder.by_type_and_properties(@app.token, 'click button', {
				'colors' => {'$in' => ['blue']}
			})
			expect(events.count).to eq(2)

			events = EventFinder.by_type_and_properties(@app.token, 'click button', {
				'colors' => {'$in' => ['red']}
			})
			expect(events.count).to eq(1)
		end

		it 'finds events by type and properties and time range' do
			track_events_2_time
			events = EventFinder.by_type_and_properties(@app.token, 'click button', {
				'colors' => {'$in' => ['blue']}
			}, TimeRange.new(999, 1000))
			expect(events.count).to eq(1)
		end
	end
end