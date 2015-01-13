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
			if external_ids.index(event['external_id']) == nil
				external_ids << event['external_id']
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

			# If the user want to see profiles...
			if opt[:break_at] == step
				result[:events]
			end
		end

		# If the user want to see profiles...
		if opt[:break_at] == segment_at
			return original_events
		end

		# Pushing the step that has the property the person is looking to segment
		results << PropertySegmentation.new(original_events).segment_by_property(opt[:property])

		events = original_events
		segment_by = opt[:property]

		# And down in the funnel...
		down_range.each do |step|
			result = step_down(step, @config['steps'][step], @config['filters'][step] || {}, segment_by, events)
			events = result[:events]
			segment_by = @@property_propagation_attribute unless segment_by.nil?
			results << result[:counts]

			# If the user want to see profiles...
			if opt[:break_at] == step
				return result[:events]
			end
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
		current_events.delete_if do |c_event|
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
			end
			!match
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

		events_at_step.delete_if do |c_event|
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
			end

			!match
		end

		return {
			:events => events_at_step,
			:counts => counts
		}
	end

	def funnel(opt = {})
		if opt[:profiles_at_index]
			segment_by({
				:step => 0,
				:property => nil,
				:break_at => opt[:profiles_at_index]
			})
		else
			result = segment_by({
				:step => 0,
				:property => nil
			})
			result[nil]
		end
	end
end