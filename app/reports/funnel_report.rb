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
		events = segment_by({
			:step => 0,
			:property => nil,
			:break_at=> step_index,
			:events => true
		}).last
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
		}).sort(:happened_at => opt[:happened_at_order] || 1)

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
			if opt[:events]
				results.unshift result[:events]
			else
				results.unshift result[:counts]
			end

			# If the user want to see profiles...
			if opt[:break_at] == step
				return results
			end
		end

		if opt[:events]
			results << original_events
		else
			results << PropertySegmentation.new(original_events).segment_by_property(opt[:property])
		end

		# If the user want to see profiles...
		if opt[:break_at] == segment_at
			return results
		end


		events = original_events
		segment_by = opt[:property]

		# And down in the funnel...
		down_range.each do |step|
			result = step_down(step, @config['steps'][step], @config['filters'][step] || {}, segment_by, events)
			events = result[:events]
			segment_by = @@property_propagation_attribute unless segment_by.nil?

			if opt[:events]
				results << result[:events]
			else
				results << result[:counts]
			end

			# If the user want to see profiles...
			if opt[:break_at] == step
				return results
			end
		end

		if opt[:events]
			results
		else
			report = {}
			results.each do |key|
				key.each do |prop, val|
					report[prop] ||= []
					report[prop] << val
				end
			end
			report
		end
	end

	# Calculates the average from the previous step (details_at - 1) to the
	# detailed step (details_at). The average time is calculate per property specified
	# by the property parameter. The segment_at is necessary because the property
	# may change because the details_at may not equals the segmentation step.
	def average_time_from_previous_step(result, details_at, property, segment_at)
		result[details_at-1].delete_if do |ev|
			!ev["funnel_matched#{details_at-1}"]
		end

		previous_segment_property = segment_at == details_at - 1 ? property : @@property_propagation_attribute
		current_segment_property = segment_at == details_at ? property : @@property_propagation_attribute

		total_count = {}
		total_times = {}
		result[details_at-1].each do |event|
			prop = event['properties'][previous_segment_property]
			total_times[prop] ||= 0
			total_times[prop] += event['happened_at']

			total_count[prop] ||= 0
			total_count[prop] += 1
		end

		end_count = {}
		end_times = {}
		result[details_at].each do |event|
			prop = event['properties'][current_segment_property]
			end_times[prop] ||= 0
			end_times[prop] += event['happened_at']

			end_count[prop] ||= 0
			end_count[prop] += 1
		end

		averages = {}
		total_times.each do |key, val|
			averages[key] = {
				:average_time_from_previous_step => (end_times[key] / end_count[key].to_f) - 
					(val / total_count[key].to_f)
			}
		end
		averages
	end

	def segmentation_details(opt)
		details_at = opt['details_at']
		segment_at = opt['step'] || details_at
		result = segment_by({
			:step => segment_at,
			:property => opt['property'],
			:break_at => details_at + 1,
			:events => true,
			:happened_at_order => -1
		})

		if details_at > 0
			details = average_time_from_previous_step(result, 
				details_at, opt['property'] || nil, segment_at)
		else
			details = {}
		end

		current_segment_property = segment_at == details_at ? opt['property'] : @@property_propagation_attribute
		next_segment_property = segment_at == details_at + 1 ? opt['property'] : @@property_propagation_attribute

		result[details_at].each do |ev|
			prop = ev['properties'][current_segment_property]
			details[prop] ||= {}
			details[prop][:profiles_at_step] ||= []

			if details[prop][:profiles_at_step].index(ev['external_id']).nil?
				details[prop][:profiles_at_step] << ev['external_id']
			end
		end

		result[details_at+1].each do |ev|
			prop = ev['properties'][next_segment_property]
			details[prop] ||= {}
			details[prop][:profiles_next_step] ||= []

			if details[prop][:profiles_next_step].index(ev['external_id']).nil?
				details[prop][:profiles_next_step] << ev['external_id']
			end
		end

		unless opt['profiles']
			details.each do |key, val|
				val[:profiles_at_step] = val[:profiles_at_step].size if val[:profiles_at_step]
				val[:profiles_next_step] = val[:profiles_next_step].size if val[:profiles_next_step]
			end
		end
		details
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
		}).sort(:happened_at => 1)

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
		}).sort(:happened_at => 1)

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
		result = segment_by({
			:step => 0,
			:property => nil
		})
		result[nil]
	end
end