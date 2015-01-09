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

	def untrack_event(event)
		untrack_event_properties(event)
		untrack_event_from_app(event)
	end

	def untrack_events(event_ids)
		events = @@collection.find({'_id' => {'$in' => event_ids}})
		events.each do |event|
			untrack_event(event)
		end
		events.remove_all
	end

	def perform(opt)
		if opt[:id]
			untrack_events([opt[:id]])
		end

		if opt[:ids]
			untrack_events(opt[:ids])
		end

		if opt[:external_id]
			events = EventFinder.by_external_id({
				:app_token => opt[:app_token],
				:external_id => opt[:external_id]
			})
			events.each do |event|
				untrack_event(event)
			end
			events.remove_all
		end
	end
end