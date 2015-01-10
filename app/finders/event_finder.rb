require 'collections'
require 'data_cleaner'
require 'time_range'

class EventFinder
	@@collection = Collections::Events.collection

	class << self

		# Required keys =>
		# :app_token
		# :type
		# Optional keys =>
		# :time_range
		def by_type(opt)
			opt.symbolize_keys!
			opt[:time_range] ||= TimeRange.new
			query = {'app_token' => opt[:app_token], 'type' => opt[:type]}
			opt[:time_range].append_to_query('happened_at', query)
			@@collection.find(query)
		end

		# Required keys =>
		# :app_token
		# :type
		# :properties
		# Optional keys =>
		# :time_range
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

		# Required keys => 
		# :app_token
		# :external_id
		def by_external_id(opt)
			@@collection.find({
				:app_token => opt[:app_token],
				:external_id => opt[:external_id]
			})
		end

		# Required keys =>
		# :app_token
		# :time_range
		def by_time_range(opt)
			query = {:app_token => opt[:app_token]}
			opt[:time_range] ||= TimeRange.new
			opt[:time_range].append_to_query('happened_at', query)
			@@collection.find(query)
		end
	end
end