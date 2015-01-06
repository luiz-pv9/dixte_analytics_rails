require 'data_cleaner'

class EventTracker
	include Sidekiq::Worker

	def perform(data)
		cleaned = clean(data)
		if cleaned.size == data.size
			# Store
		else
			# Generate error
		end
	end

	def clean(data)
		DataCleaner.clean_hash(data, [
			:json_simple_value,
			[:json_string_value]
		])
	end
end
