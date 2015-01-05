require 'base64'
require 'json'

class EventReceiverController < ApplicationController
	def track
		@raw_data = params[:data]
		if @raw_data
			@json_data = Base64.decode64 @raw_data
			begin
				@data = JSON.parse(@json_data)
				render :text => '1'
			rescue JSON::ParserError => e
				render :text => '0'
			end
		else
			render :text => '0'
		end
	end
end
