require 'rails_helper'

describe App do
	before :each do
		App.delete_all
	end

	describe 'required fields' do
		it 'requires a name' do
			app = App.new
			app.save
			expect(app).not_to be_valid

			app = App.new :name => 'Dixte'
			app.save
			expect(app).to be_valid
		end
	end

	describe 'keys of tracking properties' do
		it 'has a key for profile properties' do
			expect(App.profile_properties_key('foo')).to eq(['foo', 'profiles'])
		end

		it 'has a key for events properties' do
			expect(App.event_types_key('foo')).to eq(['foo', 'event_types'])
		end
	end

	describe 'users ownership' do
	end

	describe 'warns' do
		it 'has many warns'
		it 'removes warns based on creation time'
	end

	describe 'token generation' do
		it 'generates an unique token upon creation' do
			app = App.new :name => 'Dixte'
			app.save
			expect(app.token.length).to eq(22)
		end

		it 'doesnt update the token when updating the app' do
			app = App.create :name => 'Dixte'
			app_token = app.token
			app.update_attributes(:name => 'Liato')
			expect(app.name).to eq('Liato')
			expect(app.token).to eq(app_token)
		end
	end
end