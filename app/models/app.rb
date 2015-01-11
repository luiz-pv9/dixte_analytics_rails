require 'collections'

# The App model includes the Mongoid::Document API instead of raw interaction
# with the database because there is not performance concern. Also, Mongoid
# helps with common operations (creating, editing, deleting).
class App
	include Mongoid::Document
	include Tokenable

	class << self
		def profiles_key(app_token)
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

	# Metrics for the application
	def events
		EventFinder.by_app_token({:app_token => token})
	end

	def profiles
		ProfileFinder.by_app_token({
			:app_token => token
		})
	end

	def events_at_month(year, month)
		from = Time.strptime("01/#{month}/#{year}", '%d/%m/%Y')
		to = from.next_month
		EventFinder.by_time_range({
			:app_token => token,
			:time_range => TimeRange.new(from, to)
		})
	end
end