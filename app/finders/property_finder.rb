require 'collections'
require 'property_key'

class PropertyFinder
	@@collection = Collections::Properties.collection

	class << self
		def by_key(key)
			@@collection.find({
				'key' => PropertyKey.normalize(key)
			}).first
		end

		def event(app_token, event_type)
			@@collection.find({
				'key' => PropertyKey.normalize([app_token, event_type])
			}).first
		end

		def event_types(app_token)
			@@collection.find({
				'key' => PropertyKey.normalize(App.event_types_key(app_token))
			}).first
		end

		def profiles(app_token)
			@@collection.find({
				'key' => PropertyKey.normalize(App.profiles_key(app_token))
			}).first
		end
	end
end
