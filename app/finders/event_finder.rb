require 'collections'
require 'data_cleaner'
require 'time_range'

class EventFinder
	@@collection = Collections::Events.collection

	class << self
		def by_type(opt)
			opt.symbolize_keys!
			opt[:time_range] ||= TimeRange.new
			query = {'app_token' => opt[:app_token], 'type' => opt[:type]}
			opt[:time_range].append_to_query('happened_at', query)
			@@collection.find(query)
		end

		def by_type_and_properties(opt)
			opt.symbolize_keys!
			opt[:time_range] ||= TimeRange.new
			properties = DataCleaner.clean_hash(opt[:properties], [
				:json_simple_value,
				{'$gt' => :json_numeric_value},
				{'$lt' => :json_numeric_value},
				{'$in' => [:json_simple_value]}
			])
			query = {'app_token' => opt[:app_token]}
			properties.each do |key, val|
				query["properties.#{key}"] = val
			end
			opt[:time_range].append_to_query('happened_at', query)
			@@collection.find(query)
		end
	end
end