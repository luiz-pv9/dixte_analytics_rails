require 'tracking_value'
require 'property_key'

class PropertyUntracker
	attr_reader :key, :properties
	@@collection = MongoHelper.database.collection 'properties'

	def initialize(key, properties)
		@key = PropertyKey.normalize(key)
		@properties = {}
		properties.each do |key, val|
			@properties[key] = TrackingValue.new(val)
		end
	end

	def save!
		document = @@collection.find_one(:key => @key)
		return -1 unless document
		property = Property.new(document)
		update_query = {}
		unset_query = {}
	end
end
