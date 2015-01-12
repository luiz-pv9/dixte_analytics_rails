require 'time_range'

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
		if @config['steps_in']
			@report['steps'] = @time_range.steps_in(@config['steps_in'])
		else
			@report['steps'] = @time_range.recommended_steps
		end
	end

	def detect_segments_total
		@events.each do |event|
			if @config['segment_on']
				event_property = event['properties'][@config['segment_on']]
			else
				event_property = @config['event_type']
			end
			event_property ||= 'null'
			@report['series'][event_property] ||= []
			index = closest_value_index(@report['steps'], event['happened_at'])
			@report['series'][event_property][index] ||= 0
			@report['series'][event_property][index] += 1
		end
	end

	def detect_segments_average
		pre_series = {}
		@events.each do |event|
			if @config['segment_on']
				event_property = event['properties'][@config['segment_on']]
			else
				event_property = @config['event_type']
			end
			event_property ||= 'null'

			pre_series[event_property] ||= []
			@report['series'][event_property] ||= []

			index = closest_value_index(@report['steps'], event['happened_at'])
			pre_series[event_property][index] ||= []

			if pre_series[event_property][index].index(event['external_id']) == nil
				pre_series[event_property][index] << event['external_id']
			end

			@report['series'][event_property][index] ||= 0
			@report['series'][event_property][index] += 1
		end

		pre_series.each do |key, val|
			average_series = @report['series'][key].zip(val)
			@report['series'][key] = average_series.map do |con|
				con[0].nil? ? 0 : con[0] / con[1].size
			end
		end
	end

	def detect_segments_unique
		pre_series = {}
		@events.each do |event|
			if @config['segment_on']
				event_property = event['properties'][@config['segment_on']]
			else
				event_property = @config['event_type']
			end
			event_property ||= 'null'
			pre_series[event_property] ||= []

			index = closest_value_index(@report['steps'], event['happened_at'])

			pre_series[event_property][index] ||= []
			if pre_series[event_property][index].index(event['external_id']) == nil
				pre_series[event_property][index] << event['external_id']
			end
		end

		pre_series.each do |key, val|
			@report['series'][key] = val.map { |v| v.nil? ? 0 : v.size }
		end
	end

	def detect_segments
		@report['series'] = {}
		@config['grouping'] ||= 'total'
		case @config['grouping']
		when 'total'
			detect_segments_total
		when 'unique'
			detect_segments_unique
		when 'average'
			detect_segments_average
		end
	end

	def to_json
		@report
	end
end