require 'rails_helper'

describe PropertyUntracker do
	describe 'instantiating' do
		it 'creates a PropertyUntracker instance' do
			property_untracker = PropertyUntracker.new('foo', {})
			expect(property_untracker).to be_truthy
		end

		it 'creates the PropertyUntracker with the specified key and normalizes it' do
			property_untracker = PropertyUntracker.new(['foo', 'bar'], {})
			expect(property_untracker.key).to eq('foo#bar')
		end
	end

	describe '.save! (untracking)' do
		before :each do
			@collection = MongoHelper.database.collection 'properties'
			@collection.remove({})
		end

		it 'decrements the counter of a property if it is greater than one' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!

			PropertyUntracker.new('foo', {'name' => 'Luiz'}).save!

			expect(@collection.count).to eq(1)
			doc = @collection.find_one
			expect(doc).to eq({
				'_id' => doc['_id'],
				'key' => 'foo',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'Luiz' => 2 # change
						}
					}
				}
			})
		end

		it 'removes the value of a property from the values hash if the counter reaches zero'
		it 'removes the property from the properties hash if the counter of all values reaches zero'
		it 'removes the property document from the database if all values of all properties reaches zero'
	end
end
