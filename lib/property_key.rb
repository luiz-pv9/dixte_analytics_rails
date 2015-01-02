class PropertyKey
	class << self
		def normalize(key)
			if key.is_a? Array
				key.join('#')
			else
				key.to_s
			end
		end
	end
end
