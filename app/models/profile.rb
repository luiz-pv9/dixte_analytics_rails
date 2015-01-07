class Profile
	include Mongoid::Document
	include Mongoid::Timestamps

	before_create :check_properties

	field :app_token, :type => String
	field :external_id, :type => String
	field :properties, :type => Hash

	validates_presence_of :app_token
	validates_presence_of :external_id

	def check_properties
		self.properties = {} if properties.nil?
	end
end