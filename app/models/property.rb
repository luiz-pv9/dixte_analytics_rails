# The Property class represents a document in the properties
# collection managed by the PropertyTracker and PropertyUntracker.
# See app/models/examples/property_tracker.json for an example of a
# document in the properties collection
class Property
	attr_reader :data

	@max_properties = 50

	class << self
    attr_accessor :max_properties
	end

	attr_reader :data

	def initialize(data)
		@data = data
	end

	# Returns true if the specified property is present in the properties
	# hash. This method doesn't verify any content inside the hash
	def has_property(property_name)
		@data && @data['properties'] && @data['properties'][property_name]
	end

	# Returns the key of the property def key
  def key
		@data && @data['key']
	end

	# Returns the id of the property. The id field is generated by MongoDB
	# upon insertion
	def id
		@data && @data['_id']
	end

	# Iterates through each property in the properties hash and sums the
	# total of the count reference for each value in each property.
	def total_count
		properties = @data && @data['properties']
		total = 0
		properties && properties.each do |property, val|
			total += value_count(property)
		end
		total
	end

	# If the value (second parameter) is specified, returns the count
	# reference for the specified value in the specified property.
	# If the value is not specified, iterates through each value for the
	# property and returns the sum of all its count values.
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

	def number_of_values(property = nil)
		if property
			prop = @data && @data['properties'] && @data['properties'][property]
      return 0 unless prop
      return prop['values'].size
		else
			@data && @data['properties'] && @data['properties'].size
		end
	end

	def has_large_collection(property)
		has_large_collection_flag(property) || number_of_values(property) >= Property.max_properties
	end

  def has_large_collection_flag(property)
	  prop = @data && @data['properties'] && @data['properties'][property]
    return prop && prop['is_large'] == true
  end

	# If the value (second parameter) is specified, returns the count
	# reference for the specified value in the specified property.
	# If the value is not specified, returns a map of all values
	# for the specified property.
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
