require 'collections'
require 'tracking_value'
require 'property_key'

# The PropertyTracker class is responsible for storing properties in the database
#
# Everything that needs to have a better performance and absolute control of 
# the queries sent to MongoDB, the Moped driver is used instead of the Mongoid.
class PropertyTracker
	attr_reader :key, :properties

	@@collection = Collections::Properties.collection

	def initialize(key, properties)
		@key = PropertyKey.normalize(key)
		@properties = {}
		properties.each do |key, val|
			@properties[key] = TrackingValue.new(val)
		end
	end

	def save!(force_update_types = false)
		document = PropertyFinder.by_key(@key)
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

      if property.has_large_collection_flag(p)
        # Already has a large collection. Just need to increment the * character.
        update_query['$inc'] ||= {}
        update_query['$inc']["properties.#{p}.values.#{TrackingValue.non_string_track_value}"] = v.to_track_value.size
      elsif property.has_large_collection(p)
        # Needs to convert from a regular collection to a large
        # collection

        # New value to replace previous collection
        values_count = property.value_count(p) + v.to_track_value.size

        # Replace all values with a '*'
        update_query['$set'] ||= {}

        # Setting this flag will make property.has_large_collection_flag
        # return true
        update_query['$set']["properties.#{p}.is_large"] = true
        update_query['$set']["properties.#{p}.values"] = {
          TrackingValue.non_string_track_value => values_count
        }
      else
        v.to_track_value.each do |v_val|
          update_query['$inc'] ||= {}
          update_query['$inc']["properties.#{p}.values.#{v_val}"] = 1
        end
      end
		end
		@@collection.find({'key' => @key}).update(update_query)
	end

	alias_method :track!, :save!
end
