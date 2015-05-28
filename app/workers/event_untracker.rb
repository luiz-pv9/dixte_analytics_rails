require 'collections'
require 'time_range'

class EventUntracker
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

	def untrack_by_query(query)
		query.each do |event|
			untrack_event(event)
		end
		query.remove_all
	end

	def untrack_by_profile(app_token, external_id)
		events = EventFinder.by_external_id({
			:app_token => app_token,
			:external_id => external_id
		})
		untrack_by_query(events)
	end

	def self.perform(opt)
		EventUntracker.new().perform(opt)
	end

	def perform(opt)
		opt.symbolize_keys!
		if opt[:id]
			untrack_events([opt[:id]])
		end

		if opt[:ids]
			untrack_events(opt[:ids])
		end

		if opt[:external_id]
			untrack_by_profile(opt[:app_token], opt[:external_id])
		end

		if opt[:external_ids]
			opt[:external_ids].each do |external_id|
				untrack_by_profile(opt[:app_token], external_id)
			end
		end

		# The time_range option is not a ruby object because the value
		# needs to be put and pulled from redis, so a simple data structure
		# will be much faster
		if opt[:time_range]
			time_range = TimeRange.new(opt[:time_range][:from], opt[:time_range][:to])
			events = EventFinder.by_time_range({
				:app_token => opt[:app_token],
				:time_range => time_range
			})
			untrack_by_query(events)
		end
	end
end