# The AppMetrics model is responsible for storing metrics for an application.
# The metrics include: number of events tracked, number of profiles tracked
class AppMetrics
	include Mongoid::Document
end