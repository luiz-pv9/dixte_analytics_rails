require 'data_cleaner'

class EventTracker
	include Sidekiq::Worker

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
		data['_id'] = @@collection.insert(data)
		return data
	end

	def perform(data)
		event_cleaner = EventCleaner.new(data)
		if event_cleaner.clean?
			track_event(data)
		else
			event_cleaner.generate_not_tracked_warn
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
