class EventTracker
	include Sidekiq::Worker

	def perform(data)
	end
end
