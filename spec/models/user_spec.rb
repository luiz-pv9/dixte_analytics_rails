require 'rails_helper'

RSpec.describe User, :type => :model do
	describe 'devise' do
		it 'creates the user with password and password_confirmation' do
			user = User.new(:email => 'luiz.pv9@gmail.com', :password => '1234',
				:password_confirmation => '1234')
			expect(user).to be_valid
			expect(user.save).to be_truthy
		end
	end
end
