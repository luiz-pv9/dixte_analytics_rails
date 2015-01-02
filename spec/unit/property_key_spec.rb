require 'rails_helper'
require 'property_key'

describe 'PropertyKey' do
	it 'returns the specified content if not array' do
		expect(PropertyKey.normalize('foo')).to eq('foo')
		expect(PropertyKey.normalize(123)).to eq('123')
	end

	it 'returns the normalized value if array' do
		expect(PropertyKey.normalize(['foo', 'bar'])).to eq('foo#bar')
		expect(PropertyKey.normalize(['foo', nil])).to eq('foo#')
	end
end
