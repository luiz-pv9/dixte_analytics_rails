require 'collections'

class EventUntracker
	include Sidekiq::Worker
	@@collection = Collections::Events.collection

	def untrack_event_properties(event)
		if event['properties'].size > 0
			property_untracker = PropertyUntracker.new(
				[event['app_token'], event['type']], event['properties'])
			property_untracker.untrack!
		end
	end

	def untrack_event(event_id)
		event = @@collection.find({'_id' => event_id})
		if event.first
			untrack_event_properties(event)
		end
		event.remove
	end

	def untrack_events(event_ids)
		events = @@collection.find({'_id' => {'$in' => event_ids}})
		events.each do |event|
			untrack_event_properties(event)
		end
		events.remove_all
	end

	def perform(event_id)
		if event_id.is_a? Array
			untrack_events(event_id)
		else
			untrack_event(event_id)
		end
	end
end