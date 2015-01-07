require 'collections'

class Warn
	include Mongoid::Document
	include Mongoid::Timestamps

	store_in :collection => Collections::Warns.name

	# Warn levels
	LOW = 0
	MEDIUM = 1
	HIGH = 2
	CRITICAL = 3

	# Level of the warn. Should be one of the constants defined in this class
	field :level, :type => Integer
	field :data, :type => Hash
	field :message, :type => String

	# Relations
	belongs_to :app

	# Validations
	validates_presence_of :level
	validates_presence_of :message
	validates_presence_of :app
end