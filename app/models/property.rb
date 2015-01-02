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

	def total_count
		properties = @data && @data['properties']
		total = 0
		properties && properties.each do |property, val|
			total += value_count(property)
		end
		total
	end

	def value_count(property, value = nil)
		status = find_property(property, value)
		if value
			status == nil ? 0 : status
		else
			status == nil ? 0 : status.values.reduce(0) do |memo, val|
				memo + val
			end
		end
	end

	def find_property(property, value = nil)
		if value
			@data && @data['properties'] && 
				@data['properties'][property] && 
				@data['properties'][property]['values'] && 
				@data['properties'][property]['values'][value]
		else
			@data && @data['properties'] && 
				@data['properties'][property] && 
				@data['properties'][property]['values']
		end
	end
end
