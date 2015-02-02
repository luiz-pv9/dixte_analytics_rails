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
	end
end
