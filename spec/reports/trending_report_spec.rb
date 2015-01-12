require 'rails_helper'

describe TrendingReport do
	before :each do
		delete_all
		@event_tracker = EventTracker.new
		@profile_tracker = ProfileTracker.new
		@app = App.create :name => 'Dixte'
	end

	def track_event(type, happened_at, properties = {}, external_id = 'lpvasco', app_token = nil)
		app_token ||= @app.token
		time = Time.strptime(happened_at, '%d/%m/%Y')
		@event_tracker.perform({
			'app_token' => app_token,
			'external_id' => external_id,
			'happened_at' => time.to_i,
			'type' => type,
			'properties' => properties
		})
	end

	def track_data_1
		track_event('click button', '01/01/2014', {'label' => 'what'})
		track_event('click button', '02/01/2014', {'label' => 'what'})
		track_event('click button', '03/01/2014', {'label' => 'what'})
		track_event('click button', '04/01/2014', {'label' => 'what'})
		track_event('click button', '05/01/2014', {'label' => 'what'})

		track_event('visit page', '01/01/2014', {'label' => 'what'})
		track_event('visit page', '02/01/2014', {'label' => 'what'})
		track_event('visit page', '03/01/2014', {'label' => 'what'})
		track_event('visit page', '04/01/2014', {'label' => 'what'})
		track_event('visit page', '05/01/2014', {'label' => 'what'})

		track_event('open modal', '01/01/2014', {'label' => 'what'})
		track_event('open modal', '02/01/2014', {'label' => 'what'})
		track_event('open modal', '03/01/2014', {'label' => 'what'})
		track_event('open modal', '04/01/2014', {'label' => 'what'})
		track_event('open modal', '05/01/2014', {'label' => 'what'})
	end

	def track_data_2
		track_event('click button', '01/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '01/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '02/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '03/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '04/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '05/01/2014', {'label' => 'what'}, 'lpvasco')

		track_event('visit page', '01/01/2014', {'label' => 'what'}, 'fran')
		track_event('visit page', '01/01/2014', {'label' => 'what'}, 'fran')
		track_event('visit page', '02/01/2014', {'label' => 'what'}, 'fran')
		track_event('visit page', '03/01/2014', {'label' => 'what'}, 'fran')
		track_event('visit page', '04/01/2014', {'label' => 'what'}, 'fran')
		track_event('visit page', '05/01/2014', {'label' => 'what'}, 'fran')

		track_event('open modal', '01/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('open modal', '01/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('open modal', '02/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('open modal', '03/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('open modal', '04/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('open modal', '05/01/2014', {'label' => 'what'}, 'luizpv9')
	end

	describe 'format' do
		it 'has a hash of event types' do
			track_data_1
			report = TrendingReport.new({
				'app_token' => @app.token,
				'events_types' => ['click button', 'visit page', 'open modal'],
				'steps_in' => 'days',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series'].size).to eq(3)
		end

		it 'defaults to the most occurred 4 events if no events are specified' do
			track_data_1
			report = TrendingReport.new({
				'app_token' => @app.token,
				'steps_in' => 'days',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series'].size).to eq(3)
		end
	end

	describe 'grouping' do
		it 'groups the report by the total of events' do
			track_data_2
			report = TrendingReport.new({
				'app_token' => @app.token,
				'steps_in' => 'days',
				'grouping' => 'total',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series']['click button']).to eq([2, 1, 1, 1, 1])
		end

		it 'groups the report by unique profiles' do
			track_data_2
			report = TrendingReport.new({
				'app_token' => @app.token,
				'steps_in' => 'days',
				'grouping' => 'unique',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series']['click button']).to eq([1, 1, 1, 1, 1])
			expect(report['series']['visit page']).to eq([1, 1, 1, 1, 1])
			expect(report['series']['open modal']).to eq([1, 1, 1, 1, 1])
		end

		it 'groups the report by average per profile' do
			track_data_2
			report = TrendingReport.new({
				'app_token' => @app.token,
				'steps_in' => 'days',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series']['click button']).to eq([2, 1, 1, 1, 1])
			expect(report['series']['visit page']).to eq([2, 1, 1, 1, 1])
			expect(report['series']['open modal']).to eq([2, 1, 1, 1, 1])
		end
	end

	# There is no need to test for time steps (steps_in) because it's the same
	# as in the trending report
end