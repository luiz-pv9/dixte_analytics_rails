require 'tracking_value'

class PropertyTracker

	attr_reader :key, :properties

	def initialize(key, properties)
		@key = key
		if key.is_a? Array
			@key = key.join('#')
		end
		@properties = @properties
	end
end
