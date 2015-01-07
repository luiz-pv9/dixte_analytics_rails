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
	
	describe 'saving propreties to the database' do
		before :each do
			@collection = Mongoid::Sessions.default['properties']
			@collection.find({}).remove_all
		end

		it 'tracks the specified properties and persists it to the database' do
			property_tracker = PropertyTracker.new 'foo', {'name' => 'Luiz'}
			property_tracker.save!
			expect(@collection.find.count).to eq(1)
			doc = @collection.find.first
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

		it 'increments the find.counter if the property is already registered' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyTracker.new('foo', {'name' => 'Luiz', 'synced' => false}).save!
			expect(@collection.find.count).to eq(1)
			doc = @collection.find.first
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

		it 'increments the find.counter of different values for the same proprety' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyTracker.new('foo', {'name' => 'Paulo'}).save!
			expect(@collection.find.count).to eq(1)
			doc = @collection.find.first
			expect(doc).to eq({
				'_id' => doc['_id'],
				'key' => 'foo',
				'properties' => {
					'name' => {
						'type' => 'string',
						'values' => {
							'Luiz' => 1,
							'Paulo' => 1
						}
					}
				}
			})
		end

		it 'tracks values inside the array in a single property' do
			PropertyTracker.new('foo', {'name' => ['Luiz', 'Paulo']}).save!
			expect(@collection.find.count).to eq(1)
			doc = @collection.find.first
			expect(doc).to eq({
				'_id' => doc['_id'],
				'key' => 'foo',
				'properties' => {
					'name' => {
						'type' => 'array',
						'values' => {
							'Luiz' => 1,
							'Paulo' => 1
						}
					}
				}
			})
		end
	end
end

