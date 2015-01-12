require 'rails_helper'

describe SegmentationReport do
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
	end

	def track_data_2
		track_event('click button', '01/01/2014', {'label' => 'what'})
		track_event('click button', '02/01/2014', {'label' => 'foo'})
		track_event('click button', '03/01/2014', {})
		track_event('click button', '04/01/2014', {'label' => 'what'})
		track_event('click button', '05/01/2014', {'label' => 'what'})
	end

	def track_data_3
		track_event('click button', '01/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '01/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '02/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '03/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '04/01/2014', {'label' => 'what'}, 'lpvasco')
		track_event('click button', '05/01/2014', {'label' => 'what'}, 'lpvasco')

		track_event('click button', '01/01/2014', {'label' => 'what'}, 'fran')
		track_event('click button', '01/01/2014', {'label' => 'what'}, 'fran')
		track_event('click button', '02/01/2014', {'label' => 'what'}, 'fran')
		track_event('click button', '03/01/2014', {'label' => 'what'}, 'fran')
		track_event('click button', '04/01/2014', {'label' => 'what'}, 'fran')
		track_event('click button', '05/01/2014', {'label' => 'what'}, 'fran')

		track_event('click button', '01/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('click button', '01/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('click button', '02/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('click button', '03/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('click button', '04/01/2014', {'label' => 'what'}, 'luizpv9')
		track_event('click button', '05/01/2014', {'label' => 'what'}, 'luizpv9')
	end

	describe 'format' do
		it 'has a values hash with the key being the time and value the count for the property value' do
			track_data_1
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'days',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series'].size).to eq(1)
			expect(report['series']['what']).to eq([1, 1, 1, 1, 1])
		end

		it 'generates a segmentation on the total of event if no property to segment is provided' do
			track_data_1
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => nil,
				'steps_in' => 'days',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series'].size).to eq(1)
			expect(report['series']['click button']).to eq([1, 1, 1, 1, 1])
		end

		it 'includes a null value for the events that doesnt have the property' do
			track_data_2
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'days',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series'].size).to eq(3)
			expect(report['series']['what']).to eq([1, nil, nil, 1, 1])
			expect(report['series']['foo']).to eq([nil, 1])
			expect(report['series']['null']).to eq([nil, nil, 1])
		end
	end

	describe 'grouping' do
		it 'generates the segmentation of the total properties' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'days',
				'grouping' => 'total',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series'].size).to eq(1)
			expect(report['series']['what']).to eq([6, 3, 3, 3, 3])
		end

		it 'generates the segmentation uniquely per profile' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'days',
				'grouping' => 'unique',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series'].size).to eq(1)
			expect(report['series']['what']).to eq([3, 3, 3, 3, 3])
		end

		it 'generates the segmentation of the average per profile' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'days',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
			expect(report['series'].size).to eq(1)
			expect(report['series']['what']).to eq([2, 1, 1, 1, 1])
		end
	end

	describe 'time interval' do
		it 'uses a default time interval if no interval is provided' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(12)
		end

		it 'generates the report on hour interval' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'hours',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			# 4 days + 1 hour for the first hour of the first day
			expect(report['steps'].size).to eq(4 * 24 + 1)
		end

		it 'generates the report on day interval' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'days',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(5)
		end

		it 'generates the report on week interval' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'weeks',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(1)
		end

		it 'generates the report on month interval' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'months',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(1)
		end

		it 'generates the report on trimester interval' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'trimesters',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(1)
		end

		it 'generates the report on semester interval' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'semesters',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(1)
		end

		it 'generates the report on year interval' do
			track_data_3
			report = SegmentationReport.new({
				'app_token' => @app.token,
				'event_type' => 'click button',
				'segment_on' => 'label',
				'steps_in' => 'years',
				'grouping' => 'average',
				'time_range' => {
					'from' => Time.strptime('01/01/2014', '%d/%m/%Y').to_i,
					'to' => Time.strptime('05/01/2014', '%d/%m/%Y').to_i
				}
			}).to_json

			expect(report['steps'].size).to eq(1)
		end
	end
end