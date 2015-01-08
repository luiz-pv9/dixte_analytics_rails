require 'collections'
require 'data_cleaner'

class ProfileFinder
	@@collection = Collections::Profiles.collection

	class << self
		def by_external_id(opt)
			opt.symbolize_keys!
			@@collection.find({
				:app_token => opt[:app_token],
				:external_id => opt[:external_id]
			}).first
		end

		def by_properties(opt)
			opt.symbolize_keys!
			properties = DataCleaner.clean_hash(opt[:properties], [
				:json_simple_value,
				{'$gt' => :json_numeric_value},
				{'$lt' => :json_numeric_value},
				{'$in' => [:json_simple_value]}
			])
			query = {}
			properties.each do |key, val|
				query["properties.#{key}"] = val
			end
			query['app_token'] = opt[:app_token]
			@@collection.find(query)
		end

		def performed(opt)
			opt.symbolize_keys!
			events = EventFinder.by_type_and_properties({
				:app_token => opt[:app_token], 
				:type => opt[:event_type], 
				:properties => opt[:event_properties], 
				:time_range => opt[:time_range]
			})

			properties = DataCleaner.clean_hash(opt[:profile_properties], [
				:json_simple_value,
				{'$gt' => :json_numeric_value},
				{'$lt' => :json_numeric_value},
				{'$in' => [:json_simple_value]}
			])
			query = {
				'app_token' => opt[:app_token],
				'external_id' => {'$in' => events.distinct('external_id')}
			}
			properties.each do |key, val|
				query["properties.#{key}"] = val
			end

			@@collection.find(query)
		end
	end
end