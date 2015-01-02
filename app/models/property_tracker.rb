require 'tracking_value'

class PropertyTracker

	attr_reader :key, :properties
	@@collection = MongoHelper.database.collection 'properties'


	def initialize(key, properties)
		@key = key
		if key.is_a? Array
			@key = key.join('#')
		end
		@properties = properties.map do |value|
			TrackingValue.new value
		end
	end

	def save!
		document = @@collection.find_one(:key => @key)
		property = Property.new document
		insert_query = {}
		update_query = {}
		@properties.each do |p|
			unless property.has_property(p)
			end
		end
	end
end
