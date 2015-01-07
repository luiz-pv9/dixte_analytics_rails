require 'data_detector'

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
				return false unless value.is_a? Hash
				keys_matched = []
				pattern.each do |p_key, p_val|
					value.each do |v_key, v_val|
						if JSONMatcher.matches(p_key, v_key) && JSONMatcher.matches(p_val, v_val)
							keys_matched << v_key
						end
					end
				end
				return keys_matched.size == 0 ? false : keys_matched
			end

			# Native types
			if pattern.is_a?(String) || pattern.is_a?(Numeric) || pattern == true || pattern == false
				return pattern == value
			end

			# Symbol types
			return value.nil? if pattern == :json_null_value
			return value.is_a?(String) if pattern == :json_string_value
			return value.is_a?(Numeric) if pattern == :json_numeric_value
			return (value == true || value == false) if pattern == :json_boolean_value
			return value.is_a?(Hash) if pattern == :json_hash_value
			return value.is_a?(Array) if pattern == :json_array_value

			# Simple types
			return DataDetector.detect_json_simple_type(value) if pattern == :json_simple_value
		end	
	end
end