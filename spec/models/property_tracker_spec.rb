require 'rails_helper'

describe PropertyTracker do
	describe 'instantiating with an array as the key' do
		it 'accepts array as the key' do
			property_tracker = PropertyTracker.new ['foo', 'bar'], {}
			expect(property_tracker).to be_truthy
		end

		it 'normalizes the key in the constructor' do
			property_tracker = PropertyTracker.new ['foo', 'bar'], {}
			expect(property_tracker.key).to eq('foo#bar')
		end
	end

	describe ''

	describe 'saving propreties to the database' do
		before :each do
			@collection = MongoHelper.database.collection 'properties'
		end

		it 'tracks the '
	end
end

