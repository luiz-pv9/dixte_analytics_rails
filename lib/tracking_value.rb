require 'data_detector'

# TrackingValue is responsible for converting values to store
# in the properties collection.
class TrackingValue
	@@non_string_track_value = '*'

	attr_accessor :value, :type

  class << self
    attr_reader :non_string_track_value
  end

	def initialize(value, type = nil)
		@value = value
		@type = type || DataDetector.detect(value)
	end

	def to_track_value
		return [@value.to_s] if @type == :string or @type == :number or @type == :boolean
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
