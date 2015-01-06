require 'data_cleaner'
require 'hash_param'

class ProfileTracker
	include Sidekiq::Worker

	@@necessary_keys = ['app_token', 'properties', 'external_id']

	def generate_not_tracked_warn(data, app)
		Warn.create({
			:level => Warn::MEDIUM,
			:message => 'Profile was not tracked due to invalid attributes.',
			:data => data,
			:app => app
		})
	end

	def check_data_format(data, app)
		has_all_keys = HashParam.has_all_keys(@@necessary_keys, data)
		has_valid_values = DataCleaner.is_hash_cleaned(data.expect('properties'), [:json_string_value])

		unless has_all_keys && has_valid_values
			generate_not_tracked_warn(data, app)
			return false
		end
		return true
	end

	def clean_properties(data)
		DataCleaner.clean_hash(data, [
			:json_simple_value,
			[:json_string_value]
		])
	end

	def check_properties(data, app)
		cleaned_properties = clean_properties(data['properties'])

		if cleaned_properties.size == data['properties'].size
			return true
		else
			generate_not_tracked_warn(data, app)
		end
	end

	def find_app(data)
		App.find_by(:token => data['app_token'])
	end

	def perform(data)
		app = find_app(data)
		return -1 unless app
		if check_data_format(data, app)
			if check_properties(data, app)
			end
		end
	end
end