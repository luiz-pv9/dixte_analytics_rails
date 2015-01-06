require 'data_cleaner'

class ProfileTracker
	include Sidekiq::Worker

	def perform(data)
		cleaned = clean(data)
		if cleaned.size == data.size
			unless cleaned.size == 0
				# Store the profile (updating attributes or creating new ones)
			end
		else
			# Generate warn saying properties were removed due to some invalid
			# attributes
		end
	end

	class << self
		def clean(data)
			DataCleaner.clean_hash(data, [
				:json_simple_value,
				[:json_string_value]
			])
		end
	end
end