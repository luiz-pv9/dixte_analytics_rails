# The Property class represents a document in the properties
# collection managed by the PropertyTracker and PropertyUntracker

class Property
	attr_reader :data

	def initialize(data)
		@data = data
	end

	def has_property(property_name)
		@data && @data['properties'] && @data['properties'][property_name]
	end

	def key
		@data && @data['key']
	end

	def id
		@data && @data['_id']
	end
end
