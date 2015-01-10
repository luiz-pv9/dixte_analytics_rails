require 'rails_helper'
require 'collections'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

describe ProfileUntracker do
	before :each do
		@profiles = Collections::Profiles.collection
		@events = Collections::Events.collection
		@properties = Collections::Properties.collection
		Collections::Profiles.collection.find.remove_all
		Collections::Properties.collection.find.remove_all
		@event_tracker = EventTracker.new
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

	describe 'untracking the profile events' do
		it 'enqueues a call to EventUntracker to untrack the events associated with the profile' do
			track_profile('lpvasco', {
				'account type' => 'premium',
				'platform' => 'ios'
			})
			expect {
				@profile_untracker.perform({
					:app_token => @app.token, 
					:external_id => 'lpvasco'
				})
			}.to change(EventUntracker.jobs, :size).by(1)
		end

		it 'untracks the events through job enqueuing for a single profile' do
			track_profile('lpvasco', {
				'account type' => 'premium',
				'platform' => 'ios'
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'luiz',
				'type' => 'click button',
				'properties' => {}
			})

			@profile_untracker.perform({
				:app_token => @app.token,
				:external_id => 'lpvasco'				
			})

			expect {
				EventUntracker.drain
			}.to change { @events.find.count }.by(-1)
		end

		it 'enquens a single call to EventUntracker with multiple profiles to untrack events' do
			track_profile('lpvasco', {
				'account type' => 'premium',
				'platform' => 'ios'
			})
			track_profile('luiz', {
				'account type' => 'premium',
				'platform' => 'ios'
			})
			expect {
				@profile_untracker.perform({
					:app_token => @app.token, 
					:external_ids => ['lpvasco', 'lpvasco']
				})
			}.to change(EventUntracker.jobs, :size).by(1)
		end

		it 'untracks the events through job enqueuing for a multiple profiles' do
			track_profile('luiz', {})
			track_profile('sonic', {})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'lpvasco',
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'luiz',
				'type' => 'click button',
				'properties' => {}
			})
			@event_tracker.perform({
				'app_token' => @app.token,
				'external_id' => 'sonic',
				'type' => 'click button',
				'properties' => {}
			})

			@profile_untracker.perform({
				:app_token => @app.token,
				:external_ids => ['luiz', 'sonic']				
			})

			expect {
				EventUntracker.drain
			}.to change { @events.find.count }.by(-2)
		end
	end
end