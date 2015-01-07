require 'rails_helper'

describe Profile do
	before :each do
		Profile.delete_all
		App.delete_all
	end

	it 'stores a valid profile' do
		profile = Profile.create({
			:external_id => 'lpvasco',
			:app_token => '1234',
			:properties => {
				'name' => 'Luiz Paulo'
			}			
		})
		expect(profile).to be_valid
		expect(profile.properties).to eq({'name' => 'Luiz Paulo'})
		expect(profile.external_id).to eq('lpvasco')
		expect(profile.app_token).to eq('1234')
	end

	describe 'required attributes' do
		it 'requires the app token' do
			profile = Profile.create :external_id => 'lpvasco'
			expect(profile).not_to be_valid
		end

		it 'requires the external id' do
			profile = Profile.create :app_token => '12345'
			expect(profile).not_to be_valid
		end
	end

	it 'stores an empty hash as properties if none are specified' do
		profile = Profile.create :app_token => '12345', :external_id => 'lpvasco'
		expect(profile.properties).to eq({})
	end
end