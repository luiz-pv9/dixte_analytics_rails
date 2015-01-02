require 'tracking_value'
require 'property_key'

class PropertyTracker
	attr_reader :key, :properties
	@@collection = MongoHelper.database.collection 'properties'

	def initialize(key, properties)
		@key = PropertyKey.normalize(key)
		@properties = {}
		properties.each do |key, val|
			@properties[key] = TrackingValue.new(val)
		end
	end

	def save!(force_update_types = false)
		document = @@collection.find_one(:key => @key)
		unless document
			document = {'key' => @key, 'properties' => {}}
			@@collection.insert(document)
		end
		property = Property.new(document)

		update_query = {}
		@properties.each do |p, v|
			if !property.has_property(p) or force_update_types
				update_query['$set'] ||= {}
				update_query['$set']["properties.#{p}.type"] = v.type.to_s
			end
			v.to_track_value.each do |v_val|
				update_query['$inc'] ||= {}
				update_query['$inc']["properties.#{p}.values.#{v_val}"] = 1
			end
		end
		@@collection.update({'key' => @key}, update_query)
	end
end
