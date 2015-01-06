class HashParam
	class << self
		def has_keys(keys, hash)
			keys.all? do |key|
				hash.key? key
			end
		end
	end
end