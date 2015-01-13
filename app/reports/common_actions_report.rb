require 'collections'

class CommonActionsReport < ApplicationReport
	def initialize(config)
		@config = config
		@config['filters'] ||= []

		# The default time limit is a large amount of time so that it seems
		# there is no time limit. I guess 90 years is enought
		@config['time_limit'] ||= 90.years

		@edge_pairs = []
		load_time_range
	end

	def assign_first_edge(event)
		prev_pair = @edge_pairs.find do |pair|
			pair[:from] && 
			!pair[:to] && 
			pair[:from]['happened_at'] > event['happened_at'] &&
			pair[:external_id] == event['external_id']
		end

		if prev_pair
			prev_pair[:from] = event
		else
			@edge_pairs << {:from => event, :external_id => event['external_id']}
		end
	end

	def assign_second_edge(event)
		prev_pair = @edge_pairs.find do |pair|
			pair[:from] && !pair[:to] && pair[:from]['happened_at'] < event['happened_at'] &&
			pair[:external_id] == event['external_id'] &&
			event['happened_at'] - pair[:from]['happened_at'] <= @config['time_limit']
		end

		if prev_pair
			prev_pair[:to] = event
		else
			@edge_pairs << {:to => event, :external_id => event['external_id']}
		end
	end

	def assign_to_pair(event)
		if event['type'] == @config['events_between'][0]
			assign_first_edge event
		end

		if event['type'] == @config['events_between'][1]
			assign_second_edge event
		end
	end

	def clean_pairs
		@edge_pairs.delete_if do |pair|
			pair[:from].nil? || pair[:to].nil?
		end
	end

	def happens_between_pair(event)
		return false if event['type'] == @config['events_between'][1]

		@edge_pairs.find do |pair|
			pair[:from]['_id'] != event['_id'] &&
			pair[:from]['happened_at'] <= event['happened_at'] &&
			pair[:to]['happened_at'] >= event['happened_at'] &&
			pair[:external_id] == event['external_id']
		end
	end

	def load_from_edges
		events = EventFinder.by_type_and_properties({
			:app_token => @config['app_token'],
			:time_range => @time_range,
			:type => @config['events_between'][0],
			:properties => @config['filters'][0] || {}
		}).sort(:happened_at => 1)
		events.each do |event|
			assign_to_pair(event)
		end
	end

	def load_to_edges
		events = EventFinder.by_type_and_properties({
			:app_token => @config['app_token'],
			:time_range => @time_range,
			:type => @config['events_between'][1],
			:properties => @config['filters'][1] || {}
		}).sort(:happened_at => -1)
		events.each do |event|
			assign_to_pair(event)
		end
	end

	def load_edges
		load_from_edges
		load_to_edges
		clean_pairs
	end

	def common_actions
		load_edges
		common = {}
		events = EventFinder.by_time_range({
			:app_token => @config['app_token'],
			:time_range => @time_range
		})
		events.each do |event|
			if happens_between_pair(event)
				common[event['type']] ||= 0
				common[event['type']] += 1
			end
		end
		common
	end
end