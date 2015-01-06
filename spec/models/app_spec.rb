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

	describe 'users ownership' do
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