require 'collections'
require 'data_cleaner'

class EventFinder
	@@collection = Collections::Events.collection

	class << self
		def by_type(app_token, type)
			@@collection.find({'app_token' => app_token, 'type' => type})
		end
	end
end