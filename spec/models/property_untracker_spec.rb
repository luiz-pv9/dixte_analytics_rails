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
			@collection = Mongoid::Sessions.default['properties']
			@collection.find({}).remove_all
		end

		it 'decrements the counter of a property if it is greater than one' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!

			PropertyUntracker.new('foo', {'name' => 'Luiz'}).save!

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

		it 'removes the value of a property from the values hash if the counter reaches zero' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyTracker.new('foo', {'name' => 'Paulo'}).save!
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			
			PropertyUntracker.new('foo', {'name' => 'Paulo'}).save!

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
					}
				}
			})
		end

		it 'removes the property from the properties hash if the counter of all values reaches zero' do
			PropertyTracker.new('foo', {'name' => 'Luiz', 'age' => 20}).save!
			PropertyUntracker.new('foo', {'name' => 'Luiz'}).save!
			expect(@collection.find.count).to eq(1)
			doc = @collection.find.first
			expect(doc).to eq({
				'_id' => doc['_id'],
				'key' => 'foo',
				'properties' => {
					'age' => {
						'type' => 'number',
						'values' => {
							'*' => 1
						}
					}
				}
			})
		end

		it 'removes the property document from the database if all values of all properties reaches zero' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyUntracker.new('foo', {'name' => 'Luiz'}).save!
			expect(@collection.find.count).to eq(0)
		end

		it 'doesnt remove any property if nothing is found to untrack' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyUntracker.new('foo', {'name' => 'Paulo'}).save!
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

		it 'untracks each element in the array of values' do
			PropertyTracker.new('foo', {'name' => %w(Luiz Paulo Foo)}).save!
			PropertyUntracker.new('foo', {'name' => %w(Foo Luiz Viswanathan)}).save!
			expect(@collection.find.count).to eq(1)
			doc = @collection.find.first
			expect(doc).to eq({
				'_id' => doc['_id'],
				'key' => 'foo',
				'properties' => {
					'name' => {
						'type' => 'array',
						'values' => {
							'Paulo' => 1
						}
					}
				}
			})
			PropertyUntracker.new('foo', {'name' => %w(Paulo)}).save!
			expect(@collection.find.count).to eq(0)
		end
	end
end
