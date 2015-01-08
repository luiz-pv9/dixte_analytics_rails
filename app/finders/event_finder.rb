require 'collections'
require 'data_cleaner'
require 'time_range'

class EventFinder
	@@collection = Collections::Events.collection

	class << self
		def by_type(app_token, type, time_range = nil)
			time_range = TimeRange.new unless time_range
			query = {'app_token' => app_token, 'type' => type}
			time_range.append_to_query('happened_at', query)
			@@collection.find(query)
		end
	end
end