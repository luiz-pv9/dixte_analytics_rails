class SegmentationReport < ApplicationReport

	def initialize(config)
		@report = {}
		@config = config

		load_time_range
		load_events
		detect_steps
		detect_segments
	end

	def load_time_range
		@time_range = TimeRange.new(@config['time_range']['from'], 
			@config['time_range']['to'])
	end

	def load_events
		@events = EventFinder.by_type_and_properties({
			:app_token => @config['app_token'],
			:time_range => @time_range,
			:event_type => @config['event_type'],
			:properties => @config['filters'] || {}
		})
	end

	def detect_steps
		@report['steps'] = @time_range.steps_in(@config['steps_in'])
	end

	def detect_segments
		@report['series'] = {}
		@events.each do |event|
			event_property = event['properties'][@config['segment_on']]
			@report['series'][event_property] ||= []
			index = closest_value_index(@report['steps'], event['happened_at'])
			@report['series'][event_property][index] ||= 0
			@report['series'][event_property][index] += 1
		end
	end

	def to_json
		@report
	end
end