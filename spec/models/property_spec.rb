require 'rails_helper'

describe Property do
	it 'instantiates a Property by the specified data' do
		property = Property.new({a: 10})
		expect(property).to be_truthy
	end

	it 'has the data public accessed' do
		property = Property.new({a: 10})
		expect(property.data).to eq({:a => 10})
	end

	describe 'reading data' do
		describe '.has_property' do
			before :each do
				@property = Property.new({
					'key' => 'foobar',
					'properties' => {
						'age' => {
						}
					}
				})
			end

			it 'returns true if a property has been registered' do
				expect(@property.has_property('age')).to be_truthy
			end

			it 'returns false if a property hasnt been registered' do
				expect(@property.has_property('width')).to be_falsy
			end
		end

		describe 'reference counting' do
			before :each do
				@property = Property.new({
					'properties' => {
						'name' => {
							'type' => 'string',
							'values' => {
								'Luiz' => 3,
								'Paulo' => 2
							}
						},
						'age' => {
							'type' => 'number',
							'values' => {
								'*' => 5
							}
						}
					}
				})
			end

			it 'finds the reference counter for the value of a property' do
				expect(@property.value_count('name', 'Luiz')).to eq(3)
				expect(@property.value_count('name', 'Paulo')).to eq(2)
				expect(@property.value_count('name', 'Fran')).to eq(0)
				expect(@property.value_count('age', '*')).to eq(5)
			end

			it 'counts the total reference of a single property' do
				expect(@property.value_count('name')).to eq(5)
				expect(@property.value_count('age')).to eq(5)
				expect(@property.value_count('country')).to eq(0)
			end

			it 'counts the total of all values of all properties' do
				expect(@property.total_count()).to eq(10)
			end
		end
	end

	describe 'values size' do
		it 'counts the number of properties' do
			property = Property.new({
				'properties' => {
					'a' => {},
					'b' => {},
					'c' => {}
				}
			})
			expect(property.number_of_values).to eq(3)
		end

    it 'counts the number of values of a property' do
      prop = Property.new({
        'properties' => {
          'name' => {
            'type' => 'string',
            'values' => {
              'a' => 1, 'b' => 2
            }
          }
        }
      })
      
      expect(prop.number_of_values('name')).to eq(2)

      prop = Property.new({
        'properties' => {
          'name' => {
            'type' => 'string',
            'values' => {
              'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4
            }
          },
          'type' => {
            'type' => 'string',
            'values' => {
              'a' => 1, 'b' => 2
            }
          }
        }
      })

      expect(prop.number_of_values('name')).to eq(4)
      expect(prop.number_of_values('type')).to eq(2)
      expect(prop.number_of_values('age')).to eq(0)
    end
	end

  describe '.max_properties' do
    it 'has a default value of 50' do
      expect(Property.max_properties).to eq(50)
    end

    it 'has a setter to override' do
      Property.max_properties = 10
      expect(Property.max_properties).to eq(10)
    end
  end

  describe '.has_large_collection' do
    it 'compares the number of values against Property.max_properties' do
      prop = Property.new({
        'properties' => {
          'name' => {
            'type' => 'string',
            'values' => {
              '1' => 1, '2' => 1, '3' => 1, '4' => 1, '5' => 1
            }
          }
        }
      })
      Property.max_properties = 6
      expect(prop.has_large_collection('name')).to be(false)
      Property.max_properties = 5
      expect(prop.has_large_collection('name')).to be(true)
    end
  end

  describe '.has_large_collection_flag' do
    it 'returns true if the flag is present. false if not or false' do
      prop = Property.new({
        'properties' => {
          'name' => {
            'type' => 'string',
            'is_large' => true,
            'values' => {}
          },
          'age' => {
            'type' => 'number',
            'is_large' => false,
            'values' => {}
          },
          'admin' => {
            'type' => 'boolean',
            'values' => {}
          }
        }
      })
      expect(prop.has_large_collection_flag('name')).to be(true)
      expect(prop.has_large_collection_flag('age')).to be_falsy
      expect(prop.has_large_collection_flag('admin')).to be_falsy
      expect(prop.has_large_collection_flag('color')).to be_falsy
    end
  end
end
