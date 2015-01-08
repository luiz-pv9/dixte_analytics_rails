require 'collections'

# The App model includes the Mongoid::Document API instead of raw interaction
# with the database because there is not performance concern. Also, Mongoid
# helps with common operations (creating, editing, deleting).
class App
	include Mongoid::Document
	include Tokenable

	class << self
		def profile_properties_key(app_token)
			[app_token, 'profiles']
		end

		def event_types_key(app_token)
			[app_token, 'event_types']
		end
	end

	store_in :collection => Collections::Apps.name

	# Fields
	field :name, :type => String

	# Relations
	has_many :warns

	# Validation
	validates_presence_of :name
end