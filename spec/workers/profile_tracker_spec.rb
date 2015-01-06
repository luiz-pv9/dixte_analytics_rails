require 'rails_helper'

describe ProfileTracker do
	describe '.clean' do
		it 'cleans the profile' do
			profile = {'name' => 'Luiz Paulo', 'age' => 20, 'colors' => ['red'],
				'removed' => {}}
			cleaned = ProfileTracker.clean(profile)
			expect(cleaned).to eq(
				{'name' => 'Luiz Paulo', 'age' => 20, 'colors' => ['red']}
			)
		end
	end

	describe 'warning generation on bad formatted profiles' do
		it 'generates a warn if any property were removed in the cleaning process'
		it 'generates a different warn if all properties were removed'
		it ''
	end

	describe 'storing the profile'
	describe 'incrementing a property in a profile'
	describe 'appending a value in a property in a profile'
end