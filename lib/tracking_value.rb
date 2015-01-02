require 'data_detector'
class TrackingValue

	@@non_string_track_value = '*'

	attr_accessor :value, :type

	def initialize(value, type = nil)
		@value = value
		@type = type || DataDetector.detect(value)
	end

	def to_track_value
		return [@value] if @type == :string
		return (@value.map do |val|
			if val.is_a? String
				val
			else
				@@non_string_track_value
			end
		end) if @type == :array
		return [@@non_string_track_value]
	end
end
