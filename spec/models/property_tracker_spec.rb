require 'rails_helper'
require 'collections'

describe PropertyTracker do

  before :each do
    @collection = Collections::Properties.collection
    delete_all()
  end

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
							'false' => 1
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

    it 'tracks numbers and booleans as strings' do
      PropertyTracker.new('foo', {'age' => 20}).save!
      PropertyTracker.new('foo', {'admin' => true}).save!
      PropertyTracker.new('foo', {'name' => 'Luiz'}).save!

      doc = PropertyFinder.by_key('foo')
      expect(doc['properties']['age']['type']).to eq('number')
      expect(doc['properties']['age']['values']['20']).to eq(1)

      expect(doc['properties']['admin']['type']).to eq('boolean')
      expect(doc['properties']['admin']['values']['true']).to eq(1)

      expect(doc['properties']['name']['type']).to eq('string')
      expect(doc['properties']['name']['values']['Luiz']).to eq(1)
    end
	end
	
	def track_n(n)
		0.upto(n-1) do |val|
			property_tracker = PropertyTracker.new('foo', {'val' => val.to_s})
			property_tracker.track!
		end
	end

	describe 'large amount of values' do
		it 'accepts value normally until the values goes over max size' do
      Property.max_properties = 5
			track_n(5)
			p = PropertyFinder.by_key('foo')

			expect(p['properties']['val']['values'].size).to eq(5)

      # Tracking the 6th value
			property_tracker = PropertyTracker.new('foo', {'val' => '100'})
			property_tracker.track!

			p = PropertyFinder.by_key('foo')
      # Everything should be one reference now
			expect(p['properties']['val']['values'].size).to eq(1)
			expect(p['properties']['val']['values']['*']).to eq(6)
		end

    it 'works with array values' do
      Property.max_properties = 3
      PropertyTracker.new('foo', {'colors' => ['red', 'green', 'blue']}).track!

			p = PropertyFinder.by_key('foo')
			expect(p['properties']['colors']['values'].size).to eq(3)

      PropertyTracker.new('foo', {'colors' => ['yellow', 'purple']}).track!

			p = PropertyFinder.by_key('foo')
			expect(p['properties']['colors']['values'].size).to eq(1)
			expect(p['properties']['colors']['values']['*']).to eq(5)
    end

    it 'increments the placeholder once its a large collection' do
      Property.max_properties = 3
      # Normal collection
      PropertyTracker.new('foo', {'colors' => ['red', 'green', 'blue']}).track!

      # Converts to a large collection
      PropertyTracker.new('foo', {'colors' => ['yellow', 'purple']}).track!

      # Adds to the large collection
      PropertyTracker.new('foo', {'colors' => ['black']}).track!

			p = PropertyFinder.by_key('foo')
			expect(p['properties']['colors']['values'].size).to eq(1)
			expect(p['properties']['colors']['values']['*']).to eq(6)
    end

    it 'treats other properties normally alongside a large collection' do
      Property.max_properties = 3
      PropertyTracker.new('foo', {'colors' => ['red', 'blue', 'yellow']}).track!
      PropertyTracker.new('foo', {'colors' => ['white'], 'name' => 'Luiz'}).track!

      p = Property.new(PropertyFinder.by_key('foo'))
      expect(p.value_count('colors')).to eq(4)
      expect(p.number_of_values('colors')).to eq(1)
      expect(p.value_count('name')).to eq(1)
      expect(p.number_of_values('name')).to eq(1)
      expect(p.value_count('name', 'Luiz')).to eq(1)
    end
	end
end

