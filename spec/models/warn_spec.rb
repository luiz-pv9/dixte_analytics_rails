require 'rails_helper'

describe Warn do

	def valid_app
		App.create :name => 'Dixte'
	end

	before :each do
		App.delete_all
		Warn.delete_all
	end

	describe 'required fields' do
		it 'requires the level of the warn' do
			warn = Warn.create :message => 'foo', :app => valid_app
			expect(warn).not_to be_valid
		end

		it 'requires a message' do
			warn = Warn.create :level => Warn::LOW, :app => valid_app
			expect(warn).not_to be_valid
		end

		it 'requires a refenrece to an app' do
			warn = Warn.create :level => Warn::LOW, :message => 'foo'
			expect(warn).not_to be_valid
		end
	end

	it 'stores a hash to aggregate information to the warn' do
		warn = Warn.create :level => Warn::LOW, :message => 'foo', :app => valid_app, :data => {
			'foo' => 'bar',
			'age' => 2
		}

		expect(warn.data).to eq({'foo' => 'bar', 'age' => 2})
	end
end