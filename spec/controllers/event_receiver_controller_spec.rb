require 'rails_helper'
require 'base64'

describe EventReceiverController do
	describe 'track' do
		describe 'http methods' do
			it 'responds to the GET method' do
				data = {'foo' => 'bar'}.to_json
				get :track, {:data => Base64.encode64(data)}
				expect(response.body).to eq('1')
			end

			it 'responds to the POST method' do
				data = {'foo' => 'bar'}.to_json
				post :track, {:data => Base64.encode64(data)}
				expect(response.body).to eq('1')
			end
		end

		it 'returns 1 if the data is properly encoded' do
			data = {'foo' => 'bar'}.to_json
			post :track, {:data => Base64.encode64(data)}
			expect(response.body).to eq('1')
		end

		it 'returns 0 if the data is poorly encoded' do
			data = {'foo' => 'bar'}.to_json
			post :track, {:data => 'what' + Base64.encode64(data)}
			expect(response.body).to eq('0')
		end

		it 'enqueues the requested data to be processed by the tracker' do
			data = {'foo' => 'bar'}.to_json
			post :track, {:data => Base64.encode64(data)}
		end
	end
end
