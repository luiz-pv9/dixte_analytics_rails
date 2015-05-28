require 'rails_helper'
require 'collections'

describe PropertyUntracker do
  before :each do
    @collection = Collections::Properties.collection
    delete_all
  end

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
		it 'decrements the counter of a property if it is greater than one' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!

			PropertyUntracker.new('foo', {'name' => 'Luiz'}).save!

			expect(@collection.find.count).to eq(1)
			prop = Property.new(PropertyFinder.by_key('foo'))
			expect(prop.value_count('name', 'Luiz')).to eq(1)
		end

		it 'removes the value of a property from the values hash if the counter reaches zero' do
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			PropertyTracker.new('foo', {'name' => 'Paulo'}).save!
			PropertyTracker.new('foo', {'name' => 'Luiz'}).save!
			
			PropertyUntracker.new('foo', {'name' => 'Paulo'}).save!

			expect(@collection.find.count).to eq(1)
			prop = Property.new(PropertyFinder.by_key('foo'))
			expect(prop.number_of_values('name')).to eq(1)
			expect(prop.value_count('name', 'Luiz')).to eq(2)
		end

		it 'removes the property from the properties hash if the counter of all values reaches zero' do
			PropertyTracker.new('foo', {'name' => 'Luiz', 'age' => 20}).save!
			PropertyUntracker.new('foo', {'name' => 'Luiz'}).save!
			expect(@collection.find.count).to eq(1)
			doc = PropertyFinder.by_key('foo')
			expect(doc).to eq({
				'_id' => doc['_id'],
				'key' => 'foo',
				'properties' => {
					'age' => {
						'type' => 'number',
						'values' => {
							'20' => 1
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
			Property.max_properties = 10 # Just setting some high value for testing
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
						'is_large' => false,
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

  describe 'large collections' do
    it 'untracks a large collection value' do
    	Property.max_properties = 2
      PropertyTracker.new('foo', {'colors' => ['red', 'green']}).track!
      PropertyTracker.new('foo', {'colors' => ['blue']}).track! # large collection

      p = Property.new(PropertyFinder.by_key('foo'))
      expect(p.number_of_values('colors')).to eq(1)
      expect(p.value_count('colors', '*')).to eq(3)

      PropertyUntracker.new('foo', {'colors' => 'red'}).untrack!
      p = Property.new(PropertyFinder.by_key('foo'))
      expect(p.number_of_values('colors')).to eq(1)
      expect(p.value_count('colors', '*')).to eq(2)
    end

    it 'untracks a large collection with multiple values (array)' do
      Property.max_properties = 2
      PropertyTracker.new('foo', {'colors' => ['red', 'green']}).track!
      PropertyTracker.new('foo', {'colors' => ['blue']}).track! # large collection
      PropertyUntracker.new('foo', {'colors' => ['red', 'green']}).untrack!

      p = Property.new(PropertyFinder.by_key('foo'))
      
      expect(p.number_of_values('colors')).to eq(1)
      expect(p.value_count('colors', '*')).to eq(1)
    end

    it 'deletes the property total count reaches zero' do
      Property.max_properties = 2
      PropertyTracker.new('foo', {'colors' => ['red', 'green']}).track!
      PropertyTracker.new('foo', {'colors' => ['blue']}).track! # large collection
      PropertyUntracker.new('foo', {'colors' => ['red', 'green']}).untrack!

      p = Property.new(PropertyFinder.by_key('foo'))

      expect(p.number_of_values('colors')).to eq(1)
      expect(p.value_count('colors', '*')).to eq(1)
      expect(p.has_large_collection_flag('colors')).to be(true)

      PropertyUntracker.new('foo', {'colors' => 'red'}).untrack!
      
      expect(PropertyFinder.by_key('foo')).to be_nil
    end

    it 'sets the is_large to false when untracking values' do
    	Property.max_properties = 2
    	PropertyTracker.new('foo', {'colors' => ['red', 'green'], 'name' => 'Luiz'}).track!
    	PropertyTracker.new('foo', {'colors' => ['blue']}).track!

    	PropertyUntracker.new('foo', {'colors' => ['red', 'green', 'blue']}).untrack! #Remove the large collection

    	prop = Property.new(PropertyFinder.by_key('foo'))
    	expect(prop.has_large_collection_flag('colors')).to be_falsy
    	expect(prop.value_count('colors')).to eq(0)
    	expect(prop.value_count('name', 'Luiz')).to eq(1)
    end
  end
end
