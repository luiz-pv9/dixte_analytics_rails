class DataDetector
	# Patterns used to check against string values to detect types
	@@ipv4_pattern = /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
	@@geolocation_pattern = /^geo\(\d+([\.]\d+)?;\d+([\.]\d+)?\)$/

	class << self
		# If the value is of a simple json type, returns it. If not, returns nil
		def detect_json_simple_type(value)
			return :boolean if value == true || value == false
			return :number if value.is_a? Numeric
			return :string if value.is_a? String
		end

		# Returns true if the specified value has a valid format of a ipv4 address
		def is_ipv4_address(value)
			return false unless value.is_a? String
			match = value.match @@ipv4_pattern
			match && 
				match[1].to_i <= 255 && 
				match[2].to_i <= 255 && 
				match[3].to_i <= 255 && 
				match[4].to_i <= 255
		end

		# Detect type of the specified value.  Current possible values are:
		# * boolean - true | false (simple json format)
		# * number - float64 (simple json format)
		# * string - any size (simple json format)
		# * array
		# * ip
		# * geolocation
		#
		# There was also planning for 
		# * Timestamp - Removed because it will be stored as a number, and the filter
		#               can be configured to be a datepicker (and every date in the
		#               system is stored as a number (timestamp).
		# * DateTime - Removed in order to create a standard format (timestamp).
		# * Currency - Removed because it would be stored as a regular number,
		#              and aggregation functions will be provided for all numeric
		#              values, not just currency.
		#		
		def detect(value)
			json_simple_type = detect_json_simple_type value
			if json_simple_type && json_simple_type != :string
				return json_simple_type
			end

			return :array if value.is_a? Array
			return :ip if is_ipv4_address value
			return :geolocation if value.match @@geolocation_pattern
			return :string
		end
	end
end
