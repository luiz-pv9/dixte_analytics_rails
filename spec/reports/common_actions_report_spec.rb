require 'rails_helper'

describe CommonActionsReport do
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
		track_event('visit home', @now)
		track_event('click button', @now + 1.minute)
		track_event('review chart', @now + 2.minutes)
		track_event('click button', @now + 3.minutes)
		track_event('buy product', @now + 5.minutes)
		track_event('check orders', @now + 6.minutes)
	end

	def track_2
		@now = Time.now
		track_event('visit home', @now)
		track_event('click button', @now + 1.minute, {})
		track_event('buy product', @now + 2.minutes, {})

		track_event('visit home', @now + 3.minute, {})
		track_event('click button', @now + 4.minute, {})

		track_event('visit home', @now + 5.minutes, {}, 'luizpv9')
		track_event('open modal', @now + 6.minutes, {}, 'luizpv9')
		track_event('buy product', @now + 7.minutes, {}, 'luizpv9')
	end

	def track_3
		@now = Time.now
		track_event('visit home', @now + 5.minutes, {}, 'luizpv9')
		track_event('open modal', @now + 6.minutes, {}, 'luizpv9')
		track_event('buy product', @now + 7.minutes, {}, 'luizpv9')

		track_event('visit home', @now + 7.minutes, {}, 'lpvasco')
		track_event('check cart', @now + 8.minutes, {}, 'luizpv9') # Should not be counted
		track_event('buy product', @now + 9.minutes, {}, 'lpvasco')
	end

	def track_4
		@now = Time.now
		track_event('visit home', @now + 5.minutes, {'source' => 'facebook'}, 'luizpv9')
		track_event('open modal', @now + 6.minutes, {}, 'luizpv9')
		track_event('buy product', @now + 7.minutes, {}, 'luizpv9')

		track_event('visit home', @now + 7.minutes, {'source' => 'twitter'}, 'lpvasco')
		track_event('open modal', @now + 9.minutes, {}, 'lpvasco')
		track_event('buy product', @now + 9.minutes, {}, 'lpvasco')
	end

	def track_5
		@now = Time.now
		track_event('visit home', @now + 5.minutes, {}, 'luizpv9')
		track_event('open modal', @now + 6.minutes, {}, 'luizpv9')
		track_event('buy product', @now + 7.minutes, {'source' => 'google'}, 'luizpv9')

		track_event('visit home', @now + 7.minutes, {}, 'lpvasco')
		track_event('open modal', @now + 8.minutes, {}, 'lpvasco')
		track_event('buy product', @now + 9.minutes, {'source' => 'twitter'}, 'lpvasco')
	end

	def track_6
		@now = Time.now
		# This is gonna count
		track_event('visit home', @now + 5.minutes, {}, 'luizpv9')
		track_event('open modal', @now + 6.minutes, {}, 'luizpv9')
		track_event('buy product', @now + 7.minutes, {}, 'luizpv9')

		# This is not gonna count
		track_event('visit home', @now + 7.minutes, {}, 'lpvasco')
		track_event('open modal', @now + 9.minutes, {}, 'lpvasco')
		track_event('buy product', @now + 15.minutes, {}, 'lpvasco')
	end

	def track_7
		@now = Time.now
		# This is gonna count
		track_event('visit home', @now + 5.minutes, {}, 'luizpv9')
		track_event('visit home', @now + 6.minutes, {}, 'luizpv9')
		track_event('buy product', @now + 7.minutes, {}, 'luizpv9')

		# This is not gonna count
		track_event('visit home', @now + 7.minutes, {}, 'lpvasco')
		track_event('visit home', @now + 9.minutes, {}, 'lpvasco')
		track_event('check cart', @now + 10.minutes, {}, 'lpvasco')
		track_event('buy product', @now + 15.minutes, {}, 'lpvasco')
	end

	def track_8
		@now = Time.now
		# This is gonna count
		track_event('visit home', @now + 5.minutes, {'source' => 'facebook'}, 'lpvasco')
		track_event('open modal', @now + 6.minutes, {}, 'lpvasco')
		track_event('buy product', @now + 7.minutes, {'type' => 'digital'}, 'lpvasco')

		# This is not gonna count
		track_event('visit home', @now + 7.minutes, {'source' => 'twitter'}, 'lpvasco')
		track_event('click button', @now + 10.minutes, {}, 'lpvasco')
		track_event('click button', @now + 11.minutes, {}, 'lpvasco')
		track_event('buy product', @now + 15.minutes, {'type' => 'physical'}, 'lpvasco')
	end

	describe 'format' do
		it 'example 1' do
			track_1
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 6.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product']
			}).common_actions

			expect(report).to eq({
				'click button' => 2,
				'review chart' => 1
			})
		end

		it 'example 2' do
			track_2
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 10.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product']
			}).common_actions

			expect(report).to eq({
				'click button' => 1,
				'open modal' => 1
			})
		end

		it 'example 3' do
			track_3
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 10.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product']
			}).common_actions

			expect(report).to eq({
				'open modal' => 1
			})
		end

		it 'example 4 with same event happening in between' do
			track_7
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 20.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product']
			}).common_actions

			expect(report).to eq({
				'visit home' => 2,
				'check cart' => 1
			})
		end
	end

	describe 'filtering events between' do
		it 'accepts filters for events in the first edge' do
			track_4
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 10.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product'],
				'filters' => [
					{'source' => 'facebook'}
				]
			}).common_actions

			expect(report).to eq({
				'open modal' => 1
			})
		end

		it 'acceps filters for events in the second edge' do
			track_5
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 20.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product'],
				'filters' => [
					nil,
					{
						'source' => 'twitter'
					}
				]
			}).common_actions

			expect(report).to eq({
				'open modal' => 1
			})
		end
	end

	describe 'time limit' do
		it 'specifies a limit of time between the edges of the report' do
			track_6
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 20.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product'],
				'time_limit' => 2.minutes
			}).common_actions

			expect(report).to eq({
				'open modal' => 1
			})
		end
	end

	describe 'segmenting by a property in the edges' do
		it 'segments by a property in the first edge' do
			track_8
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 20.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product'],
				'segment_for' => 'visit home',
				'segment_by' => 'source'
			}).common_actions

			expect(report).to eq({
				'facebook' => {
					'open modal' => 1
				},
				'twitter' => {
					'click button' => 2
				}
			})
		end

		it 'segments by a property in the second edge' do
			track_8
			report = CommonActionsReport.new({
				'app_token' => @app.token,
				'time_range' => {
					'from' => @now.to_i,
					'to' => (@now + 20.minutes).to_i
				},
				'events_between' => ['visit home', 'buy product'],
				'segment_for' => 'buy product',
				'segment_by' => 'type'
			}).common_actions

			expect(report).to eq({
				'digital' => {
					'open modal' => 1
				},
				'physical' => {
					'click button' => 2
				}
			})
		end
	end
end