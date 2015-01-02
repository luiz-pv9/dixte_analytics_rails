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
	end
end
