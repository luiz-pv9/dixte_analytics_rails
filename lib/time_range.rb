class TimeRange

	def initialize(from = nil, to = nil)
		assign_from(from)
		assign_to(to)
	end

	def assign_default_from_value
		@from = 20.days.ago.to_i
	end

	def assign_default_to_value
		@to = Time.now.to_i
	end

	def assign_from(val)
		if val
			if val.is_a? Time
				@from = val.to_i
			elsif val.is_a? Numeric
				@from = val
			else
				assign_default_from_value
			end
		else
			assign_default_from_value
		end
	end

	def assign_to(val)
		if val
			if val.is_a? Time
				@to = val.to_i
			elsif val.is_a? Numeric
				@to = val
			else
				assign_default_to_value
			end
		else
			assign_default_to_value
		end
	end

	def from
		@from
	end

	def to
		@to
	end

	def to_query(key)
		{key => {'$gte' => @from, '$lte' => @to}}
	end

	def append_to_query(key, query)
		query.merge!(to_query(key))
	end

	def steps_by_interval(interval)
		steps = [@from]
		while steps.last <= @to
			next_step = steps.last + interval
			if next_step <= @to
				steps << next_step
			else
				break
			end
		end
		steps
	end

	def steps_in_hours
		steps_by_interval 1.hour
	end

	def steps_in_days
		steps_by_interval 1.day
	end

	def steps_in_weeks
		steps_by_interval 7.days
	end

	def steps_in_months
		steps_by_interval 1.month
	end

	def steps_in_trimesters
		steps_by_interval 3.months
	end

	def steps_in_semesters
		steps_by_interval 6.months
	end

	def steps_in_years
		steps_by_interval 1.year
	end

	def steps_in(interval)
		case interval
		when 'hours'
			steps_in_hours
		when 'days'
			steps_in_days
		when 'weeks'
			steps_in_weeks
		when 'months'
			steps_in_months
		when 'trimesters'
			steps_in_trimesters
		when 'semesters'
			steps_in_semesters
		when 'years'
			steps_in_years
		end
	end

	# The chart should have 12 ticks at the most, and it's always better to have
	# more details, so 12 ticks always.
	# The division is by 11 because the first value (@from value) is included
	# in the steps, so to be 12 ticks the difference must be divided by 11
	def recommended_interval
		(@to - @from) / 11
	end

	def recommended_steps
		steps_by_interval(recommended_interval)
	end
end