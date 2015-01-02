require 'rails_helper'
require 'tracking_value'

describe 'TrackingValue class' do
	describe 'instantiting' do
		it 'receives any value type as the value' do
			tracking_value = TrackingValue.new 'foo'
			expect(tracking_value).to be_truthy
		end
	end

	describe 'detecting the type' do
		it 'may receive the type in the constructor' do
			tracking_value = TrackingValue.new 'foo', :string
			expect(tracking_value.type).to be(:string)
		end

		it 'may receive the type through a setter' do
			tracking_value = TrackingValue.new 'foo'
			tracking_value.type = :number
			expect(tracking_value.type).to be(:number)
		end

		it 'detects the type if not specified' do
			tracking_value = TrackingValue.new 'foo'
			expect(tracking_value.type).to eq(:string)
		end
	end

	describe 'converting to tracking values' do
		it 'returns the same value if the type is a string' do
			value = TrackingValue.new 'foo'
			expect(value.to_track_value).to eq(['foo'])
		end

		it 'returns non string track value if the type is not a string' do
			value = TrackingValue.new 25.5
			expect(value.to_track_value).to eq(['*'])
		end

		it 'returns an array of values if the type is an array' do
			value = TrackingValue.new ['foo', 25, false]
			expect(value.to_track_value).to eq(['foo', '*', '*'])
		end
	end
end
