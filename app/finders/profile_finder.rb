require 'collections'
require 'data_cleaner'

class ProfileFinder
	@@collection = Collections::Profiles.collection

	class << self
		def by_external_id(app_token, external_id)
			@@collection.find(:app_token => app_token, :external_id => external_id).first
		end

		def by_properties(app_token, properties)
			properties = DataCleaner.clean_hash(properties, [
				:json_simple_value,
				{'$gt' => :json_numeric_value},
				{'$lt' => :json_numeric_value},
				{'$in' => [:json_simple_value]}
			])
			query = {}
			properties.each do |key, val|
				query["properties.#{key}"] = val
			end
			query['app_token'] = app_token
			@@collection.find(query)
		end
	end
end