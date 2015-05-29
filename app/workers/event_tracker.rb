require 'data_cleaner'
require 'hash_param'
require 'bson'

# EventTracker is responsible for tracking *OR* updating an event.
# The the API is the same for both (the perform method with the event JSON object).
# If the argument for perform has the '_id' attribute, it's treated as an update.
# If it doesn't have, it's treated as an insert.
class EventTracker
	@@collection = Collections::Events.collection

	def track_properties(data)
		if data['properties'].size > 0
			property_tracker = PropertyTracker.new([data['app_token'], data['type']], data['properties'])
			property_tracker.track!
		end
	end

	def track_event_type(data)
		property_tracker = PropertyTracker.new(App.event_types_key(data['app_token']), {
			'type' => data['type']
		})
		property_tracker.track!
	end

	def append_profile_properties(data)
		profile = ProfileFinder.by_external_id({
			:app_token => data['app_token'], 
			:external_id => data['external_id']
		})
		if profile && profile['properties']
			profile['properties'].each do |key, val|
				data['properties']["acc:#{key}"] = val
			end
		end
	end

	def track_event(data)
		track_properties(data)
		track_event_type(data)
		append_profile_properties(data)
		data['happened_at'] ||= Time.now.to_i
		data['_id'] = BSON::ObjectId.new
		if @user
			data['modified_by'] = [@user.id]
		end
		@@collection.insert(data)
		return data
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
			PropertyTracker.new([data['app_token'], data['type']], track).track!
		end

		if untrack.size > 0
			PropertyUntracker.new([data['app_token'], data['type']], untrack).untrack!
		end
	end

	def track_update_event(event, data)
		query = {}
		data['properties'].each do |key, val|
			update_track_query(query, key, val)
		end
		track_update_properties(event, query)

		# There is gonna need to implement an history of editing of so I'll
		# keep this snipet here:

		# query['$set'] ||= {}
		# query['$set']['updated_at'] = data['updated_at'] || Time.now.to_i

		if @user
			query['$push'] ||= {}
			query['$push']['modified_by'] = @user.id
		end

		@@collection.find({'_id' => data['_id']}).update(query)
	end

	def self.perform(opt)
		EventTracker.new().perform(opt)
	end

	def perform(data, user = nil)
		@user = user
		if data['_id']
			event = EventFinder.by_id(data['_id'])
			return false unless event
			track_update_event(event, data)
		else
			event_cleaner = EventCleaner.new(data)
			if event_cleaner.clean?
				track_event(data)
			else
				event_cleaner.generate_not_tracked_warn
			end
		end
	end
end

class EventCleaner
	@@necessary_keys = ['app_token', 'external_id', 'type', 'properties']

	def initialize(data)
		@data = data
		@message = I18n.t('event.warn.messages.generic')
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
		cleaned = DataCleaner.clean_root_hash(@data, [
			{'app_token' => :json_string_value},
			{'happened_at' => :json_numeric_value},
			{'external_id' => :json_string_value},
			{'type' => :json_string_value},
			{'properties' => :json_hash_value}
		])
		return HashParam.has_all_keys(@@necessary_keys, cleaned)
	end

	def clean_properties(properties)
		DataCleaner.clean_hash(properties, [
			:json_simple_value,
			:json_null_value,
			[:json_string_value]
		])
	end

	def check_properties
		cleaned_properties = clean_properties(@data['properties'])
		return cleaned_properties.size == @data['properties'].size
	end

	def clean?
		@app = App.find_by(:token => @data['app_token'])
		return false unless @app
		check_data_format && check_properties
	end
end
