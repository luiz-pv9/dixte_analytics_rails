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
end