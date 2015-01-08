require 'data_cleaner'

class EventTracker
	include Sidekiq::Worker

	@@necessary_keys = ['app_token', 'external_id', 'type', 'properties']
	@@collection = Collections::Events.collection

	def generate_not_tracked_warn(data, app)
		Warn.create({
			:level => Warn::MEDIUM,
			:message => 'Event was not tracked due to invalid attributes.',
			:data => data,
			:app => app
		})
	end

	def check_data_format(data, app)
		cleaned = DataCleaner.clean_root_hash(data, 
			[
				{'app_token' => :json_string_value},
				{'happened_at' => :json_numeric_value},
				{'external_id' => :json_string_value},
				{'type' => :json_string_value},
				{'properties' => :json_hash_value}
			])

		has_all_valid_keys = HashParam.has_all_keys(@@necessary_keys, cleaned)


		unless has_all_valid_keys
			generate_not_tracked_warn(data, app)
			return false
		end
		return true
	end

	def clean_properties(properties)
		DataCleaner.clean_hash(properties, [
			:json_simple_value,
			:json_null_value,
			[:json_string_value]
		])
	end

	def check_properties(data, app)
		cleaned_properties = clean_properties(data['properties'])

		unless cleaned_properties.size == data['properties'].size
			generate_not_tracked_warn(data, app)
			return false
		end
		return true
	end

	def find_app(data)
		App.find_by(:token => data['app_token'])
	end

	def update_track_query(query, prop, val)
		if val.nil?
			query['$unset'] ||= {}
			query['$unset']["properties.#{prop}"] = ''
		else
			if prop.index('$inc.') == 0
				prop_to_increment = prop.sub('$inc.', '')
				query['$inc'] ||= {}
				query['$inc']["properties.#{prop_to_increment}"] = val
			elsif prop.index('$push.') == 0
				prop_to_increment = prop.sub('$push.', '')
				query['$push'] ||= {}
				query['$push']["properties.#{prop_to_increment}"] = val
			elsif prop.index('$pull.') == 0
				prop_to_increment = prop.sub('$pull.', '')
				query['$pull'] ||= {}
				query['$pull']["properties.#{prop_to_increment}"] = val
			else
				query['$set'] ||= {}
				query['$set']["properties.#{prop}"] = val
			end
		end
	end

	def track_properties(data)
		if data['properties'].size > 0
			property_tracker = PropertyTracker.new([data['app_token'], data['type']], data['properties'])
			property_tracker.track!
		end
	end

	def append_profile_properties(data)
		profile = ProfileFinder.by_external_id(data['app_token'], data['external_id'])
		if profile && profile['properties']
			profile['properties'].each do |key, val|
				data['properties']["acc:#{key}"] = val
			end
		end
	end

	def track_event(data)
		track_properties(data)
		append_profile_properties(data)
		data['happened_at'] ||= Time.now.to_i
		data['_id'] = @@collection.insert(data)
		return data
	end

	def perform(data)
		app = find_app(data)
		return -1 unless app
		if check_data_format(data, app)
			if check_properties(data, app)
				return track_event(data)
			end
		end
	end
end
