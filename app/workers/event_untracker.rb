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

	def untrack_event_from_app(event)
		property_untracker = PropertyUntracker.new(
			App.event_types_key(event['app_token']),
			{'type' => event['type']}
		)
		property_untracker.untrack!
	end

	def untrack_events(event_ids)
		events = @@collection.find({'_id' => {'$in' => event_ids}})
		events.each do |event|
			untrack_event_properties(event)
			untrack_event_from_app(event)
		end
		events.remove_all
	end

	def perform(opt)
		if opt[:id]
			untrack_events([opt[:id]])
		end
	end
end