module Tokenable
	extend ActiveSupport::Concern

	included do
		field :token, :type => String
		index({:token => 1}, {:unique => true})
		before_create :generate_token
	end

	def generate_token
		self.token = loop do
			random_token = SecureRandom.urlsafe_base64(nil, false)
			if self.class.where(:token => random_token).count == 0
				break random_token
			end
		end
	end
end