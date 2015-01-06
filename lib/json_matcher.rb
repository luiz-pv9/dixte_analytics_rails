class JSONMatcher
	class << self
		def matches(pattern, value)
			# Array type
			if pattern.is_a? Array
				return false unless value.is_a? Array
				matched_count = 0
				pattern.each do |p_val|
					value.each do |v_val|
						matched_count += 1 if JSONMatcher.matches(p_val, v_val)
					end
				end
				return matched_count == value.size
			end

			# Hash type
			if pattern.is_a? Hash
				# If the pattern is a hash, it MUST have size = 1
				return false unless value.is_a? Hash
				any_of_key_matched = false
				any_of_value_matched = false
				pattern.each do |p_key, p_val|
					value.each do |v_key, v_val|
						any_of_key_matched = true if JSONMatcher.matches(p_key, v_key)
						any_of_value_matched = true if JSONMatcher.matches(p_val, v_val)
					end
				end
				return any_of_value_matched && any_of_key_matched
			end

			# Native types
			if pattern.is_a?(String) || pattern.is_a?(Numeric) || pattern == true || pattern == false
				return pattern == value
			end

			# Symbol types
			return value.is_a?(String) if pattern == :json_string_value
			return value.is_a?(Numeric) if pattern == :json_numeric_value
			return (value == true || value == false) if pattern == :json_boolean_value

			# Simple types
			return DataDetector.detect_json_simple_type(value) if pattern == :json_simple_value
		end	
	end
end