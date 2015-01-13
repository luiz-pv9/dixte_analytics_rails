require 'time_range'
require 'collections'
require 'property_segmentation'

class FunnelReport < ApplicationReport

	# This needs to be a unique name to not override any property that the
	# event may have. It's use to propagate the property of an event to segment
	# the funnel in all steps
	@@property_propagation_attribute = '$$f_e_p'

	def initialize(config)
		@config = config
		@config['filters'] ||= []
		load_time_range
	end

	def profiles_at_step(step_index)
		events = funnel({:profiles_at_index => step_index})
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

	def segment_by(opt)
		opt.symbolize_keys!
		segment_at = opt[:step]
		segment_by = opt[:property]
		steps = @config['steps']

		events = EventFinder.by_type_and_properties({
			:app_token => @config['app_token'],
			:time_range => @time_range,
			:type => @config['steps'][segment_at],
			:properties => @config['filters'][segment_at] || {}
		})

		events = Collections.query_to_array(events)
		original_events = events

		up_range = (0..segment_at-1).to_a.reverse!
		down_range = (segment_at+1..steps.size-1).to_a

		# Up in the funnel...
		results = []
		up_range.each do |step|
			result = step_up(step, @config['steps'][step], @config['filters'][step] || {}, segment_by, events)
			events = result[:events]
			segment_by = @@property_propagation_attribute
			results.unshift result[:counts]
		end

		# Pushing the step that has the property the person is looking to segment
		results << PropertySegmentation.new(original_events).segment_by_property(opt[:property])

		events = original_events
		segment_by = opt[:property]

		# And down in the funnel...
		down_range.each do |step|
			result = step_down(step, @config['steps'][step], @config['filters'][step] || {}, segment_by, events)
			events = result[:events]
			segment_by = @@property_propagation_attribute
			results << result[:counts]
		end

		report = {}
		results.each do |key|
			key.each do |prop, val|
				report[prop] ||= []
				report[prop] << val
			end
		end
		report
	end

	# This method is going to return a hash with the count for the current step
	# and the list of the new events to make the previous one
	# This method *changes* the current_events array, deleting any event
	# that doesnt have a match from the upper step
	#
	# The events in the `current_events` must have the property specified in 
	# the property_to_segment param.
	def step_up(step, event_type, event_filters, property_to_segment, current_events)	
		events_at_step = EventFinder.by_type_and_properties({
			:app_token => @config['app_token'],
			:time_range => @time_range,
			:type => event_type,
			:properties => event_filters
		})

		counts = {}
		events_at_step = Collections.query_to_array(events_at_step)
		noticed_events_count = 0
		current_events.each_with_index do |c_event, c_index|
			match = events_at_step.find do |ps_e|
				ps_e['external_id'] == c_event['external_id'] &&
				ps_e['happened_at'] <= c_event['happened_at'] &&
				!ps_e["funnel_matched#{step}"]
			end

			if match
				match["funnel_matched#{step}"] = true
				noticed_events_count += 1
				match['properties'][@@property_propagation_attribute] = 
					c_event['properties'][property_to_segment]
				counts[c_event['properties'][property_to_segment]] ||= 0
				counts[c_event['properties'][property_to_segment]] += 1
			else
				current_events.delete_at(c_index)
			end
		end

		unnoticed_events = events_at_step.size - noticed_events_count
		if unnoticed_events > 0
			counts['undefined'] = unnoticed_events
		end

		return {
			:events => events_at_step,
			:counts => counts
		}
	end

	def step_down(step, event_type, event_filters, property_to_segment, prev_events)
		events_at_step = EventFinder.by_type_and_properties({
			:app_token => @config['app_token'],
			:time_range => @time_range,
			:type => event_type,
			:properties => event_filters
		})

		counts = {}
		events_at_step = Collections.query_to_array(events_at_step)
		events_at_step.each_with_index do |c_event, c_index|
			match = prev_events.find do |ps_e|
				c_event['external_id'] == ps_e['external_id'] &&
				c_event['happened_at'] >= ps_e['happened_at'] &&
				!ps_e["funnel_matched#{step}"]
			end

			if match
				match["funnel_matched#{step}"] = true
				c_event['properties'][@@property_propagation_attribute] = 
					match['properties'][property_to_segment]
				counts[match['properties'][property_to_segment]] ||= 0
				counts[match['properties'][property_to_segment]] += 1
			else
				events_at_step.delete_at(c_index)
			end
		end

		return {
			:events => events_at_step,
			:counts => counts
		}
	end

	def funnel(opt = {})
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

			if opt[:profiles_at_index] != nil
				if index == opt[:profiles_at_index]
					return previous_step_events
				end
			end
		end
		convergance
	end
end