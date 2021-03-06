require 'data_cleaner'
require 'hash_param'
require 'collections'
require 'bson'

class ProfileTracker
	@@collection = Collections::Profiles.collection

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

	def track_update_properties(data, query)
		untrack = {}
		track = {}
		if query['$set']
			query['$set'].each do |key, val|
				prop = key.sub('properties.', '')
				track[prop] = val
				if data['properties'][prop]
					untrack[prop] = data['properties'][prop]
				end
			end
		end

		if query['$unset']
			query['$unset'].each do |key, val|
				prop = key.sub('properties.', '')
				untrack[prop] = data['properties'][prop]
			end
		end

		if query['$push']
			query['$push'].each do |key, val|
				prop = key.sub('properties.', '')
				track[prop] = val
			end
		end

		if query['$pull']
			query['$pull'].each do |key, val|
				prop = key.sub('properties.', '')
				untrack[prop] = val
			end
		end

		if query['$inc']
			query['$inc'].each do |key, val|
				prop = key.sub('properties.', '')
				# Only track an increment operation if the previous value didnt
				# exist
				unless data['properties'][prop]
					track[prop] = val
				end
			end
		end

		if track.size > 0
			PropertyTracker.new(App.profiles_key(data['app_token']), track).track!
		end

		if untrack.size > 0
			PropertyUntracker.new(App.profiles_key(data['app_token']), untrack).untrack!
		end
	end

	def track_insert_properties(data)
		if data['properties'].size > 0
			property_tracker = PropertyTracker.new(App.profiles_key(data['app_token']),
				data['properties'])
			property_tracker.track!
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

			track_update_properties(profile, query)
			query['$set'] ||= {}
			query['$set']['updated_at'] = data['updated_at'] || Time.now.to_i

			if @user
				query['$push'] ||= {}
				query['$push']['modified_by'] = @user.id
			end

			@@collection.find(find_query).update(query)
		else
			track_insert_properties(data)
			data['created_at'] ||= Time.now.to_i
			data['updated_at'] ||= data['created_at']
			if @user
				data['modified_by'] = [@user.id]
			end
			data['_id'] = BSON::ObjectId.new
			@@collection.insert(data)
			return data
		end
	end

	def self.perform(opt)
		ProfileTracker.new().perform(opt)
	end

	def perform(data, user = nil)
		@user = user
		profile_cleaner = ProfileCleaner.new(data)
		if profile_cleaner.clean?
			track_profile data
		else
			profile_cleaner.generate_not_tracked_warn
		end
	end
end

class ProfileCleaner
	@@necessary_keys = ['app_token', 'properties', 'external_id']

	def initialize(data)
		@data = data
		@message = I18n.t('profile.warn.messages.generic')
	end

	def generate_not_tracked_warn
		return false unless @app
		Warn.create({
			:level => Warn::MEDIUM,
			:message => @message,
			:data => @data,
			:app => @app
		})
	end

	def check_data_format
		cleaned = DataCleaner.clean_root_hash(@data, 
			[
				{'app_token' => :json_string_value},
				{'created_at' => :json_numeric_value},
				{'updated_at' => :json_numeric_value},
				{'external_id' => :json_string_value},
				{'properties' => :json_hash_value}
			])

		HashParam.has_all_keys(@@necessary_keys, cleaned)
	end

	def clean_properties(properties)
		cleaned = DataCleaner.clean_hash(properties, [
			:json_simple_value,
			:json_null_value,
			[:json_string_value]
		])

		# Need to check for specific property operations: $inc, $pull and $push
		# In case of $inc, only allowed numeric values.
		# In case of $pull and $push, only allow string values
		# If in the future there is support for array of other values other than
		# strings, this method is gonna need to be changed.
		cleaned.each do |key, val|
			if key.index('$inc') == 0
				unless val.is_a?(Numeric)
					cleaned.delete(key)
					@message = I18n.t('profile.warn.messages.inc')
				end
			end

			if key.index('$pull') == 0 || key.index('$push') == 0
				unless val.is_a?(String)
					cleaned.delete(key)
					@message = I18n.t('profile.warn.messages.push_pull')
				end
			end
		end

		cleaned
	end

	def check_properties
		cleaned_properties = clean_properties(@data['properties'])
		cleaned_properties.size == @data['properties'].size
	end

	def clean?
		@app = App.find_by(:token => @data['app_token'])
		@app && check_data_format && check_properties
	end
end