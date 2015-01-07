require 'data_cleaner'
require 'hash_param'

class ProfileTracker
	include Sidekiq::Worker

	@@necessary_keys = ['app_token', 'properties', 'external_id']
	@@collection = Mongoid::Sessions.default['profiles']

	def generate_not_tracked_warn(data, app)
		Warn.create({
			:level => Warn::MEDIUM,
			:message => 'Profile was not tracked due to invalid attributes.',
			:data => data,
			:app => app
		})
	end

	def check_data_format(data, app)
		cleaned = DataCleaner.clean_root_hash(data, 
			[
				{'app_token' => :json_string_value},
				{'created_at' => :json_numeric_value},
				{'updated_at' => :json_numeric_value},
				{'external_id' => :json_string_value},
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
			elsif prop.index('$append.') == 0
				prop_to_increment = prop.sub('$append.', '')
				query['$push'] ||= {}
				query['$push']["properties.#{prop_to_increment}"] = val
			else
				query['$set'] ||= {}
				query['$set']["properties.#{prop}"] = val
			end
		end
	end

	def track_profile(data)
		find_query = {
			:app_token => data['app_token'], 
			:external_id => data['external_id']
		}
		profile = @@collection.find(find_query).first

		if profile
			current_properties = profile['properties'] || {}
			new_properties = data['properties'] || {}
			query = {}
			new_properties.each do |prop, val|
				update_track_query(query, prop, val)
			end

			query['$set'] ||= {}
			query['$set']['updated_at'] = data['updated_at'] || Time.now.to_i

			@@collection.find(find_query).update(query)
		else
			data['created_at'] ||= Time.now.to_i
			data['updated_at'] ||= data['created_at']
			data['_id'] = @@collection.insert(data)
			return data
		end
	end

	def perform(data)
		app = find_app(data)
		return -1 unless app
		if check_data_format(data, app)
			if check_properties(data, app)
				return track_profile(data)
			end
		end
	end
end