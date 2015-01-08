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

		def by_type_and_properties(app_token, type, properties, time_range = nil)
			time_range = TimeRange.new unless time_range
			properties = DataCleaner.clean_hash(properties, [
				:json_simple_value,
				{'$gt' => :json_numeric_value},
				{'$lt' => :json_numeric_value},
				{'$in' => [:json_simple_value]}
			])
			query = {'app_token' => app_token}
			properties.each do |key, val|
				query["properties.#{key}"] = val
			end
			time_range.append_to_query('happened_at', query)
			@@collection.find(query)
		end
	end
end