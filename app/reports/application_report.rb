class ApplicationReport
	def closest_value_index(list, val)
		val = xs.min_by { |x| (x.to_f - value).abs }
		list.index(val)
	end
end