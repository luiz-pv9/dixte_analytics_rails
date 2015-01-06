require 'tracking_value'
require 'property_key'

class PropertyUntracker
	attr_reader :key, :properties
	@@collection = Mongoid::Sessions.default['properties']

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
			track_values = val.to_track_value
			track_values.each do |track_val|
				next unless property.find_property(prop, track_val)
				prop_val_count = property.value_count(prop, track_val)
				if prop_val_count <= 1
					unset_query['$unset'] ||= {}
					prop_count = property.value_count(prop)
					if(prop_count <= 1)
						unset_query['$unset']["properties.#{prop}"] = ''
					else
						unset_query['$unset']["properties.#{prop}.values.#{track_val}"] = ''
					end
				else
					update_query['$inc'] ||= {}
					update_query['$inc']["properties.#{prop}.values.#{track_val}"] = -1
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
