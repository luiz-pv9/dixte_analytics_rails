require 'tracking_value'
require 'property_key'
require 'collections'

class PropertyUntracker
	attr_reader :key, :properties
	@@collection = Collections::Properties.collection

	def initialize(key, properties)
		@key = PropertyKey.normalize(key)
		@properties = {}
		properties.each do |key, val|
			@properties[key] = TrackingValue.new(val)
		end
	end

	def save!
		document = @@collection.find(:key => @key).first
		return -1 unless document
		property = Property.new(document)
		update_query = {}
		unset_query = {}
		
		total_count = property.total_count
		@properties.each do |prop, val|
			val.to_track_value.each do |track_val|
				# If the property is a large collection, the non_string_track_value will be
				# used to track occurences of values.
				track_val = TrackingValue.non_string_track_value if property.has_large_collection_flag(prop)
				next unless property.find_property(prop, track_val)
				prop_val_count = property.value_count(prop, track_val)

				if prop_val_count <= 1
					unset_query['$unset'] ||= {}
					prop_count = property.value_count(prop)
					if(prop_count <= 1)
						unset_query['$unset']["properties.#{prop}"] = ''
					else
						unset_query['$unset']["properties.#{prop}.values.#{track_val}"] = ''
						update_query['$set'] ||= {}
						update_query['$set']["properties.#{prop}.is_large"] = false
					end
				else
					update_query['$inc'] ||= {}
					# Why there is a prev_val:
					# If it's an array in a large collection, all items will be '*'
					# When untracking it needs to decrement multiple times for the same track_val
					prev_val = update_query['$inc']["properties.#{prop}.values.#{track_val}"]
					update_query['$inc']["properties.#{prop}.values.#{track_val}"] = prev_val ? prev_val - 1 : -1

					# I need to update the property in-memory in order for the prop_val_count to reflect reality
					# of the current status of the property counter.
					# This is crucial because in the next loop, when finding the prop_val_count it will return one
					# less than the current. This will not prevent the update_query to decrement the value (which is
					# performance wasteful), but the end result will be correct, which is more important at the moment.
					property.data["properties"][prop]["values"][track_val] -= 1
				end
				total_count -= 1
			end
		end

		if total_count == 0
			@@collection.find({'key' => @key}).remove()
		else
			@@collection.find({'key' => @key}).update(update_query) if update_query.size > 0
			@@collection.find({'key' => @key}).update(unset_query) if unset_query.size > 0
		end
	end

	alias_method :untrack!, :save!
end
