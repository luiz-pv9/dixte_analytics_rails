require 'json_matcher'

class DataCleaner
	class << self
		def clean_hash(hash, allowed)
			return {} unless hash.is_a? Hash
			clean = hash.clone
			clean.each do |key, val|
				match_count = 0
				allowed.each do |pattern|
					match_count += 1 if JSONMatcher.matches(pattern, val)
				end

				if val.is_a?(Hash)
					if match_count != val.size || match_count == 0
						clean.delete(key)
					end
				else
					clean.delete(key) unless match_count == 1
				end
			end
		end

		def is_hash_cleaned(hash, allowed)
			hash.size == clean_hash(hash, allowed).size
		end

		def clean_array(array, allowed)
			return [] unless array.is_a? Array
			cleaned = []
			array.each do |elm|
				cleaned << clean_hash(elm, allowed)
			end
			cleaned.select { |e| e.size > 0 }
		end

		def is_array_cleaned(array, allowed)
			array.size == clean_array(array, allowed).size
		end
	end
end