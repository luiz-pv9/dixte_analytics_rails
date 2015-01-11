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
		end

		it 'generates a segmentation on the total of event if no property to segment is provided'
		it 'includes a null value for the events that doesnt have the property'
	end

	describe 'time interval' do
		it 'generates the report on hour interval'
		it 'generates the report on day interval'
		it 'generates the report on week interval'
		it 'generates the report on month interval'
		it 'generates the report on trimester interval'
		it 'generates the report on semester interval'
		it 'generates the report on year interval'
	end

	describe 'grouping' do
		it 'generates the segmentation of the total properties'
		it 'generates the segmentation of the average per profile'
		it 'generates the segmentation uniquely per profile'
	end

end