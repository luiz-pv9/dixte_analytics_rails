require 'rails_helper'

describe FunnelReport do
	before :each do
		delete_all
		@event_tracker = EventTracker.new
		@profile_tracker = ProfileTracker.new
		@app = App.create :name => 'Dixte'
	end

	def track_event(type, time, properties = {}, external_id = 'lpvasco', app_token = nil)
		app_token ||= @app.token
		@event_tracker.perform({
			'app_token' => app_token,
			'external_id' => external_id,
			'happened_at' => time.to_i,
			'type' => type,
			'properties' => properties
		})
	end

	def track_profile(external_id, properties = {}, app_token = nil)
		app_token ||= @app.token
		@profile_tracker.perform({
			'app_token' => app_token,
			'external_id' => external_id,
			'properties' => properties
		})
	end

	def track_1
		@now = Time.now
		track_event('visit page', @now, {}, 'lpvasco')
		track_event('open signup modal', @now + 1.minute, {}, 'lpvasco')
		track_event('complete signup', @now + 2.minute, {}, 'lpvasco')

		track_event('visit page', @now, {}, 'luizpv9')
		track_event('open signup modal', @now + 1.minute, {}, 'luizpv9')

		track_event('visit page', @now, {}, 'fran')
		track_event('complete signup', @now + 1.minute, {}, 'fran')
	end

	def track_2
		@now = Time.now
		track_event('visit page', @now, {'source' => 'facebook'}, 'lpvasco')
		track_event('open signup modal', @now + 1.minute, {}, 'lpvasco')
		track_event('complete signup', @now + 2.minute, {}, 'lpvasco')

		track_event('visit page', @now, {'source' => 'twitter'}, 'lpvasco')
		track_event('open signup modal', @now + 1.minute, {}, 'lpvasco')
		track_event('complete signup', @now + 2.minute, {}, 'lpvasco')

		track_event('visit page', @now, {'source' => 'facebook'}, 'luizpv9')
		track_event('open signup modal', @now + 1.minute, {}, 'luizpv9')

		track_event('visit page', @now, {}, 'fran')
		track_event('complete signup', @now + 1.minute, {}, 'fran')
	end

	def track_3
		@now = Time.now
		track_event('visit page', @now, {'page' => 'home'}, 'lpvasco')
		track_event('visit page', @now + 1.minute, {'page' => 'contact'}, 'lpvasco')
		track_event('visit page', @now + 2.minute, {'page' => 'home'}, 'lpvasco')

		track_event('visit page', @now, {'page' => 'home'}, 'luizpv9')
		track_event('visit page', @now + 1.minute, {'page' => 'contact'}, 'luizpv9')

		track_event('visit page', @now, {'page' => 'contact'}, 'fran')
	end

	def track_4
		@now = Time.now
		track_event('visit page', @now, {}, 'lpvasco')
		track_event('open signup modal', @now + 1.minute, {}, 'lpvasco')

		track_event('open signup modal', @now, {}, 'luizpv9')
		track_event('visit page', @now + 1.minute, {}, 'luizpv9')
	end

	def track_5
		track_profile('lpvasco')
		track_profile('luizpv9')
		track_profile('fran')

		@now = Time.now
		track_event('visit page', @now, {}, 'lpvasco')
		track_event('open signup modal', @now + 1.minute, {}, 'lpvasco')
		track_event('complete signup', @now + 2.minute, {}, 'lpvasco')

		track_event('visit page', @now, {}, 'luizpv9')
		track_event('open signup modal', @now + 1.minute, {}, 'luizpv9')

		track_event('visit page', @now, {}, 'fran')
		track_event('complete signup', @now + 1.minute, {}, 'fran')
	end

	describe 'funnel' do
		it 'example 1' do
			track_1
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'open signup modal', 'complete signup']
			}).funnel
			expect(report).to eq([3, 2, 1])
		end

		it 'example 2' do
			track_1
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'complete signup']
			}).funnel
			expect(report).to eq([3, 2])
		end 

		it 'example 3' do
			track_2
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'open signup modal', 'complete signup']
			}).funnel
			expect(report).to eq([4, 3, 2])
		end

		it 'example 4 with event order' do
			track_4
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'open signup modal']
			}).funnel
			expect(report).to eq([2, 1])
		end
	end	

	describe 'filtering' do
		it 'accepts filters in each step of the funnel' do
			track_2
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'open signup modal', 'complete signup'],
				'filters' => [
					{'source' => 'facebook'}
				]
			}).funnel
			expect(report).to eq([2, 2, 1])
		end

		it 'accepts filters for the step even if the same event is in two steps' do
			track_3
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'visit page'],
				'filters' => [
					{'page' => 'home'},
					{'page' => 'contact'}
				]
			}).funnel
			expect(report).to eq([3, 2])
		end
	end

	describe 'profiles' do
		it 'finds the profiles that passed at n point of the funnel (n being first)' do
			track_5
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'open signup modal', 'complete signup']
			}).profiles_at_step(0)

			expect(report.count).to eq(3)
		end

		it 'finds the profiles that passed at n point of the funnel (n being last)' do
			track_5
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'open signup modal', 'complete signup']
			}).profiles_at_step(2)

			expect(report.count).to eq(1)
		end

		it 'finds the profiles that passed at n point of the funnel (n being in the middle)' do
			track_5
			report = FunnelReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => @now + 5.minutes
				},
				'steps' => ['visit page', 'open signup modal', 'complete signup']
			}).profiles_at_step(1)

			expect(report.count).to eq(2)
		end
	end

	describe 'segmentation' do
		it 'calculates convertion rate segmented by a property'
	end

	describe 'actions in between steps' do
		it 'finds the n most common events between two steps in the funnel'
	end

	describe 'allowed interval between steps' do
		it 'may receive an array of intervals to filter the funnel'
	end
end