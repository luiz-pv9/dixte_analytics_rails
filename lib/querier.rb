require 'data_detector'

class Querier
	attr_accessor :query, :config

	def initialize(query, config)
		@query = query
		@config = config
	end
	
	# This needs to be implemented by the subclasses
	def clean
	end

	class << self
		def match_value(placeholder, value)
			# Array type
			if placeholder.is_a? Array
				return false unless value.is_a? Array
				matched_count = 0
				placeholder.each do |p_val|
					value.each do |v_val|
						matched_count += 1 if match_value(p_val, v_val)
					end
				end
				return matched_count == value.size
			end

			# Hash type
			if placeholder.is_a? Hash
				# If the placeholder is a hash, it MUST have size = 1
				return false unless value.is_a? Hash
				any_of_key_matched = false
				any_of_value_matched = false
				placeholder.each do |p_key, p_val|
					value.each do |v_key, v_val|
						any_of_key_matched = true if match_value(p_key, v_key)
						any_of_value_matched = true if match_value(p_val, v_val)
					end
				end
				return any_of_value_matched && any_of_key_matched
			end

			# Native types
			if placeholder.is_a?(String) || placeholder.is_a?(Numeric) || placeholder == true || placeholder == false
				return placeholder == value
			end

			# Symbol types
			return value.is_a?(String) if placeholder == :json_string_value
			return value.is_a?(Numeric) if placeholder == :json_numeric_value
			return (value == true || value == false) if placeholder == :json_boolean_value

			# Simple types
			return DataDetector.detect_json_simple_type(value) if placeholder == :json_simple_value
		end
	end
end

class HashQuerier < Querier
	def initialize(query, config)
		super(query, config)
	end

	def clean
		return {} unless @query.is_a? Hash
		@query.each do |key, val|
			match_count = 0
			@config[:allowed].each do |pattern|
				match_count += 1 if Querier.match_value(pattern, val)
			end

			if val.is_a?(Hash) || val.is_a?(Array)
				@query.delete(key) unless match_count == val.size
			else
				@query.delete(key) unless match_count == 1
			end
		end
	end
end

class ArrayQuerier < Querier
	def initialize(query, config)
		super(query, config)
	end

	def clean
		return [] unless @query.is_a? Array
		cleaned = []
		@query.each do |elm, index|
			cleaned << HashQuerier.new(elm, @config).clean
		end
		cleaned.select { |e| e.size > 0 }
	end
end
