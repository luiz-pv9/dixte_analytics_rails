class ApplicationReport
	def closest_value_index(list, val)
		val = list.min_by { |x| (x.to_f - val).abs }
		list.index(val)
	end
end