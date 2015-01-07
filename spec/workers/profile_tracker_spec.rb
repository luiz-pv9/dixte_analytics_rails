require 'rails_helper'

describe ProfileTracker do

	def valid_app
		App.create :name => 'Dixte'
	end

	def valid_app_token
		valid_app.token
	end

	before :each do
		App.delete_all
		Warn.delete_all
		@profile_tracker = ProfileTracker.new
		@profiles = Mongoid::Sessions.default['profiles']
		@profiles.find().remove_all
	end

	it 'returns -1 if the app_token is not present in the data' do
		expect(@profile_tracker.perform({'foo' => 'bar'})).to be(-1)
	end

	describe 'warning generation on bad formatted profiles' do
		it 'generates a warn if the properties hash is not present in the data' do
			app = valid_app
			expect {
				@profile_tracker.perform({'app_token' => app.token, 'external_id' => 'lpvasco'})
			}.to change { Warn.all.count }.by(1)
			warn = Warn.first
			expect(warn.level).to eq(Warn::MEDIUM)
			expect(warn.app).to eq(app)
			expect(warn.data).to eq({
				'app_token' => app.token,
				'external_id' => 'lpvasco'
			})
		end

		it 'generates a warn if the external_id is not present in the data' do
			app = valid_app
			expect {
				@profile_tracker.perform({'app_token' => app.token, 'properties' => {}})
			}.to change { Warn.all.count }.by(1)
			warn = Warn.first
			expect(warn.level).to eq(Warn::MEDIUM)
			expect(warn.app).to eq(app)
			expect(warn.data).to eq({
				'app_token' => app.token,
				'properties' => {}
			})
		end

		it 'generates a warn if any root property were removed in the cleaning process' do
			# app = valid_app
			# expect {
			# 	@profile_tracker.perform({
			# 		'app_token' => app.token,
			# 		'external_id' => 2015,
			# 		'properties' => {}
			# 	})
			# }.to change { Warn.all.count }.by(1)
			# warn = Warn.first
			# expect(warn.level).to eq(Warn::MEDIUM)
			# expect(warn.app).to eq(app)
			# expect(warn.data).to eq({
			# 	'app_token' => app.token,
			# 	'external_id' => 2015,
			# 	'properties' => {}
			# })
		end

		it 'generates a warn if the properties has invalid attributes' do
			app = valid_app
			expect {
				@profile_tracker.perform({
					'app_token' => app.token,
					'external_id' => 'lpvasco',
					'properties' => {
						'name' => 'Luiz Paulo',
						'age' => {'foo' => 'bar'}
					}
				})
			}.to change { Warn.all.count }.by(1)
			warn = Warn.first
			expect(warn.level).to eq(Warn::MEDIUM)
			expect(warn.app).to eq(app)
			expect(warn.data).to eq({
				'app_token' => app.token,
				'external_id' => 'lpvasco',
				'properties' => {
					'name' => 'Luiz Paulo',
					'age' => {'foo' => 'bar'}
				}
			})
		end
	end

	describe 'storing the profile' do
		it 'sets created_at and updated_at when creating the profile' do
			profile = nil
			expect {
				profile = @profile_tracker.perform({
					'app_token' => valid_app_token,
					'external_id' => 'lpvasco',
					'properties' => {
						'name' => 'Luiz Paulo'
					}
				})
			}.to change { @profiles.find.count }.by(1)
			expect(profile['_id']).to be_truthy
			expect(profile['external_id']).to eq('lpvasco')
			expect(profile['properties']).to eq({'name' => 'Luiz Paulo'})
			expect(profile['created_at']).to be_truthy
			expect(profile['updated_at']).to eq(profile['created_at'])
		end

		it 'may receive created_at and updated_at in the hash to override default ones' do
			profile = nil
			expect {
				profile = @profile_tracker.perform({
					'app_token' => valid_app_token,
					'external_id' => 'lpvasco',
					'created_at' => 123456,
					'properties' => {
						'name' => 'Luiz Paulo'
					}
				})
			}.to change { @profiles.find.count }.by(1)
			expect(profile['_id']).to be_truthy
			expect(profile['external_id']).to eq('lpvasco')
			expect(profile['properties']).to eq({'name' => 'Luiz Paulo'})
			expect(profile['created_at']).to eq(123456)
			expect(profile['updated_at']).to eq(123456)
		end

		it 'updates updated_at when updating the profile'
		it 'increments a value with the special increment attribute'
		it 'creates the value with the increment operation if no value is found'
		it 'appends a value to a list with the special append atttribute'
		it 'creates the list with the append operation if no list is found'
	end

	describe 'incrementing a property in a profile'
	describe 'appending a value in a property in a profile'
	describe 'tracking properties (PropertyTracker usage)'
end