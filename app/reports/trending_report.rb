require 'time_range'

class TrendingReport < ApplicationReport
	def initialize(config)
		@report = {}
		@config = config

		load_time_range
		load_events_types
		load_events
		detect_steps
		detect_grouping
	end

	def load_events_types
		if @config['events_types']
			@events_types = @config['events_types']
		else
			event_types = PropertyFinder.event_types(@config['app_token'])
			values = event_types['properties']['type']['values']
			@events_types = values.sort_by { |k, v| v }.first(4).map do |val|
				val[0]
			end
		end
	end

	def load_events
		@events = {}
		@events_types.each do |event_type|
			@events[event_type] = EventFinder.by_type({
				:app_token => @config['app_token'],
				:type => event_type,
				:time_range => @time_range
			})
		end
	end

	def detect_grouping_total
		@events.each do |key, events|
			event_property = key
			events.each do |event|
				@report['series'][event_property] ||= []
				index = closest_value_index(@report['steps'], event['happened_at'])
				@report['series'][event_property][index] ||= 0
				@report['series'][event_property][index] += 1
			end
		end
	end

	def detect_grouping_unique
		@events.each do |key, events|
			event_property = key
			events.each do |event|
				@report['series'][event_property] ||= []
				index = closest_value_index(@report['steps'], event['happened_at'])
				@report['series'][event_property][index] ||= []

				if @report['series'][event_property][index].index(event['external_id']) == nil
					@report['series'][event_property][index] << event['external_id']
				end
			end
			@report['series'][event_property] = @report['series'][event_property].map do |val|
				val.nil? ? 0 : val.size
			end 
		end
	end

	def detect_grouping_average
		@events.each do |key, events|
			event_property = key
			totals = []
			events.each do |event|
				@report['series'][event_property] ||= []
				index = closest_value_index(@report['steps'], event['happened_at'])
				@report['series'][event_property][index] ||= []

				if @report['series'][event_property][index].index(event['external_id']) == nil
					@report['series'][event_property][index] << event['external_id']
				end

				totals[index] ||= 0
				totals[index] += 1
			end
			@report['series'][event_property] = @report['series'][event_property].map.with_index do |val, i|
				val.nil? ? 0 : totals[i] / val.size
			end 
		end
	end

	def detect_grouping
		@report['series'] = {}
		@config['grouping'] ||= 'total'
		case @config['grouping']
		when 'total'
			detect_grouping_total
		when 'unique'
			detect_grouping_unique
		when 'average'
			detect_grouping_average
		end
	end

	def to_json
		@report
	end
end