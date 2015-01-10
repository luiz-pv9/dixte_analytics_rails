require 'rails_helper'
require 'collections'

describe ProfileUntracker do
	before :each do
		@profiles = Collections::Profiles.collection
		@properties = Collections::Properties.collection
		Collections::Profiles.collection.find.remove_all
		Collections::Properties.collection.find.remove_all
		@profile_tracker = ProfileTracker.new
		@profile_untracker = ProfileUntracker.new
		@app = App.create :name => 'Dixte'
	end

	def track_profile(external_id, properties = {})
		@profile_tracker.perform({
			'app_token' => @app.token,
			'external_id' => external_id,
			'properties' => properties
		})
	end

	def track_profiles_1
		track_profile('lpvasco', {
			'account type' => 'premium',
			'platform' => 'ios'
		})
		track_profile('luiz', {
			'account type' => 'normal',
			'platform' => 'web'
		})
	end

	describe 'untracking a profile' do
		it 'removes the profile from the external_id' do
			track_profiles_1
			expect {
				@profile_untracker.perform({
					:app_token => @app.token, 
					:external_id => 'lpvasco'
				})
			}.to change { @profiles.find.count }.by(-1)
		end

		it 'untracks the properties in the profile being removed' do
			track_profiles_1
			@profile_untracker.perform({
				:app_token => @app.token, 
				:external_id => 'lpvasco'
			})
			property = @properties.find.first
			expect(property.except('_id')).to eq({
				'key' => @app.token + '#profiles',
				'properties' => {
					'account type' => {
						'type' => 'string',
						'values' => {
							'normal' => 1
						}
					},
					'platform' => {
						'type' => 'string',
						'values' => {
							'web' => 1
						}
					}
				}				
			})
		end
	end

	def track_profiles_2
		track_profile('lpvasco', {
			'account type' => 'premium',
			'platform' => 'ios'
		})
		track_profile('luiz', {
			'account type' => 'normal',
			'platform' => 'web'
		})
		track_profile('sinxoll', {
			'account type' => 'premium',
			'platform' => 'android'
		})
	end

	describe 'untracking multiple profiles' do
		it 'removes multiple profiles from external ids' do
			track_profiles_2
			expect {
				@profile_untracker.perform({
					:app_token => @app.token, 
					:external_ids => ['lpvasco', 'sinxoll']
				})
			}.to change { @profiles.find.count }.by(-2)
			property = @properties.find.first
			expect(property.except('_id')).to eq({
				'key' => @app.token + '#profiles',
				'properties' => {
					'account type' => {
						'type' => 'string',
						'values' => {
							'normal' => 1
						}
					},
					'platform' => {
						'type' => 'string',
						'values' => {
							'web' => 1
						}
					}
				}				
			})
		end
	end
end