require 'time_range'

class FunnelReport < ApplicationReport
	def initialize(config)
		@config = config
		@config['filters'] ||= []
		load_time_range
	end

	def profiles_at_step(step_index)
		events = funnel(step_index)
		external_ids = []
		events.each do |event|
			if external_ids.index(event[:external_id]) == nil
				external_ids << event[:external_id]
			end
		end
		ProfileFinder.by_external_ids({
			:app_token => @config['app_token'],
			:external_ids => external_ids
		})
	end

	def funnel(stop_at_index = nil)
		convergance = []
		previous_step_events = []
		first_step = true
		@config['steps'].each_with_index do |step, index|
			events_at_step = EventFinder.by_type_and_properties({
				:app_token => @config['app_token'],
				:time_range => @time_range,
				:type => step,
				:properties => @config['filters'][index] || {}
			})

			if first_step
				events_at_step.each do |event|
					previous_step_events << {
						:external_id => event['external_id'],
						:happened_at => event['happened_at']
					}
				end
				convergance << events_at_step.count
			else
				current_step_events = []
				count = 0
				events_at_step.each do |event|
					match = previous_step_events.find do |ps_e|
						ps_e[:external_id] == event['external_id'] &&
						ps_e[:happened_at] <= event['happened_at']
					end
					if match
						current_step_events << {
							:external_id => event['external_id'],
							:happened_at => event['happened_at']
						}
						count += 1
						previous_step_events.delete_at(previous_step_events.index(match))
					end
				end
				convergance << count
				previous_step_events = current_step_events
			end
			first_step = false

			unless stop_at_index.nil?
				if index == stop_at_index
					return previous_step_events
				end
			end
		end
		convergance
	end
end