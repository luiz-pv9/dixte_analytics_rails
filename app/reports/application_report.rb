class ApplicationReport
	def closest_value_index(list, val)
		val = list.min_by { |x| (x.to_f - val).abs }
		list.index(val)
	end

	def load_time_range
		@time_range = TimeRange.new(@config['time_range']['from'], 
			@config['time_range']['to'])
	end

	def detect_steps
		if @config['steps_in']
			@report['steps'] = @time_range.steps_in(@config['steps_in'])
		else
			@report['steps'] = @time_range.recommended_steps
		end
	end
end