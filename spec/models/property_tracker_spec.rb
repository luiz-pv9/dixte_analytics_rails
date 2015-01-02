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
			@collection.remove({})
		end

		it 'tracks the specified properties and persists it to the database' do
			property_tracker = PropertyTracker.new 'foo', {'name' => 'Luiz'}
			property_tracker.save!
			expect(@collection.count).to eq(1)
			doc = @collection.find_one
			expect(doc).to eq({
				'_id' => doc['_id'],
				'key' => 'foo',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'Luiz' => 1
						}
					}
				}
			})
		end

		it 'increments the counter if the property is already registered' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyTracker.new('foo', {'name' => 'Luiz', 'synced' => false}).save!
			expect(@collection.count).to eq(1)
			doc = @collection.find_one
			expect(doc).to eq({
				'_id' => doc['_id'],
				'key' => 'foo',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'Luiz' => 2
						}
					},
					'synced' => {
						'type' => 'boolean',
						'values' => {
							'*' => 1
						}
					}
				}
			})
		end
	end
end

